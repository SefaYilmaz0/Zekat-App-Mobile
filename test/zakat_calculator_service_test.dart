import 'package:flutter_test/flutter_test.dart';
import 'package:zekat_app_mobile/core/constants/currency_constants.dart';
import 'package:zekat_app_mobile/core/domain/app_state.dart';
import 'package:zekat_app_mobile/core/domain/enums.dart';
import 'package:zekat_app_mobile/features/assets/domain/asset_model.dart';
import 'package:zekat_app_mobile/features/calculator/domain/zakat_calculator_service.dart';
import 'package:zekat_app_mobile/features/exchange_rates/domain/exchange_rate_model.dart';

void main() {
  late ZakatCalculatorService service;
  const double testGoldRate = 6848.0; // 1 gr 24K altın
  const double testSilverRate = 102.0; // 1 gr gümüş
  final List<ExchangeRateModel> testRates = [
    ExchangeRateModel(currencyCode: 'USD', currencyName: 'USD', buyingPrice: 48.5, sellingPrice: 48.5, lastUpdate: DateTime.now()),
    ExchangeRateModel(currencyCode: 'EUR', currencyName: 'EUR', buyingPrice: 56.5, sellingPrice: 56.5, lastUpdate: DateTime.now()),
    ExchangeRateModel(currencyCode: 'GOLD', currencyName: 'GOLD', buyingPrice: testGoldRate, sellingPrice: testGoldRate, lastUpdate: DateTime.now()),
    ExchangeRateModel(currencyCode: 'SILVER', currencyName: 'SILVER', buyingPrice: testSilverRate, sellingPrice: testSilverRate, lastUpdate: DateTime.now()),
  ];

  setUp(() {
    service = ZakatCalculatorService();
  });

  AppState createAppState({
    Sect sect = Sect.hanefi,
    AppCurrency currency = AppCurrency.tryCurrency,
    NisabType nisabType = NisabType.gold,
  }) {
    return AppState(
      sect: sect,
      currency: currency,
      isDark: false,
      language: Language.tr,
      onboardingComplete: true,
      nisabType: nisabType,
    );
  }

  group('ZakatCalculatorService - Fıkhi ve Finansal Hesaplama Testleri', () {
    test('1. Hanefi: Varlıklar altın nisap eşiğinin (80.18 gr) altındaysa zekat 0 olmalıdır', () {
      final appState = createAppState(sect: Sect.hanefi, nisabType: NisabType.gold);
      // 50 gr 24K altın (50 * 6848 = 342.400 TL < 80.18 * 6848 = 549.073 TL)
      final assets = [
        AssetModel(
          id: '1',
          name: '24K Gram Altın',
          category: AssetCategory.gold,
          value: 50 * testGoldRate,
          details: {
            'goldType': 'Gram',
            'purity': '24',
            'quantity': '50',
            'unitPrice': testGoldRate.toString(),
            'isJewelry': false,
          },
        ),
      ];

      final result = service.calculate(
        appState: appState,
        assets: assets,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      expect(result.isNisabReached, isFalse);
      expect(result.zakatToPay, equals(0.0));
      expect(result.netZakatableAmount, equals(342400.0));
    });

    test('2. Hanefi: Varlıklar altın nisap eşiğinin üstündeyse %2.5 (1/40) zekat hesaplanmalıdır', () {
      final appState = createAppState(sect: Sect.hanefi, nisabType: NisabType.gold);
      // 100 gr 24K altın (684.800 TL > 549.073 TL)
      final assets = [
        AssetModel(
          id: '1',
          name: '24K Gram Altın',
          category: AssetCategory.gold,
          value: 100 * testGoldRate,
          details: {
            'goldType': 'Gram',
            'purity': '24',
            'quantity': '100',
            'unitPrice': testGoldRate.toString(),
            'isJewelry': false,
          },
        ),
      ];

      final result = service.calculate(
        appState: appState,
        assets: assets,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      expect(result.isNisabReached, isTrue);
      expect(result.netZakatableAmount, equals(684800.0));
      expect(result.zakatToPay, equals(684800.0 * 0.025)); // 17.120 TL
    });

    test('3. Hanefi: Kişisel ziynet (takı) altın zekata tabidir (Muafiyet YOK)', () {
      final appState = createAppState(sect: Sect.hanefi);
      final assets = [
        AssetModel(
          id: '1',
          name: '22K Bilezik',
          category: AssetCategory.gold,
          value: 100 * testGoldRate * 0.916,
          details: {
            'goldType': 'Gram',
            'purity': '22',
            'quantity': '100',
            'unitPrice': (testGoldRate * 0.916).toString(),
            'isJewelry': true, // Ziynet
          },
        ),
      ];

      final result = service.calculate(
        appState: appState,
        assets: assets,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      expect(result.isNisabReached, isTrue);
      expect(result.zakatToPay, greaterThan(0.0));
    });

    test('4. Şafii, Maliki, Hanbeli: Kadının kullanımındaki ziynet takı zekattan MUAFTIR', () {
      final sects = [Sect.safi, Sect.maliki, Sect.hanbeli];
      for (final sect in sects) {
        final appState = createAppState(sect: sect);
        final assets = [
          AssetModel(
            id: '1',
            name: '22K Bilezik',
            category: AssetCategory.gold,
            value: 100 * testGoldRate * 0.916,
            details: {
              'goldType': 'Gram',
              'purity': '22',
              'quantity': '100',
              'unitPrice': (testGoldRate * 0.916).toString(),
              'isJewelry': true, // Ziynet
            },
          ),
        ];

        final result = service.calculate(
          appState: appState,
          assets: assets,
          goldRate: testGoldRate,
          silverRate: testSilverRate,
          exchangeRates: testRates,
        );

        expect(result.zakatToPay, equals(0.0), reason: '$sect mezhebinde ziynet takı muaf olmalıdır');
      }
    });

    test('5. Hanefi: Kısa vadeli borç matrahtan düşülür ve nisap altına düşürüyorsa zekat 0 olur', () {
      final appState = createAppState(sect: Sect.hanefi);
      // 100 gr altın = 684.800 TL
      // Kısa vadeli borç = 300.000 TL -> Net matrah: 384.800 TL (< 549.073 TL nisap)
      final assets = [
        AssetModel(
          id: '1',
          name: '24K Altın',
          category: AssetCategory.gold,
          value: 100 * testGoldRate,
          details: {
            'goldType': 'Gram',
            'purity': '24',
            'quantity': '100',
            'unitPrice': testGoldRate.toString(),
          },
        ),
        AssetModel(
          id: '2',
          name: 'Kısa Vadeli Borç',
          category: AssetCategory.debt,
          value: 300000.0,
          details: {
            'currency': 'TRY',
            'originalAmount': '300000',
            'isShortTerm': true,
          },
        ),
      ];

      final result = service.calculate(
        appState: appState,
        assets: assets,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      expect(result.netZakatableAmount, equals(384800.0));
      expect(result.isNisabReached, isFalse);
      expect(result.zakatToPay, equals(0.0));
    });

    test('6. Hanefi: Uzun vadeli borç (1 yıldan sonraki) matrahtan DÜŞÜLMEZ', () {
      final appState = createAppState(sect: Sect.hanefi);
      // 100 gr altın = 684.800 TL
      // Uzun vadeli borç = 300.000 TL (Düşülmez) -> Net matrah: 684.800 TL
      final assets = [
        AssetModel(
          id: '1',
          name: '24K Altın',
          category: AssetCategory.gold,
          value: 100 * testGoldRate,
          details: {
            'goldType': 'Gram',
            'purity': '24',
            'quantity': '100',
            'unitPrice': testGoldRate.toString(),
          },
        ),
        AssetModel(
          id: '2',
          name: 'Uzun Vadeli Konut Kredisi',
          category: AssetCategory.debt,
          value: 300000.0,
          details: {
            'currency': 'TRY',
            'originalAmount': '300000',
            'isShortTerm': false, // Uzun vadeli
          },
        ),
      ];

      final result = service.calculate(
        appState: appState,
        assets: assets,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      expect(result.netZakatableAmount, equals(684800.0));
      expect(result.isNisabReached, isTrue);
      expect(result.zakatToPay, equals(684800.0 * 0.025));
    });

    test('7. Şafii ve Maliki: Eldeki zekatlık varlıktan borç DÜŞÜLMEZ', () {
      final appState = createAppState(sect: Sect.safi);
      // 100 gr altın = 684.800 TL
      // 300.000 TL borç olsa dahi Şafii'de matrahtan düşülmez
      final assets = [
        AssetModel(
          id: '1',
          name: '24K Altın',
          category: AssetCategory.gold,
          value: 100 * testGoldRate,
          details: {
            'goldType': 'Gram',
            'purity': '24',
            'quantity': '100',
            'unitPrice': testGoldRate.toString(),
          },
        ),
        AssetModel(
          id: '2',
          name: 'Borç',
          category: AssetCategory.debt,
          value: 300000.0,
          details: {
            'currency': 'TRY',
            'originalAmount': '300000',
            'isShortTerm': true,
          },
        ),
      ];

      final result = service.calculate(
        appState: appState,
        assets: assets,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      expect(result.netZakatableAmount, equals(684800.0));
      expect(result.isNisabReached, isTrue);
      expect(result.zakatToPay, equals(684800.0 * 0.025));
    });

    test('8. Gümüş Nisabı (595 gr): Gümüş nisabı seçildiğinde eşik 595 * gümüş kuru olmalıdır', () {
      final appState = createAppState(nisabType: NisabType.silver);
      // Gümüş nisap eşiği = 595 * 102 = 60.690 TL
      // 700 gr 999 ayar gümüş = 700 * 102 = 71.400 TL (> 60.690 TL)
      final assets = [
        AssetModel(
          id: '1',
          name: '999 Ayar Gümüş',
          category: AssetCategory.silver,
          value: 700 * testSilverRate,
          details: {
            'purity': '999',
            'quantity': '700',
          },
        ),
      ];

      final result = service.calculate(
        appState: appState,
        assets: assets,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      expect(result.nisabThreshold, equals(595 * testSilverRate));
      expect(result.isNisabReached, isTrue);
      expect(result.zakatToPay, equals(71400.0 * 0.025));
    });

    test('9. Tarım Ürünleri (Öşür): Doğal sulamada %10, yapay sulamada %5 öşür hesaplanmalıdır', () {
      final appState = createAppState();
      final assets = [
        AssetModel(
          id: '1',
          name: 'Buğday (Doğal Sulama)',
          category: AssetCategory.agriculture,
          value: 100000.0,
          details: {'irrigationType': 'natural'},
        ),
        AssetModel(
          id: '2',
          name: 'Mısır (Yapay Sulama)',
          category: AssetCategory.agriculture,
          value: 100000.0,
          details: {'irrigationType': 'artificial'},
        ),
      ];

      final result = service.calculate(
        appState: appState,
        assets: assets,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      // Doğal sulama %10 = 10.000 TL, Yapay sulama %5 = 5.000 TL -> Toplam = 15.000 TL
      expect(result.zakatToPay, equals(15000.0));
    });

    test('10. Saime Hayvan: 40 koyun için 1 koyun birim bedeli zekat hesaplanmalıdır', () {
      final appState = createAppState();
      const unitPrice = 8000.0;
      final assets = [
        AssetModel(
          id: '1',
          name: 'Koyun/Keçi',
          category: AssetCategory.livestock,
          value: 40 * unitPrice,
          details: {
            'livestockType': 'Koyun/Keçi',
            'quantity': '40',
            'unitPrice': unitPrice.toString(),
            'isTrade': 'false',
          },
        ),
      ];

      final result = service.calculate(
        appState: appState,
        assets: assets,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      // 40-120 koyunda 1 koyun zekattır
      expect(result.zakatToPay, equals(unitPrice));
    });

    test('11. Dinamik Kur Değerlemesi: Altın miktarı canlı kur değiştiğinde güncel kur üzerinden değerlenmelidir', () {
      final appState = createAppState();
      // Kullanıcı aylar önce 100 gr altın girdi ve o an value 250.000 TL kaydedildi diyelim
      final asset = AssetModel(
        id: '1',
        name: '24K Altın',
        category: AssetCategory.gold,
        value: 250000.0, // Eski statik değer
        details: {
          'goldType': 'Gram',
          'purity': '24',
          'quantity': '100', // Gerçek miktar
          'unitPrice': '2500',
        },
      );

      // Güncel kur 6848 TL olduğunda dinamik değer 684.800 TL olmalıdır
      final dynamicVal = CurrencyConstants.calculateDynamicAssetValueTRY(
        asset: asset,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );
      expect(dynamicVal, equals(100 * testGoldRate));

      final result = service.calculate(
        appState: appState,
        assets: [asset],
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      // Statik 250.000 TL yerine dinamik 684.800 TL üzerinden nisap ve zekat hesaplanmalıdır
      expect(result.netZakatableAmount, equals(684800.0));
      expect(result.isNisabReached, isTrue);
      expect(result.zakatToPay, equals(684800.0 * 0.025));
    });

    test('12. Döviz Dinamik Değerlemesi: USD nakit varlık güncel kurla değerlenmelidir', () {
      final appState = createAppState();
      final asset = AssetModel(
        id: '1',
        name: 'USD Nakit',
        category: AssetCategory.cash,
        value: 30000.0, // Eski statik değer
        details: {
          'currency': 'USD',
          'originalAmount': '20000', // 20.000 USD
        },
      );

      final result = service.calculate(
        appState: appState,
        assets: [asset],
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      // 20.000 USD * 48.5 = 970.000 TL
      expect(result.netZakatableAmount, equals(970000.0));
      expect(result.isNisabReached, isTrue);
      expect(result.zakatToPay, equals(970000.0 * 0.025));
    });

    test('13. Hedef Para Birimi (USD) seçildiğinde sonuçlar USD olarak normalize edilmelidir', () {
      final appState = createAppState(currency: AppCurrency.usd);
      final assets = [
        AssetModel(
          id: '1',
          name: 'USD Nakit',
          category: AssetCategory.cash,
          value: 485000.0,
          details: {
            'currency': 'USD',
            'originalAmount': '10000',
          },
        ),
      ];

      final result = service.calculate(
        appState: appState,
        assets: assets,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      expect(result.conversionRate, equals(48.5));
      // 10.000 USD net matrah
      expect(result.netZakatableAmount, closeTo(10000.0, 0.01));
      // Nisap eşiği USD karşılığı: (80.18 * 6848) / 48.5 = 11321.10 USD
      expect(result.nisabThreshold, closeTo((80.18 * testGoldRate) / 48.5, 0.1));
    });

    test('14. Çeyrek ve Yarım Altın hesaplama çarpanları doğru çalışmalıdır', () {
      // 10 adet Çeyrek altın (10 * 1.64 * 6848 = 112.307,20 TL)
      final ceyrek = AssetModel(
        id: '1',
        name: 'Çeyrek Altın',
        category: AssetCategory.gold,
        value: 0,
        details: {
          'goldType': 'Çeyrek',
          'quantity': '10',
        },
      );

      final val = CurrencyConstants.calculateDynamicAssetValueTRY(
        asset: ceyrek,
        goldRate: testGoldRate,
        silverRate: testSilverRate,
        exchangeRates: testRates,
      );

      expect(val, closeTo(10 * 1.64 * testGoldRate, 0.01));
    });
  });
}
