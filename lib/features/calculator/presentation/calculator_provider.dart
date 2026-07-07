import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../assets/domain/asset_model.dart';
import '../../exchange_rates/data/exchange_rate_repository.dart';
import '../../exchange_rates/domain/exchange_rate_model.dart';
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
  final assetsAsync = ref.watch(assetsProvider);
  final appState = ref.watch(appStateProvider);

  if (goldRateAsync is AsyncLoading || assetsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (goldRateAsync.hasError) {
    return AsyncValue.error(goldRateAsync.error!, goldRateAsync.stackTrace!);
  }

  final goldRate = goldRateAsync.value ?? 0.0;
  final assets = assetsAsync.value ?? [];

  double totalAssets = 0;
  double totalDebts = 0;

  for (var asset in assets) {
    if (asset.category == AssetCategory.debt) {
      totalDebts += asset.value;
    } else {
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

  final nisabThreshold = 80.18 * goldRate;
  final isNisabReached = netZakatableAmount >= nisabThreshold;

  double zakatToPay = 0;
  if (isNisabReached) {
    double tempZakat = 0;
    for (var asset in assets) {
      if (asset.category == AssetCategory.debt) continue;
      
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
    totalAssets: totalAssets,
    totalDebts: totalDebts,
    netZakatableAmount: netZakatableAmount,
    nisabThreshold: nisabThreshold,
    isNisabReached: isNisabReached,
    zakatToPay: zakatToPay,
    goldRate: goldRate,
  ));
});
