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
import '../../../calculator/presentation/calculator_provider.dart';
import '../../../exchange_rates/presentation/exchange_rate_provider.dart';

class GoldAssetForm extends ConsumerStatefulWidget {
  final AssetModel? existingAsset;
  final VoidCallback onBack;

  const GoldAssetForm({super.key, this.existingAsset, required this.onBack});

  @override
  ConsumerState<GoldAssetForm> createState() => _GoldAssetFormState();
}

class _GoldAssetFormState extends ConsumerState<GoldAssetForm> {
  final _formKey = GlobalKey<FormState>();
  String _goldType = 'Gram';
  String _purity = '24';
  final _goldQuantityController = TextEditingController();
  bool _isJewelry = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAsset != null) {
      _goldType = widget.existingAsset!.details?['goldType'] ?? 'Gram';
      _purity = widget.existingAsset!.details?['purity'] ?? '24';
      _goldQuantityController.text = widget.existingAsset!.details?['quantity'] ?? '';
      _isJewelry = widget.existingAsset!.details?['isJewelry'] ?? false;
    }
  }

  @override
  void dispose() {
    _goldQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;
    final goldRateAsync = ref.watch(goldRateProvider);
    final goldPrice = goldRateAsync.value ?? CurrencyConstants.defaultGoldRate;
    final ratesAsync = ref.watch(exchangeRatesProvider);
    final rates = ratesAsync.value ?? [];

    final conversionRate = CurrencyConstants.getConversionRate(appState.currency, rates);

    final goldTypes = isTr
        ? ['Gram', 'Çeyrek', 'Yarım', 'Tam', 'Cumhuriyet', 'Ata']
        : ['Gram', 'Quarter', 'Half', 'Full', 'Republic', 'Ata'];

    double getPurityFactor(String k) {
      switch (k) {
        case '24': return 1.0;
        case '22': return 0.916;
        case '18': return 0.75;
        case '14': return 0.585;
        default: return 1.0;
      }
    }

    double getUnitGoldPrice() {
      if (_goldType == 'Gram') {
        return goldPrice * getPurityFactor(_purity);
      }
      switch (_goldType) {
        case 'Çeyrek':
        case 'Quarter':
          return goldPrice * 1.64;
        case 'Yarım':
        case 'Half':
          return goldPrice * 3.28;
        case 'Tam':
        case 'Full':
          return goldPrice * 6.56;
        case 'Cumhuriyet':
        case 'Republic':
          return goldPrice * 6.68;
        case 'Ata':
          return goldPrice * 6.75;
        default:
          return goldPrice * getPurityFactor(_purity);
      }
    }

    final unitPriceTRY = getUnitGoldPrice();
    final quantity = double.tryParse(_goldQuantityController.text) ?? 0.0;
    final totalValueTRY = quantity * unitPriceTRY;

    final unitPriceConverted = unitPriceTRY / conversionRate;
    final totalValueConverted = totalValueTRY / conversionRate;

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
              Text(isTr ? 'Altın Ekle' : 'Add Gold', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'ALTIN TÜRÜ' : 'GOLD TYPE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: goldTypes.map((type) {
              final isSelected = _goldType == type;
              return ChoiceChip(
                label: Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : (appState.isDark ? Colors.white70 : Colors.black87))),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: appState.isDark ? Colors.white10 : Colors.grey.shade100,
                side: BorderSide(color: isSelected ? AppColors.primary : (appState.isDark ? AppColors.borderDark : AppColors.borderLight)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _goldType = type;
                    });
                  }
                },
              );
            }).toList(),
          ),
          if (_goldType == 'Gram') ...[
            const SizedBox(height: 16),
            Text(isTr ? 'AYAR (SAFLIK DERECESİ)' : 'PURITY (CARAT)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            AppPillGroup<String>(
              selectedValue: _purity,
              options: const [
                AppPillOption(value: '24', label: '24 K'),
                AppPillOption(value: '22', label: '22 K'),
                AppPillOption(value: '18', label: '18 K'),
                AppPillOption(value: '14', label: '14 K'),
              ],
              onSelected: (val) => setState(() => _purity = val),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _goldQuantityController,
            decoration: AppFormControls.inputDecoration(
              context: context,
              labelText: _goldType == 'Gram' ? (isTr ? 'Miktar (Gram)' : 'Quantity (Grams)') : (isTr ? 'Adet' : 'Quantity'),
              suffixText: _goldType == 'Gram' ? 'gr' : (isTr ? 'adet' : 'pcs'),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir miktar girin' : 'Please enter a quantity') : null,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(isTr ? 'Kişisel Takı (Ziynet)' : 'Personal Jewelry', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              appState.sect == Sect.hanefi
                  ? (isTr
                      ? 'Hanefi mezhebine göre kişisel takılar zekata tabidir.'
                      : 'According to Hanafi sect, personal jewelry is subject to Zakat.')
                  : (isTr
                      ? 'Seçili mezhebe göre kişisel takılar zekattan muaftır.'
                      : 'According to the selected sect, personal jewelry is exempt from Zakat.'),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            value: _isJewelry,
            onChanged: (val) {
              setState(() {
                _isJewelry = val;
              });
            },
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          AppLiveValuationCard(
            label: isTr ? 'Toplam Değer' : 'Total Value',
            value: '${appState.currency.symbol}${totalValueConverted.toStringAsFixed(2)}',
            secondaryText: '${isTr ? "Birim Fiyat" : "Unit Price"}: ${appState.currency.symbol}${unitPriceConverted.toStringAsFixed(2)}',
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
                    final asset = AssetModel(
                      id: widget.existingAsset?.id ?? const Uuid().v4(),
                      name: _goldType == 'Gram' 
                          ? '${_purity}K $_goldType ${isTr ? "Altın" : "Gold"}'
                          : '$_goldType ${isTr ? "Altın" : "Gold"}',
                      category: AssetCategory.gold,
                      value: totalValueTRY,
                      details: {
                        'goldType': _goldType,
                        'purity': _purity,
                        'quantity': _goldQuantityController.text,
                        'unitPrice': unitPriceTRY.toString(),
                        'isJewelry': _isJewelry,
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
