import 'package:dio/dio.dart';
import '../domain/exchange_rate_model.dart';

abstract class ExchangeRateService {
  Future<List<ExchangeRateModel>> fetchRates();
}

// 1. Servis: GenelPara API (Altın ve Döviz - Türkiye için popüler)
class GenelParaService implements ExchangeRateService {
  final Dio dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  @override
  Future<List<ExchangeRateModel>> fetchRates() async {
    try {
      final response = await dio.get('https://api.genelpara.com/embed/para-birimleri.json');
      final data = response.data as Map<String, dynamic>;
      
      return [
        ExchangeRateModel.fromJson(data['USD'], 'USD', 'Amerikan Doları'),
        ExchangeRateModel.fromJson(data['EUR'], 'EUR', 'Euro'),
        ExchangeRateModel.fromJson(data['GA'], 'GOLD', 'Gram Altın'),
      ];
    } catch (e) {
      return []; 
    }
  }
}

// 2. Servis: Frankfurter API (Sadece Döviz - Yedek Servis)
class FrankfurterService implements ExchangeRateService {
  final Dio dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  @override
  Future<List<ExchangeRateModel>> fetchRates() async {
    try {
      final response = await dio.get('https://api.frankfurter.app/latest?from=TRY&to=USD,EUR');
      final rates = response.data['rates'] as Map<String, dynamic>;
      
      // Frankfurter 1 TRY = ? USD verir, bize alışkın olduğumuz 1 USD = ? TRY lazım
      final usdRate = 1 / (rates['USD'] ?? 1);
      final eurRate = 1 / (rates['EUR'] ?? 1);

      return [
        ExchangeRateModel(currencyCode: 'USD', currencyName: 'Amerikan Doları', buyingPrice: usdRate, sellingPrice: usdRate, lastUpdate: DateTime.now()),
        ExchangeRateModel(currencyCode: 'EUR', currencyName: 'Euro', buyingPrice: eurRate, sellingPrice: eurRate, lastUpdate: DateTime.now()),
      ];
    } catch (e) {
      return [];
    }
  }
}

class ExchangeRateRepository {
  final ExchangeRateService primaryService = GenelParaService();
  final ExchangeRateService fallbackService = FrankfurterService();

  Future<List<ExchangeRateModel>> getRates() async {
    // Önce 1. Servisten veri çekmeyi dene
    List<ExchangeRateModel> rates = await primaryService.fetchRates();
    
    if (rates.isEmpty) {
      // 1. Servis çökerse, ücretsiz 2. servise (Fallback) geç
      rates = await fallbackService.fetchRates();
    }
    
    return rates;
  }
}
