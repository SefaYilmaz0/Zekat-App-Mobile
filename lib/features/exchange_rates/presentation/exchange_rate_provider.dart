import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exchange_rate_repository.dart';
import '../domain/exchange_rate_model.dart';

final exchangeRateRepositoryProvider = Provider((ref) => ExchangeRateRepository());

// Asenkron veri çekimi için FutureProvider kullanıyoruz
final exchangeRatesProvider = FutureProvider<List<ExchangeRateModel>>((ref) async {
  final repository = ref.read(exchangeRateRepositoryProvider);
  return await repository.getRates();
});

