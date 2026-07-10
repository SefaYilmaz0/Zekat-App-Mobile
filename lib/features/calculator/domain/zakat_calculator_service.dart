import '../../../core/domain/app_state.dart';
import '../../../core/domain/enums.dart';
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
    double conversionRate = 1.0;

    if (appState.currency == AppCurrency.usd) {
      final usdRate = exchangeRates.firstWhere(
        (r) => r.currencyCode == 'USD',
        orElse: () => ExchangeRateModel(
            currencyCode: 'USD',
            currencyName: 'USD',
            buyingPrice: 46.0,
            sellingPrice: 46.0,
            lastUpdate: DateTime.now()),
      );
      conversionRate = usdRate.buyingPrice > 0 ? usdRate.buyingPrice : 46.0;
    } else if (appState.currency == AppCurrency.eur) {
      final eurRate = exchangeRates.firstWhere(
        (r) => r.currencyCode == 'EUR',
        orElse: () => ExchangeRateModel(
            currencyCode: 'EUR',
            currencyName: 'EUR',
            buyingPrice: 53.0,
            sellingPrice: 53.0,
            lastUpdate: DateTime.now()),
      );
      conversionRate = eurRate.buyingPrice > 0 ? eurRate.buyingPrice : 53.0;
    }

    double totalZakatableAssets = 0; // Sadece nakit/altın/ticaret malları havuzu
    double totalDebts = 0;
    double agricultureZakat = 0;
    double saimeLivestockZakat = 0;

    for (var asset in assets) {
      if (asset.category == AssetCategory.debt) {
        totalDebts += asset.value;
      } else if (asset.category == AssetCategory.agriculture) {
        // Tarım ürünleri kendi içinde hesaplanır, genel havuza (totalAssets) katılmaz.
        final irrigation = asset.details?['irrigationType'] ?? 'natural';
        final rate = irrigation == 'natural' ? 0.10 : 0.05;
        agricultureZakat += asset.value * rate;
      } else if (asset.category == AssetCategory.livestock) {
        final isTrade = asset.details?['isTrade'] == 'true' || asset.details?['isTrade'] == true;
        if (isTrade) {
          totalZakatableAssets += asset.value;
        } else {
          // Saime Hayvan Hesabı
          final type = asset.details?['livestockType'] ?? '';
          final quantity = int.tryParse(asset.details?['quantity']?.toString() ?? '0') ?? 0;
          final unitPriceStr = asset.details?['unitPrice']?.toString() ?? '0';
          final unitPrice = double.tryParse(unitPriceStr) ?? 0.0;
          
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
            animalZakatCount = quantity ~/ 30;
            customZakatValue = animalZakatCount * unitPrice;
          } else if (type == 'Deve' || type == 'Camel') {
            animalZakatCount = quantity ~/ 5;
            customZakatValue = animalZakatCount * (unitPrice / 10);
          }

          saimeLivestockZakat += customZakatValue;
        }
      } else {
        // Altın, Gümüş, Nakit
        if ((asset.category == AssetCategory.gold ||
                asset.category == AssetCategory.silver) &&
            asset.details?['isJewelry'] == true &&
            appState.sect != Sect.hanefi) {
          continue; // Şafii, Maliki, Hanbeli mezheplerinde kadının kullanımındaki takı zekata tabi değildir.
        }
        totalZakatableAssets += asset.value;
      }
    }

    double netZakatableAmount = totalZakatableAssets;

    // Hanefi ve Hanbeli mezheplerinde borçlar nisap hesabından düşülür.
    if (appState.sect == Sect.hanefi || appState.sect == Sect.hanbeli) {
      netZakatableAmount = totalZakatableAssets - totalDebts;
    }

    if (netZakatableAmount < 0) {
      netZakatableAmount = 0;
    }

    final nisabThreshold = appState.nisabType == NisabType.silver
        ? 595.0 * silverRate
        : 80.18 * goldRate;
    final isNisabReached = netZakatableAmount >= nisabThreshold;

    double zakatToPay = 0;
    
    // Altın, gümüş, para ve ticaret mallarının zekatı
    if (isNisabReached) {
      zakatToPay = totalZakatableAssets * 0.025;
      
      // Borçların zekattan düşülmesi (Sadece Hanefi ve Hanbeli)
      if (appState.sect == Sect.hanefi || appState.sect == Sect.hanbeli) {
        zakatToPay -= totalDebts * 0.025;
      }
      
      if (zakatToPay < 0.0) {
        zakatToPay = 0.0;
      }
    }

    // Tarım ve Saime Hayvan zekatları kendi nisaplarına sahip oldukları varsayılarak doğrudan eklenir
    zakatToPay += agricultureZakat;
    zakatToPay += saimeLivestockZakat;

    // Hesaplama sonucunda, UI'da gösterilen totalAssets'in doğru kalması için
    double totalDisplayAssets = 0;
    for (var a in assets) {
      if (a.category != AssetCategory.debt) {
        totalDisplayAssets += a.value;
      }
    }

    return CalculationResult(
      totalAssets: totalDisplayAssets / conversionRate,
      totalDebts: totalDebts / conversionRate,
      netZakatableAmount: netZakatableAmount / conversionRate,
      nisabThreshold: nisabThreshold / conversionRate,
      isNisabReached: isNisabReached,
      zakatToPay: zakatToPay / conversionRate,
      goldRate: goldRate / conversionRate,
      conversionRate: conversionRate,
    );
  }
}
