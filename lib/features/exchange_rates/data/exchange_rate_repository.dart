import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/currency_constants.dart';
import '../domain/exchange_rate_model.dart';

abstract class ExchangeRateService {
  Future<List<ExchangeRateModel>> fetchRates();
}

// 1. Servis: Truncgil API (Altın, Gümüş ve Döviz - Birincil ve Aktif)
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
      final silver = parseDouble(data['gumus']?['Alış']);

      if (usd == 0.0 && gold == 0.0) return [];

      return [
        ExchangeRateModel(
          currencyCode: 'USD',
          currencyName: 'Amerikan Doları',
          buyingPrice: usd > 0 ? usd : CurrencyConstants.defaultUsdRate,
          sellingPrice: usd > 0 ? usd : CurrencyConstants.defaultUsdRate,
          lastUpdate: DateTime.now(),
        ),
        ExchangeRateModel(
          currencyCode: 'EUR',
          currencyName: 'Euro',
          buyingPrice: eur > 0 ? eur : CurrencyConstants.defaultEurRate,
          sellingPrice: eur > 0 ? eur : CurrencyConstants.defaultEurRate,
          lastUpdate: DateTime.now(),
        ),
        ExchangeRateModel(
          currencyCode: 'GOLD',
          currencyName: 'Gram Altın',
          buyingPrice: gold > 0 ? gold : CurrencyConstants.defaultGoldRate,
          sellingPrice: gold > 0 ? gold : CurrencyConstants.defaultGoldRate,
          lastUpdate: DateTime.now(),
        ),
        ExchangeRateModel(
          currencyCode: 'SILVER',
          currencyName: 'Gram Gümüş',
          buyingPrice: silver > 0 ? silver : CurrencyConstants.defaultSilverRate,
          sellingPrice: silver > 0 ? silver : CurrencyConstants.defaultSilverRate,
          lastUpdate: DateTime.now(),
        ),
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

      // Frankfurter 1 TRY = ? USD verir, 1 USD = ? TRY elde etmek için tersini alıyoruz
      final usdRate = 1 / (rates['USD'] ?? 1);
      final eurRate = 1 / (rates['EUR'] ?? 1);

      return [
        ExchangeRateModel(
          currencyCode: 'USD',
          currencyName: 'Amerikan Doları',
          buyingPrice: usdRate,
          sellingPrice: usdRate,
          lastUpdate: DateTime.now(),
        ),
        ExchangeRateModel(
          currencyCode: 'EUR',
          currencyName: 'Euro',
          buyingPrice: eurRate,
          sellingPrice: eurRate,
          lastUpdate: DateTime.now(),
        ),
      ];
    } catch (e) {
      return [];
    }
  }
}

// 3. Servis: GenelPara API (Yedek Servis)
class GenelParaService implements ExchangeRateService {
  final Dio dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  @override
  Future<List<ExchangeRateModel>> fetchRates() async {
    try {
      final response = await dio.get(
        'https://api.genelpara.com/embed/para-birimleri.json',
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );
      final data = response.data as Map<String, dynamic>;

      return [
        ExchangeRateModel.fromJson(data['USD'], 'USD', 'Amerikan Doları'),
        ExchangeRateModel.fromJson(data['EUR'], 'EUR', 'Euro'),
        ExchangeRateModel.fromJson(data['GA'], 'GOLD', 'Gram Altın'),
        ExchangeRateModel.fromJson(data['GUMUS'], 'SILVER', 'Gram Gümüş'),
      ];
    } catch (e) {
      return [];
    }
  }
}

class ExchangeRateRepository {
  final List<ExchangeRateService> services = [
    TruncgilService(),
    FrankfurterService(),
    GenelParaService(),
  ];

  Future<List<ExchangeRateModel>> getRates() async {
    final box = Hive.box<ExchangeRateModel>('exchange_rates');

    for (final service in services) {
      try {
        final rates = await service.fetchRates();
        if (rates.isNotEmpty) {
          final hasGold = rates.any((r) => r.currencyCode == 'GOLD');
          if (hasGold || service == services.last) {
            // Başarılı kurları Hive'a önbellekle
            for (var rate in rates) {
              box.put(rate.currencyCode, rate);
            }
            return rates;
          }
        }
      } catch (_) {}
    }

    // Servisler başarısız olursa yerel önbellekten oku
    if (box.isNotEmpty) {
      return box.values.toList();
    }

    // Hem ağ yoksa hem önbellek boşsa 2026 güncel güvenlik taban değerleri
    return [
      ExchangeRateModel(
        currencyCode: 'USD',
        currencyName: 'Amerikan Doları',
        buyingPrice: CurrencyConstants.defaultUsdRate,
        sellingPrice: CurrencyConstants.defaultUsdRate,
        lastUpdate: DateTime.now(),
      ),
      ExchangeRateModel(
        currencyCode: 'EUR',
        currencyName: 'Euro',
        buyingPrice: CurrencyConstants.defaultEurRate,
        sellingPrice: CurrencyConstants.defaultEurRate,
        lastUpdate: DateTime.now(),
      ),
      ExchangeRateModel(
        currencyCode: 'GOLD',
        currencyName: 'Gram Altın',
        buyingPrice: CurrencyConstants.defaultGoldRate,
        sellingPrice: CurrencyConstants.defaultGoldRate,
        lastUpdate: DateTime.now(),
      ),
      ExchangeRateModel(
        currencyCode: 'SILVER',
        currencyName: 'Gram Gümüş',
        buyingPrice: CurrencyConstants.defaultSilverRate,
        sellingPrice: CurrencyConstants.defaultSilverRate,
        lastUpdate: DateTime.now(),
      ),
    ];
  }
}
