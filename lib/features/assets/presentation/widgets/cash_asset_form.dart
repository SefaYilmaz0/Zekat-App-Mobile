import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/constants/currency_constants.dart';
import '../../../../core/theme.dart';
import '../../../../core/presentation/widgets/app_form_controls.dart';
import '../../domain/asset_model.dart';
import '../../../exchange_rates/presentation/exchange_rate_provider.dart';

class CashAssetForm extends ConsumerStatefulWidget {
  final AssetCategory category;
  final AssetModel? existingAsset;
  final VoidCallback onBack;

  const CashAssetForm({super.key, required this.category, this.existingAsset, required this.onBack});

  @override
  ConsumerState<CashAssetForm> createState() => _CashAssetFormState();
}

class _CashAssetFormState extends ConsumerState<CashAssetForm> {
  final _formKey = GlobalKey<FormState>();
  String _currency = 'TRY';
  final _cashAmountController = TextEditingController();
  bool _isShortTerm = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingAsset != null) {
      _currency = widget.existingAsset!.details?['currency'] ?? 'TRY';
      _cashAmountController.text = widget.existingAsset!.details?['originalAmount'] ?? '';
      _isShortTerm = widget.existingAsset!.details?['isShortTerm'] != false;
    }
  }

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

    final conversionRate = CurrencyConstants.getConversionRate(appState.currency, rates);
    final currentRate = CurrencyConstants.getCurrencyToTryRate(_currency, rates);

    final amount = double.tryParse(_cashAmountController.text) ?? 0.0;
    final totalValueTRY = amount * currentRate;
    final totalValueConverted = totalValueTRY / conversionRate;

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

    final currencySymbol = appState.currency.symbol;

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
          Text(isTr ? 'PARA BİRİMİ' : 'CURRENCY', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          AppPillGroup<String>(
            selectedValue: _currency,
            options: const [
              AppPillOption(value: 'TRY', label: '₺ TRY'),
              AppPillOption(value: 'USD', label: '\$ USD'),
              AppPillOption(value: 'EUR', label: '€ EUR'),
            ],
            onSelected: (val) => setState(() => _currency = val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cashAmountController,
            decoration: AppFormControls.inputDecoration(
              context: context,
              labelText: getLabelText(),
              suffixText: _currency,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen geçerli bir tutar girin' : 'Please enter a valid amount') : null,
          ),
          if (widget.category == AssetCategory.debt) ...[
            const SizedBox(height: 16),
            Text(isTr ? 'BORÇ VADESİ' : 'DEBT TERM', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            AppPillGroup<bool>(
              selectedValue: _isShortTerm,
              options: [
                AppPillOption(
                  value: true,
                  label: isTr ? 'Kısa Vadeli' : 'Short-Term',
                  subtitle: isTr ? '1 Yıl İçinde (Düşülür)' : 'Due in 1 Yr (Deducted)',
                ),
                AppPillOption(
                  value: false,
                  label: isTr ? 'Uzun Vadeli' : 'Long-Term',
                  subtitle: isTr ? '1 Yıldan Sonra (Düşülmez)' : '> 1 Yr (Not Deducted)',
                ),
              ],
              onSelected: (val) => setState(() => _isShortTerm = val),
            ),
            const SizedBox(height: 8),
            Text(
              isTr
                  ? (_isShortTerm
                      ? 'Vadesi gelmiş veya 1 yıl içinde ödenecek borçlar Hanefi ve Hanbeli mezheplerinde matrahtan düşülür.'
                      : 'Fıkha göre uzun vadeli konut/taşıt gibi borçların vadesi gelmemiş sonraki yılları zekat matrahından düşülmez.')
                  : (_isShortTerm
                      ? 'Debts due within 1 year are deducted from the nisab in Hanafi and Hanbali schools.'
                      : 'According to fiqh, long-term installments beyond the current year are not deducted.'),
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted, height: 1.3),
            ),
          ],
          const SizedBox(height: 16),
          AppLiveValuationCard(
            label: isTr ? '$currencySymbol Karşılığı' : '$currencySymbol Equivalent',
            value: '$currencySymbol${totalValueConverted.toStringAsFixed(2)}',
            secondaryText: _currency != 'TRY' ? 'Kur: ₺${currentRate.toStringAsFixed(2)}' : null,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: AppColors.textMuted)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String categoryName = '';
                    if (widget.category == AssetCategory.cash) categoryName = isTr ? 'Nakit' : 'Cash';
                    if (widget.category == AssetCategory.receivable) categoryName = isTr ? 'Alacak' : 'Receivable';
                    if (widget.category == AssetCategory.debt) {
                      categoryName = _isShortTerm
                          ? (isTr ? 'Kısa Vadeli Borç' : 'Short-Term Debt')
                          : (isTr ? 'Uzun Vadeli Borç' : 'Long-Term Debt');
                    }

                    final asset = AssetModel(
                      id: widget.existingAsset?.id ?? const Uuid().v4(),
                      name: '$_currency $categoryName',
                      category: widget.category,
                      value: totalValueTRY,
                      details: {
                        'currency': _currency,
                        'originalAmount': _cashAmountController.text,
                        'exchangeRate': currentRate,
                        'isShortTerm': _isShortTerm,
                      },
                    );
                    final box = Hive.box<AssetModel>('assets');
                    box.put(asset.id, asset);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
