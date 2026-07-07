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
      final response = await dio.get(
        'https://api.genelpara.com/embed/para-birimleri.json',
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ),
      );
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

// 3. Servis: Truncgil API (Altın ve Döviz - Popüler ve Ücretsiz)
class TruncgilService implements ExchangeRateService {
  final Dio dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  @override
  Future<List<ExchangeRateModel>> fetchRates() async {
    try {
      final response = await dio.get('https://finans.truncgil.com/today.json');
      final data = response.data as Map<String, dynamic>;
      
      double parseDouble(dynamic val) {
        if (val == null) return 0.0;
        final clean = val.toString().replaceAll('.', '').replaceAll(',', '.');
        return double.tryParse(clean) ?? 0.0;
      }

      final usd = parseDouble(data['USD']?['Alış']);
      final eur = parseDouble(data['EUR']?['Alış']);
      final gold = parseDouble(data['gram-altin']?['Alış']);

      return [
        ExchangeRateModel(currencyCode: 'USD', currencyName: 'Amerikan Doları', buyingPrice: usd, sellingPrice: usd, lastUpdate: DateTime.now()),
        ExchangeRateModel(currencyCode: 'EUR', currencyName: 'Euro', buyingPrice: eur, sellingPrice: eur, lastUpdate: DateTime.now()),
        ExchangeRateModel(currencyCode: 'GOLD', currencyName: 'Gram Altın', buyingPrice: gold, sellingPrice: gold, lastUpdate: DateTime.now()),
      ];
    } catch (e) {
      return [];
    }
  }
}

class ExchangeRateRepository {
  final List<ExchangeRateService> services = [
    GenelParaService(),
    TruncgilService(),
    FrankfurterService(),
  ];

  Future<List<ExchangeRateModel>> getRates() async {
    for (final service in services) {
      try {
        final rates = await service.fetchRates();
        if (rates.isNotEmpty) {
          final hasGold = rates.any((r) => r.currencyCode == 'GOLD');
          if (hasGold || service == services.last) {
            return rates;
          }
        }
      } catch (_) {}
    }
    return [];
  }
}


