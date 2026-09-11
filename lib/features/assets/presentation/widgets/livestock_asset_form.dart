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

class LivestockAssetForm extends ConsumerStatefulWidget {
  final AssetModel? existingAsset;
  final VoidCallback onBack;

  const LivestockAssetForm({super.key, this.existingAsset, required this.onBack});

  @override
  ConsumerState<LivestockAssetForm> createState() => _LivestockAssetFormState();
}

class _LivestockAssetFormState extends ConsumerState<LivestockAssetForm> {
  final _formKey = GlobalKey<FormState>();
  String _livestockType = 'Koyun/Keçi';
  final _livestockQuantityController = TextEditingController();
  final _livestockUnitPriceController = TextEditingController();
  bool _isTrade = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAsset != null) {
      _livestockType = widget.existingAsset!.details?['livestockType'] ?? 'Koyun/Keçi';
      _livestockQuantityController.text = widget.existingAsset!.details?['quantity'] ?? '';
      _isTrade = widget.existingAsset!.details?['isTrade'] == 'true';
    }
  }

  @override
  void dispose() {
    _livestockQuantityController.dispose();
    _livestockUnitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;
    final ratesAsync = ref.watch(exchangeRatesProvider);
    final rates = ratesAsync.value ?? [];

    final conversionRate = CurrencyConstants.getConversionRate(appState.currency, rates);

    if (widget.existingAsset != null && !_isInitialized && rates.isNotEmpty) {
      final storedUnitPrice = double.tryParse(widget.existingAsset!.details?['unitPrice'] ?? '') ?? 0.0;
      _livestockUnitPriceController.text = (storedUnitPrice / conversionRate).toStringAsFixed(2);
      _isInitialized = true;
    }

    final quantity = double.tryParse(_livestockQuantityController.text) ?? 0.0;
    final unitPriceConverted = double.tryParse(_livestockUnitPriceController.text) ?? 0.0;
    final totalValueConverted = quantity * unitPriceConverted;
    final totalValueTRY = totalValueConverted * conversionRate;

    final animalTypes = isTr
        ? ['Koyun/Keçi', 'Sığır/Manda', 'Deve']
        : ['Sheep/Goat', 'Cattle/Buffalo', 'Camel'];

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
              Text(isTr ? 'Hayvan Ekle' : 'Add Livestock', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'HAYVAN TÜRÜ' : 'LIVESTOCK TYPE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          AppPillGroup<String>(
            selectedValue: _livestockType,
            options: animalTypes.map((type) => AppPillOption(value: type, label: type)).toList(),
            onSelected: (val) => setState(() => _livestockType = val),
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'YETİŞTİRME AMACI' : 'PURPOSE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          AppPillGroup<bool>(
            selectedValue: _isTrade,
            options: [
              AppPillOption(
                value: false,
                label: isTr ? 'Saime' : 'Grazing',
                subtitle: isTr ? 'Süt/Üreme' : 'Milk/Breeding',
              ),
              AppPillOption(
                value: true,
                label: isTr ? 'Ticaret' : 'Trade',
                subtitle: isTr ? 'Alım-Satım' : 'Buying-Selling',
              ),
            ],
            onSelected: (val) => setState(() => _isTrade = val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _livestockQuantityController,
            decoration: AppFormControls.inputDecoration(
              context: context,
              labelText: isTr ? 'Adet' : 'Quantity',
              suffixText: isTr ? 'adet' : 'pcs',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir miktar girin' : 'Please enter a quantity') : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _livestockUnitPriceController,
            decoration: AppFormControls.inputDecoration(
              context: context,
              labelText: isTr ? 'Birim Değer ($currencySymbol)' : 'Unit Value ($currencySymbol)',
              suffixText: currencySymbol,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir birim değer girin' : 'Please enter a unit value') : null,
          ),
          const SizedBox(height: 8),
          // Akıllı Piyasa Fiyatı Ön Tanımları (Smart Presets)
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                isTr ? '2026 Piyasa Tahminleri:' : '2026 Market Estimates:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: () {
              final isCattle = _livestockType.contains('Sığır') || _livestockType.contains('Cattle');
              final isCamel = _livestockType.contains('Deve') || _livestockType.contains('Camel');
              final presetsTRY = isCattle
                  ? [85000.0, 115000.0, 145000.0]
                  : isCamel
                      ? [100000.0, 130000.0, 160000.0]
                      : [12000.0, 15000.0, 18000.0];

              return presetsTRY.map((presetTRY) {
                final convertedPreset = presetTRY / conversionRate;
                final formattedValue = convertedPreset >= 1000
                    ? '${(convertedPreset / 1000).toStringAsFixed(convertedPreset % 1000 == 0 ? 0 : 1)}k $currencySymbol'
                    : '${convertedPreset.toStringAsFixed(0)} $currencySymbol';

                return ActionChip(
                  avatar: const Icon(Icons.touch_app_outlined, size: 13, color: AppColors.primary),
                  label: Text(
                    formattedValue,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () {
                    setState(() {
                      _livestockUnitPriceController.text = convertedPreset.toStringAsFixed(0);
                    });
                  },
                );
              }).toList();
            }(),
          ),
          const SizedBox(height: 16),
          AppLiveValuationCard(
            label: isTr ? 'Tahmini Toplam' : 'Estimated Total',
            value: '$currencySymbol${totalValueConverted.toStringAsFixed(2)}',
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
                      name: '$_livestockType ${isTr ? "(Hayvan)" : "(Livestock)"}',
                      category: AssetCategory.livestock,
                      value: totalValueTRY,
                      details: {
                        'livestockType': _livestockType,
                        'quantity': _livestockQuantityController.text,
                        'unitPrice': (unitPriceConverted * conversionRate).toString(),
                        'isTrade': _isTrade.toString(),
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
