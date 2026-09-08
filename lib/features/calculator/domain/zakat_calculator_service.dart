import '../../../core/domain/app_state.dart';
import '../../../core/domain/enums.dart';
import '../../../core/constants/currency_constants.dart';
import '../../assets/domain/asset_model.dart';
import '../../exchange_rates/domain/exchange_rate_model.dart';
import 'calculation_result.dart';

class ZakatCalculatorService {
  CalculationResult calculate({
    required AppState appState,
    required List<AssetModel> assets,
    required double goldRate,
    required double silverRate,
    required List<ExchangeRateModel> exchangeRates,
  }) {
    final effectiveGoldRate = goldRate > 0 ? goldRate : CurrencyConstants.defaultGoldRate;
    final effectiveSilverRate = silverRate > 0 ? silverRate : CurrencyConstants.defaultSilverRate;
    final conversionRate = CurrencyConstants.getConversionRate(appState.currency, exchangeRates);

    double totalZakatableAssets = 0; // Zekata tabi altın, gümüş, nakit ve ticaret malları
    double totalDebts = 0; // Toplam borçlar
    double deductibleDebts = 0; // Matrahtan düşülebilir borçlar (kısa vadeli / vadesi gelmiş)
    double agricultureZakat = 0;
    double saimeLivestockZakat = 0;
    double totalDisplayAssets = 0;

    for (var asset in assets) {
      // Varlığın o anki canlı piyasa kurlarıyla dinamik TRY değeri
      final assetValueTRY = CurrencyConstants.calculateDynamicAssetValueTRY(
        asset: asset,
        goldRate: effectiveGoldRate,
        silverRate: effectiveSilverRate,
        exchangeRates: exchangeRates,
      );

      if (asset.category == AssetCategory.debt) {
        totalDebts += assetValueTRY;
        // Fıkıh kuralı: Sadece vadesi gelmiş veya 1 yıl içinde ödenecek kısa vadeli borçlar düşülür.
        // Geriye dönük uyumluluk için varsayılan true kabul edilir.
        final isShortTerm = asset.details?['isShortTerm'] != false;
        if (isShortTerm) {
          deductibleDebts += assetValueTRY;
        }
      } else if (asset.category == AssetCategory.agriculture) {
        totalDisplayAssets += assetValueTRY;
        // Tarım ürünleri (Öşür) kendi içinde hesaplanır, genel havuza katılmaz.
        final irrigation = asset.details?['irrigationType'] ?? 'natural';
        final rate = irrigation == 'natural' ? 0.10 : 0.05;
        agricultureZakat += assetValueTRY * rate;
      } else if (asset.category == AssetCategory.livestock) {
        totalDisplayAssets += assetValueTRY;
        final isTrade = asset.details?['isTrade'] == 'true' || asset.details?['isTrade'] == true;
        if (isTrade) {
          totalZakatableAssets += assetValueTRY;
        } else {
          // Saime Hayvan Hesabı
          final type = asset.details?['livestockType'] ?? '';
          final quantity = int.tryParse(asset.details?['quantity']?.toString() ?? '0') ?? 0;
          final unitPrice = double.tryParse(asset.details?['unitPrice']?.toString() ?? '0') ?? 0.0;

          int animalZakatCount = 0;
          double customZakatValue = 0;

          if (type == 'Koyun/Keçi' || type == 'Sheep/Goat') {
            if (quantity >= 40 && quantity <= 120) {
              animalZakatCount = 1;
            } else if (quantity >= 121 && quantity <= 200) {
              animalZakatCount = 2;
            } else if (quantity >= 201 && quantity <= 399) {
              animalZakatCount = 3;
            } else if (quantity >= 400) {
              animalZakatCount = quantity ~/ 100;
            }
            customZakatValue = animalZakatCount * unitPrice;
          } else if (type == 'Sığır/Manda' || type == 'Cattle/Buffalo') {
            if (quantity >= 30 && quantity < 40) {
              animalZakatCount = 1;
            } else if (quantity >= 40 && quantity < 60) {
              animalZakatCount = 1;
            } else if (quantity >= 60) {
              animalZakatCount = quantity ~/ 30;
            }
            customZakatValue = animalZakatCount * unitPrice;
          } else if (type == 'Deve' || type == 'Camel') {
            if (quantity >= 5 && quantity < 25) {
              // 5-24 arası her 5 devede 1 koyun verilir (koyun değeri ~ deve / 10)
              final sheepCount = quantity ~/ 5;
              customZakatValue = sheepCount * (unitPrice / 10);
            } else if (quantity >= 25) {
              animalZakatCount = quantity ~/ 25;
              customZakatValue = animalZakatCount * unitPrice;
            }
          }

          saimeLivestockZakat += customZakatValue;
        }
      } else {
        // Altın, Gümüş, Nakit, Alacaklar
        totalDisplayAssets += assetValueTRY;

        // Ziynet eşyası muafiyeti kontrolü:
        // Şafii, Maliki ve Hanbeli mezheplerinde kadının kullanımındaki ziynet eşyası zekata tabi değildir.
        if ((asset.category == AssetCategory.gold || asset.category == AssetCategory.silver) &&
            asset.details?['isJewelry'] == true &&
            appState.sect != Sect.hanefi) {
          continue;
        }

        totalZakatableAssets += assetValueTRY;
      }
    }

    // Fıkıh kuralı: Hanefi ve Hanbeli mezheplerinde borçlar nisap hesabından düşülür.
    // Şafii ve Maliki mezheplerinde ise elde mevcut zekata tabi varlıklardan borç düşülmez.
    double netZakatableAmount = totalZakatableAssets;
    if (appState.sect == Sect.hanefi || appState.sect == Sect.hanbeli) {
      netZakatableAmount = totalZakatableAssets - deductibleDebts;
    }

    if (netZakatableAmount < 0) {
      netZakatableAmount = 0;
    }

    // Nisab Eşiği Belirleme (Altın: 80.18 gr, Gümüş: 595 gr)
    final nisabThreshold = appState.nisabType == NisabType.silver
        ? 595.0 * effectiveSilverRate
        : 80.18 * effectiveGoldRate;
    final isNisabReached = netZakatableAmount >= nisabThreshold;

    double zakatToPay = 0;

    // Altın, gümüş, para ve ticaret mallarının zekatı (%2.5 / 1/40)
    if (isNisabReached) {
      zakatToPay = netZakatableAmount * 0.025;
      if (zakatToPay < 0.0) {
        zakatToPay = 0.0;
      }
    }

    // Tarım ve Saime Hayvan zekatları kendi fıkhi oranlarına tabidir ve doğrudan eklenir
    zakatToPay += agricultureZakat;
    zakatToPay += saimeLivestockZakat;

    return CalculationResult(
      totalAssets: totalDisplayAssets / conversionRate,
      totalDebts: totalDebts / conversionRate,
      netZakatableAmount: netZakatableAmount / conversionRate,
      nisabThreshold: nisabThreshold / conversionRate,
      isNisabReached: isNisabReached,
      zakatToPay: zakatToPay / conversionRate,
      goldRate: effectiveGoldRate / conversionRate,
      silverRate: effectiveSilverRate / conversionRate,
      conversionRate: conversionRate,
    );
  }
}
