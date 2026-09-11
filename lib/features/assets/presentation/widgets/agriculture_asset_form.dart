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

class AgricultureAssetForm extends ConsumerStatefulWidget {
  final AssetModel? existingAsset;
  final VoidCallback onBack;

  const AgricultureAssetForm({super.key, this.existingAsset, required this.onBack});

  @override
  ConsumerState<AgricultureAssetForm> createState() => _AgricultureAssetFormState();
}

class _AgricultureAssetFormState extends ConsumerState<AgricultureAssetForm> {
  final _formKey = GlobalKey<FormState>();
  final _agricultureNameController = TextEditingController();
  String _irrigationType = 'natural';
  final _agricultureValueController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAsset != null) {
      String storedName = widget.existingAsset!.name;
      storedName = storedName
          .replaceAll(' (Tarım)', '')
          .replaceAll(' (Agriculture)', '');
      _agricultureNameController.text = storedName;
      _irrigationType = widget.existingAsset!.details?['irrigationType'] ?? 'natural';
    }
  }

  @override
  void dispose() {
    _agricultureNameController.dispose();
    _agricultureValueController.dispose();
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
      final storedValue = widget.existingAsset!.value;
      _agricultureValueController.text = (storedValue / conversionRate).toStringAsFixed(2);
      _isInitialized = true;
    }

    final amountConverted = double.tryParse(_agricultureValueController.text) ?? 0.0;
    final amountTRY = amountConverted * conversionRate;
    final ratePercent = _irrigationType == 'natural' ? '10% (Öşür)' : '5% (Yapay/Sulama)';

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
              Text(isTr ? 'Tarım Ürünü Ekle' : 'Add Agriculture', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _agricultureNameController,
            decoration: AppFormControls.inputDecoration(
              context: context,
              labelText: isTr ? 'Ürün Tanımı (Örn: Buğday, Arpa)' : 'Product Name (e.g. Wheat)',
            ),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir ürün adı girin' : 'Please enter a product name') : null,
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'SULAMA YÖNTEMİ' : 'IRRIGATION TYPE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          AppPillGroup<String>(
            selectedValue: _irrigationType,
            options: [
              AppPillOption(
                value: 'natural',
                label: isTr ? 'Doğal (Yağmur/Nehir)' : 'Natural (Rain/River)',
                subtitle: isTr ? 'Masrafsız (%10 Öşür)' : 'Cost-free (10% Ushr)',
              ),
              AppPillOption(
                value: 'artificial',
                label: isTr ? 'Yapay (Motor/Kuyu)' : 'Artificial (Irrigated)',
                subtitle: isTr ? 'Masraflı (%5 Öşür)' : 'Costly (5% Ushr)',
              ),
            ],
            onSelected: (val) => setState(() => _irrigationType = val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _agricultureValueController,
            decoration: AppFormControls.inputDecoration(
              context: context,
              labelText: isTr ? 'Toplam Değer ($currencySymbol)' : 'Total Value ($currencySymbol)',
              suffixText: currencySymbol,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen değeri girin' : 'Please enter value') : null,
          ),
          const SizedBox(height: 16),
          AppLiveValuationCard(
            label: isTr ? 'Zekat Oranı' : 'Zakat Rate',
            value: ratePercent,
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
                      name: '${_agricultureNameController.text} ${isTr ? "(Tarım)" : "(Agriculture)"}',
                      category: AssetCategory.agriculture,
                      value: amountTRY,
                      details: {
                        'irrigationType': _irrigationType,
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
