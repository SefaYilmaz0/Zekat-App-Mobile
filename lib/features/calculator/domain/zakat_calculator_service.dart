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

    double totalAssets = 0;
    double totalDebts = 0;

    for (var asset in assets) {
      if (asset.category == AssetCategory.debt) {
        totalDebts += asset.value;
      } else {
        if ((asset.category == AssetCategory.gold ||
                asset.category == AssetCategory.silver) &&
            asset.details?['isJewelry'] == true &&
            appState.sect != Sect.hanefi) {
          continue; // Şafii, Maliki, Hanbeli mezheplerinde kadının kullanımındaki takı zekata tabi değildir.
        }
        totalAssets += asset.value;
      }
    }

    double netZakatableAmount = totalAssets;

    // Hanefi ve Hanbeli mezheplerinde borçlar toplam varlıktan düşülür.
    if (appState.sect == Sect.hanefi || appState.sect == Sect.hanbeli) {
      netZakatableAmount = totalAssets - totalDebts;
    }

    if (netZakatableAmount < 0) {
      netZakatableAmount = 0;
    }

    final nisabThreshold = appState.nisabType == NisabType.silver
        ? 595.0 * silverRate
        : 80.18 * goldRate;
    final isNisabReached = netZakatableAmount >= nisabThreshold;

    double zakatToPay = 0;
    if (isNisabReached) {
      double tempZakat = 0;
      for (var asset in assets) {
        if (asset.category == AssetCategory.debt) continue;
        if ((asset.category == AssetCategory.gold ||
                asset.category == AssetCategory.silver) &&
            asset.details?['isJewelry'] == true &&
            appState.sect != Sect.hanefi) {
          continue;
        }

        if (asset.category == AssetCategory.agriculture) {
          final irrigation = asset.details?['irrigationType'] ?? 'natural';
          final rate = irrigation == 'natural' ? 0.10 : 0.05;
          tempZakat += asset.value * rate;
        } else {
          tempZakat += asset.value * 0.025;
        }
      }
      
      // Borçların zekatı (eksi olarak yansıtılır)
      tempZakat -= totalDebts * 0.025;
      zakatToPay = tempZakat < 0.0 ? 0.0 : tempZakat;
    }

    return CalculationResult(
      totalAssets: totalAssets / conversionRate,
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
