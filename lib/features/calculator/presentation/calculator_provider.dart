import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/currency_constants.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../assets/domain/asset_model.dart';
import '../../exchange_rates/domain/exchange_rate_model.dart';
import '../../exchange_rates/presentation/exchange_rate_provider.dart';
import '../domain/calculation_result.dart';
import '../domain/zakat_calculator_service.dart';

final zakatCalculatorServiceProvider = Provider((ref) => ZakatCalculatorService());

final goldRateProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(exchangeRateRepositoryProvider);
  final rates = await repo.getRates();
  final goldRate = rates.firstWhere(
    (rate) => rate.currencyCode == 'GOLD',
    orElse: () => ExchangeRateModel(
      currencyCode: 'GOLD',
      currencyName: 'Gram Altın',
      buyingPrice: CurrencyConstants.defaultGoldRate,
      sellingPrice: CurrencyConstants.defaultGoldRate,
      lastUpdate: DateTime.now(),
    ),
  );
  return goldRate.buyingPrice > 0 ? goldRate.buyingPrice : CurrencyConstants.defaultGoldRate;
});

final silverRateProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(exchangeRateRepositoryProvider);
  final rates = await repo.getRates();
  final silverRate = rates.firstWhere(
    (rate) => rate.currencyCode == 'SILVER',
    orElse: () => ExchangeRateModel(
      currencyCode: 'SILVER',
      currencyName: 'Gram Gümüş',
      buyingPrice: CurrencyConstants.defaultSilverRate,
      sellingPrice: CurrencyConstants.defaultSilverRate,
      lastUpdate: DateTime.now(),
    ),
  );
  return silverRate.buyingPrice > 0 ? silverRate.buyingPrice : CurrencyConstants.defaultSilverRate;
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
  final calculatorService = ref.watch(zakatCalculatorServiceProvider);

  if (goldRateAsync is AsyncLoading || silverRateAsync is AsyncLoading || assetsAsync is AsyncLoading || ratesAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (goldRateAsync.hasError) {
    return AsyncValue.error(goldRateAsync.error!, goldRateAsync.stackTrace!);
  }
  if (silverRateAsync.hasError) {
    return AsyncValue.error(silverRateAsync.error!, silverRateAsync.stackTrace!);
  }

  final goldRateRaw = goldRateAsync.value ?? CurrencyConstants.defaultGoldRate;
  final silverRateRaw = silverRateAsync.value ?? CurrencyConstants.defaultSilverRate;
  final assets = assetsAsync.value ?? [];
  final rates = ratesAsync.value ?? [];

  final result = calculatorService.calculate(
    appState: appState,
    assets: assets,
    goldRate: goldRateRaw,
    silverRate: silverRateRaw,
    exchangeRates: rates,
  );

  return AsyncValue.data(result);
});
