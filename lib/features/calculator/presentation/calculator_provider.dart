import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../assets/domain/asset_model.dart';
import '../../exchange_rates/data/exchange_rate_repository.dart';
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
      buyingPrice: 2500.0, // Varsayılan güvenlik değeri
      sellingPrice: 2500.0,
      lastUpdate: DateTime.now(),
    ),
  );
  return goldRate.buyingPrice;
});

final silverRateProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(exchangeRateRepositoryProvider);
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

  final goldRateRaw = goldRateAsync.value ?? 0.0;
  final silverRateRaw = silverRateAsync.value ?? 0.0;
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

