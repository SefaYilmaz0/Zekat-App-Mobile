import '../domain/enums.dart';
import '../../features/assets/domain/asset_model.dart';
import '../../features/exchange_rates/domain/exchange_rate_model.dart';

class CurrencyConstants {
  // 2026 Güncel Piyasa Taban Fiyatları (Ağ erişimi olmadığında güvenlik değerleri)
  static const double defaultGoldRate = 6848.0;
  static const double defaultSilverRate = 102.0;
  static const double defaultUsdRate = 48.50;
  static const double defaultEurRate = 56.50;

  /// Hedef para birimine göre TRY dönüşüm kurunu getirir.
  static double getConversionRate(AppCurrency currency, List<ExchangeRateModel> exchangeRates) {
    if (currency == AppCurrency.usd) {
      final usdRate = exchangeRates.firstWhere(
        (r) => r.currencyCode == 'USD',
        orElse: () => ExchangeRateModel(
          currencyCode: 'USD',
          currencyName: 'Amerikan Doları',
          buyingPrice: defaultUsdRate,
          sellingPrice: defaultUsdRate,
          lastUpdate: DateTime.now(),
        ),
      );
      return usdRate.buyingPrice > 0 ? usdRate.buyingPrice : defaultUsdRate;
    } else if (currency == AppCurrency.eur) {
      final eurRate = exchangeRates.firstWhere(
        (r) => r.currencyCode == 'EUR',
        orElse: () => ExchangeRateModel(
          currencyCode: 'EUR',
          currencyName: 'Euro',
          buyingPrice: defaultEurRate,
          sellingPrice: defaultEurRate,
          lastUpdate: DateTime.now(),
        ),
      );
      return eurRate.buyingPrice > 0 ? eurRate.buyingPrice : defaultEurRate;
    }
    return 1.0;
  }

  /// Belirli bir döviz kodunun (USD, EUR, TRY) o anki TRY kurunu döner.
  static double getCurrencyToTryRate(String currencyCode, List<ExchangeRateModel> exchangeRates) {
    final code = currencyCode.toUpperCase();
    if (code == 'TRY') return 1.0;
    if (code == 'USD') {
      final usd = exchangeRates.firstWhere(
        (r) => r.currencyCode == 'USD',
        orElse: () => ExchangeRateModel(
          currencyCode: 'USD',
          currencyName: 'Amerikan Doları',
          buyingPrice: defaultUsdRate,
          sellingPrice: defaultUsdRate,
          lastUpdate: DateTime.now(),
        ),
      );
      return usd.buyingPrice > 0 ? usd.buyingPrice : defaultUsdRate;
    }
    if (code == 'EUR') {
      final eur = exchangeRates.firstWhere(
        (r) => r.currencyCode == 'EUR',
        orElse: () => ExchangeRateModel(
          currencyCode: 'EUR',
          currencyName: 'Euro',
          buyingPrice: defaultEurRate,
          sellingPrice: defaultEurRate,
          lastUpdate: DateTime.now(),
        ),
      );
      return eur.buyingPrice > 0 ? eur.buyingPrice : defaultEurRate;
    }
    return 1.0;
  }

  /// Altın ayar katsayısı
  static double getGoldPurityFactor(String purity) {
    switch (purity) {
      case '24':
        return 1.0;
      case '22':
        return 0.916;
      case '18':
        return 0.750;
      case '14':
        return 0.585;
      default:
        return 1.0;
    }
  }

  /// Altın türü ve ayarına göre gram başına veya adet başına TRY birim fiyatını hesaplar
  static double getGoldUnitPriceTRY(String goldType, String purity, double goldRate) {
    final effectiveGoldRate = goldRate > 0 ? goldRate : defaultGoldRate;
    if (goldType == 'Gram') {
      return effectiveGoldRate * getGoldPurityFactor(purity);
    }
    switch (goldType) {
      case 'Çeyrek':
      case 'Quarter':
        return effectiveGoldRate * 1.64;
      case 'Yarım':
      case 'Half':
        return effectiveGoldRate * 3.28;
      case 'Tam':
      case 'Full':
        return effectiveGoldRate * 6.56;
      case 'Cumhuriyet':
      case 'Republic':
        return effectiveGoldRate * 6.68;
      case 'Ata':
        return effectiveGoldRate * 6.75;
      default:
        return effectiveGoldRate * getGoldPurityFactor(purity);
    }
  }

  /// Gümüş saflık katsayısı
  static double getSilverPurityFactor(String purity) {
    switch (purity) {
      case '999':
        return 1.0;
      case '925':
        return 0.925;
      case '900':
        return 0.900;
      case '800':
        return 0.800;
      default:
        return 1.0;
    }
  }

  /// Gümüş birim fiyatı (TRY)
  static double getSilverUnitPriceTRY(String purity, double silverRate) {
    final effectiveSilverRate = silverRate > 0 ? silverRate : defaultSilverRate;
    return effectiveSilverRate * getSilverPurityFactor(purity);
  }

  /// Varlığın O ANKİ canlı kurlarla dinamik TRY değerini hesaplar.
  /// Bu metot, varlığın girildiği günkü statik TRY değerine takılıp kalmasını önler.
  static double calculateDynamicAssetValueTRY({
    required AssetModel asset,
    required double goldRate,
    required double silverRate,
    required List<ExchangeRateModel> exchangeRates,
  }) {
    final details = asset.details;
    if (details == null) {
      return asset.value;
    }

    switch (asset.category) {
      case AssetCategory.gold:
        final goldType = details['goldType']?.toString() ?? 'Gram';
        final purity = details['purity']?.toString() ?? '24';
        final quantity = double.tryParse(details['quantity']?.toString() ?? '') ?? 0.0;
        if (quantity > 0) {
          final unitPrice = getGoldUnitPriceTRY(goldType, purity, goldRate);
          return quantity * unitPrice;
        }
        return asset.value;

      case AssetCategory.silver:
        final purity = details['purity']?.toString() ?? '925';
        final quantity = double.tryParse(details['quantity']?.toString() ?? '') ?? 0.0;
        if (quantity > 0) {
          final unitPrice = getSilverUnitPriceTRY(purity, silverRate);
          return quantity * unitPrice;
        }
        return asset.value;

      case AssetCategory.cash:
      case AssetCategory.receivable:
      case AssetCategory.debt:
        final currencyCode = details['currency']?.toString() ?? 'TRY';
        final originalAmount = double.tryParse(details['originalAmount']?.toString() ?? '') ?? 0.0;
        if (originalAmount > 0) {
          final rate = getCurrencyToTryRate(currencyCode, exchangeRates);
          return originalAmount * rate;
        }
        return asset.value;

      case AssetCategory.livestock:
      case AssetCategory.agriculture:
        return asset.value;
    }
  }
}
