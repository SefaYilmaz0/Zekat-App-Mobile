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

class SilverAssetForm extends ConsumerStatefulWidget {
  final AssetModel? existingAsset;
  final VoidCallback onBack;

  const SilverAssetForm({super.key, this.existingAsset, required this.onBack});

  @override
  ConsumerState<SilverAssetForm> createState() => _SilverAssetFormState();
}

class _SilverAssetFormState extends ConsumerState<SilverAssetForm> {
  final _formKey = GlobalKey<FormState>();
  String _silverType = 'Gram';
  String _purity = '925';
  final _silverQuantityController = TextEditingController();
  bool _isJewelry = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAsset != null) {
      _silverType = widget.existingAsset!.details?['silverType'] ?? 'Gram';
      _purity = widget.existingAsset!.details?['purity'] ?? '925';
      _silverQuantityController.text = widget.existingAsset!.details?['quantity'] ?? '';
      _isJewelry = widget.existingAsset!.details?['isJewelry'] ?? false;
    }
  }

  @override
  void dispose() {
    _silverQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;
    final silverRateAsync = ref.watch(silverRateProvider);
    final silverPrice = silverRateAsync.value ?? CurrencyConstants.defaultSilverRate;
    final ratesAsync = ref.watch(exchangeRatesProvider);
    final rates = ratesAsync.value ?? [];

    final conversionRate = CurrencyConstants.getConversionRate(appState.currency, rates);

    final silverTypes = isTr
        ? ['Gram', 'Takı (Ziynet)', 'Külçe']
        : ['Gram', 'Jewelry', 'Bar'];

    double getPurityFactor(String k) {
      switch (k) {
        case '999': return 1.0;
        case '925': return 0.925;
        case '900': return 0.900;
        case '800': return 0.800;
        default: return 1.0;
      }
    }

    double getUnitSilverPrice() {
      return silverPrice * getPurityFactor(_purity);
    }

    final unitPriceTRY = getUnitSilverPrice();
    final quantity = double.tryParse(_silverQuantityController.text) ?? 0.0;
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
              Text(isTr ? 'Gümüş Ekle' : 'Add Silver', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'GÜMÜŞ TÜRÜ' : 'SILVER TYPE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: silverTypes.map((type) {
              final isSelected = _silverType == type;
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
                      _silverType = type;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'AYAR (MİLYEM)' : 'PURITY (MILLIEME)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          AppPillGroup<String>(
            selectedValue: _purity,
            options: const [
              AppPillOption(value: '999', label: '999 Milyem', subtitle: 'Has Gümüş'),
              AppPillOption(value: '925', label: '925 Ayar', subtitle: 'Standart Takı'),
              AppPillOption(value: '900', label: '900 Ayar'),
              AppPillOption(value: '800', label: '800 Ayar'),
            ],
            onSelected: (val) => setState(() => _purity = val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _silverQuantityController,
            decoration: AppFormControls.inputDecoration(
              context: context,
              labelText: isTr ? 'Miktar (Gram)' : 'Quantity (Grams)',
              suffixText: 'gr',
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
                      name: '$_purity ${isTr ? "Ayar" : "Purity"} $_silverType ${isTr ? "Gümüş" : "Silver"}',
                      category: AssetCategory.silver,
                      value: totalValueTRY,
                      details: {
                        'silverType': _silverType,
                        'purity': _purity,
                        'quantity': _silverQuantityController.text,
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
