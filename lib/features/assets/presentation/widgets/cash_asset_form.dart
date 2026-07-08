import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../domain/asset_model.dart';
import '../../../exchange_rates/presentation/exchange_rate_provider.dart';

class CashAssetForm extends ConsumerStatefulWidget {
  final AssetCategory category;
  final VoidCallback onBack;

  const CashAssetForm({super.key, required this.category, required this.onBack});

  @override
  ConsumerState<CashAssetForm> createState() => _CashAssetFormState();
}

class _CashAssetFormState extends ConsumerState<CashAssetForm> {
  final _formKey = GlobalKey<FormState>();
  String _currency = 'TRY';
  final _cashAmountController = TextEditingController();

  @override
  void dispose() {
    _cashAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;
    final ratesAsync = ref.watch(exchangeRatesProvider);
    final rates = ratesAsync.value ?? [];

    double usdPrice = 46.0;
    double eurPrice = 53.0;

    for (var r in rates) {
      if (r.currencyCode == 'USD') usdPrice = r.buyingPrice;
      if (r.currencyCode == 'EUR') eurPrice = r.buyingPrice;
    }

    double getRate() {
      if (_currency == 'USD') return usdPrice;
      if (_currency == 'EUR') return eurPrice;
      return 1.0;
    }

    final currentRate = getRate();
    final amount = double.tryParse(_cashAmountController.text) ?? 0.0;
    final totalValue = amount * currentRate;

    String getTitle() {
      if (widget.category == AssetCategory.debt) return isTr ? 'Borç Ekle' : 'Add Debt';
      if (widget.category == AssetCategory.receivable) return isTr ? 'Alacak Ekle' : 'Add Receivable';
      return isTr ? 'Nakit Ekle' : 'Add Cash';
    }

    String getLabelText() {
      if (widget.category == AssetCategory.debt) return isTr ? 'Borç Miktarı' : 'Debt Amount';
      if (widget.category == AssetCategory.receivable) return isTr ? 'Alacak Miktarı' : 'Receivable Amount';
      return isTr ? 'Nakit Miktarı' : 'Cash Amount';
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Text(getTitle(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'PARA BİRİMİ' : 'CURRENCY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: ['TRY', 'USD', 'EUR'].map((c) {
              final isSelected = _currency == c;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xFFF3A712).withValues(alpha: 0.1) : Colors.transparent,
                      side: BorderSide(color: isSelected ? const Color(0xFFF3A712) : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _currency = c),
                    child: Text(c, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFF3A712) : (appState.isDark ? Colors.white70 : Colors.black54))),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cashAmountController,
            decoration: InputDecoration(
              labelText: getLabelText(),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: _currency,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen geçerli bir tutar girin' : 'Please enter a valid amount') : null,
          ),
          if (_currency != 'TRY') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appState.isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: appState.isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isTr ? 'Kur ($_currency/TRY):' : 'Rate ($_currency/TRY):', style: const TextStyle(fontSize: 12)),
                  Text('₺${currentRate.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isTr ? 'TRY Karşılığı:' : 'TRY Equivalent:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('₺${totalValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF3A712))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isTr ? 'İptal' : 'Cancel', style: TextStyle(color: Colors.grey.shade600)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String categoryName = '';
                    if (widget.category == AssetCategory.cash) categoryName = isTr ? 'Nakit' : 'Cash';
                    if (widget.category == AssetCategory.receivable) categoryName = isTr ? 'Alacak' : 'Receivable';
                    if (widget.category == AssetCategory.debt) categoryName = isTr ? 'Borç' : 'Debt';

                    final asset = AssetModel(
                      id: const Uuid().v4(),
                      name: '$_currency $categoryName',
                      category: widget.category,
                      value: totalValue,
                      details: {
                        'currency': _currency,
                        'originalAmount': _cashAmountController.text,
                        'exchangeRate': currentRate,
                      },
                    );
                    final box = Hive.box<AssetModel>('assets');
                    box.put(asset.id, asset);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3A712),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isTr ? 'Kaydet' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
