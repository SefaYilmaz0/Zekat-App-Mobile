import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../assets/domain/asset_model.dart';
import '../../exchange_rates/data/exchange_rate_repository.dart';
import '../../exchange_rates/domain/exchange_rate_model.dart';
import '../../exchange_rates/presentation/exchange_rate_provider.dart';
import '../domain/calculation_result.dart';

final goldRateProvider = FutureProvider<double>((ref) async {
  final repo = ExchangeRateRepository();
  final rates = await repo.getRates();
  final goldRate = rates.firstWhere(
    (rate) => rate.currencyCode == 'GOLD',
    orElse: () => ExchangeRateModel(
      currencyCode: 'GOLD',
      currencyName: 'Gram Altın',
      buyingPrice: 2500.0, // Varsayılan güvenlik değeri
      sellingPrice: 2500.0,
      lastUpdate: DateTime.now(),
    ),
  );
  return goldRate.buyingPrice;
});

final silverRateProvider = FutureProvider<double>((ref) async {
  final repo = ExchangeRateRepository();
  final rates = await repo.getRates();
  final silverRate = rates.firstWhere(
    (rate) => rate.currencyCode == 'SILVER',
    orElse: () => ExchangeRateModel(
      currencyCode: 'SILVER',
      currencyName: 'Gram Gümüş',
      buyingPrice: 38.0, // Varsayılan güvenlik değeri
      sellingPrice: 38.0,
      lastUpdate: DateTime.now(),
    ),
  );
  return silverRate.buyingPrice;
});

// A stream of assets to trigger recalculations when assets change
final assetsProvider = StreamProvider<List<AssetModel>>((ref) {
  final box = Hive.box<AssetModel>('assets');
  return box.watch().map((_) => box.values.toList()).startWith(box.values.toList());
});

extension StreamExt<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}

final calculatorProvider = Provider<AsyncValue<CalculationResult>>((ref) {
  final goldRateAsync = ref.watch(goldRateProvider);
  final silverRateAsync = ref.watch(silverRateProvider);
  final assetsAsync = ref.watch(assetsProvider);
  final appState = ref.watch(appStateProvider);
  final ratesAsync = ref.watch(exchangeRatesProvider);

  if (goldRateAsync is AsyncLoading || silverRateAsync is AsyncLoading || assetsAsync is AsyncLoading || ratesAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (goldRateAsync.hasError) {
    return AsyncValue.error(goldRateAsync.error!, goldRateAsync.stackTrace!);
  }
  if (silverRateAsync.hasError) {
    return AsyncValue.error(silverRateAsync.error!, silverRateAsync.stackTrace!);
  }

  final goldRateRaw = goldRateAsync.value ?? 0.0;
  final silverRateRaw = silverRateAsync.value ?? 0.0;
  final assets = assetsAsync.value ?? [];
  final rates = ratesAsync.value ?? [];

  double conversionRate = 1.0;
  if (appState.currency == AppCurrency.usd) {
    final usdRate = rates.firstWhere(
      (r) => r.currencyCode == 'USD',
      orElse: () => ExchangeRateModel(currencyCode: 'USD', currencyName: 'USD', buyingPrice: 46.0, sellingPrice: 46.0, lastUpdate: DateTime.now()),
    );
    conversionRate = usdRate.buyingPrice > 0 ? usdRate.buyingPrice : 46.0;
  } else if (appState.currency == AppCurrency.eur) {
    final eurRate = rates.firstWhere(
      (r) => r.currencyCode == 'EUR',
      orElse: () => ExchangeRateModel(currencyCode: 'EUR', currencyName: 'EUR', buyingPrice: 53.0, sellingPrice: 53.0, lastUpdate: DateTime.now()),
    );
    conversionRate = eurRate.buyingPrice > 0 ? eurRate.buyingPrice : 53.0;
  }

  double totalAssets = 0;
  double totalDebts = 0;

  for (var asset in assets) {
    if (asset.category == AssetCategory.debt) {
      totalDebts += asset.value;
    } else {
      if ((asset.category == AssetCategory.gold || asset.category == AssetCategory.silver) &&
          asset.details?['isJewelry'] == true &&
          appState.sect != Sect.hanefi) {
        continue;
      }
      totalAssets += asset.value;
    }
  }

  double netZakatableAmount = totalAssets;

  // In Hanefi and Hanbeli, debts are deducted from total assets.
  if (appState.sect == Sect.hanefi || appState.sect == Sect.hanbeli) {
    netZakatableAmount = totalAssets - totalDebts;
  }

  if (netZakatableAmount < 0) {
    netZakatableAmount = 0;
  }

  final nisabThreshold = appState.nisabType == NisabType.silver
      ? 595.0 * silverRateRaw
      : 80.18 * goldRateRaw;
  final isNisabReached = netZakatableAmount >= nisabThreshold;

  double zakatToPay = 0;
  if (isNisabReached) {
    double tempZakat = 0;
    for (var asset in assets) {
      if (asset.category == AssetCategory.debt) continue;
      if ((asset.category == AssetCategory.gold || asset.category == AssetCategory.silver) &&
          asset.details?['isJewelry'] == true &&
          appState.sect != Sect.hanefi) {
        continue;
      }
      
      if (asset.category == AssetCategory.agriculture) {
        final irrigation = asset.details?['irrigationType'] ?? 'natural';
        final rate = irrigation == 'natural' ? 0.10 : 0.05;
        tempZakat += asset.value * rate;
      } else {
        tempZakat += asset.value * 0.025;
      }
    }
    tempZakat -= totalDebts * 0.025;
    zakatToPay = tempZakat < 0.0 ? 0.0 : tempZakat;
  }

  return AsyncValue.data(CalculationResult(
    totalAssets: totalAssets / conversionRate,
    totalDebts: totalDebts / conversionRate,
    netZakatableAmount: netZakatableAmount / conversionRate,
    nisabThreshold: nisabThreshold / conversionRate,
    isNisabReached: isNisabReached,
    zakatToPay: zakatToPay / conversionRate,
    goldRate: goldRateRaw / conversionRate,
    conversionRate: conversionRate,
  ));
});

