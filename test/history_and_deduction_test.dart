import 'package:flutter_test/flutter_test.dart';
import 'package:zekat_app_mobile/features/assets/domain/asset_model.dart';
import 'package:zekat_app_mobile/features/history/domain/history_model.dart';

void main() {
  group('HistoryModel and AssetModel tests', () {
    test('AssetModel.clone creates deep copy of asset and its details', () {
      final original = AssetModel(
        id: 'asset_1',
        name: 'Vadesiz TL',
        category: AssetCategory.cash,
        value: 50000.0,
        details: {
          'currency': 'TRY',
          'originalAmount': 50000.0,
        },
      );

      final cloned = original.clone();

      expect(cloned.id, original.id);
      expect(cloned.name, original.name);
      expect(cloned.category, original.category);
      expect(cloned.value, original.value);
      expect(cloned.details?['currency'], 'TRY');
      expect(cloned.details?['originalAmount'], 50000.0);

      // Mutating clone should not affect original
      cloned.value = 40000.0;
      cloned.details?['originalAmount'] = 40000.0;

      expect(original.value, 50000.0);
      expect(original.details?['originalAmount'], 50000.0);
    });

    test('HistoryModel stores snapshot metrics and paymentMethod correctly', () {
      final assets = [
        AssetModel(
          id: '1',
          name: 'Nakit TL',
          category: AssetCategory.cash,
          value: 100000.0,
        ),
      ];

      final liabilities = [
        AssetModel(
          id: '2',
          name: 'Kredi Borcu',
          category: AssetCategory.debt,
          value: 20000.0,
        ),
      ];

      final historyItem = HistoryModel(
        id: 123456789,
        period: 'Zekat Ödemesi',
        gregorian: 'Eylül 2026',
        amount: 2000.0,
        currency: 'TRY',
        status: 'paid',
        assetCount: 1,
        date: '2026-09-16T10:00:00.000',
        assets: assets,
        liabilities: liabilities,
        hijriDate: 'Rebiülevvel 1448',
        totalAssets: 100000.0,
        totalDebts: 20000.0,
        netZakatableAmount: 80000.0,
        nisabThreshold: 549000.0,
        paymentMethod: 'cash_deduction',
      );

      expect(historyItem.totalAssets, 100000.0);
      expect(historyItem.totalDebts, 20000.0);
      expect(historyItem.netZakatableAmount, 80000.0);
      expect(historyItem.nisabThreshold, 549000.0);
      expect(historyItem.paymentMethod, 'cash_deduction');
      expect(historyItem.assets.length, 1);
      expect(historyItem.liabilities.length, 1);
    });
  });
}
