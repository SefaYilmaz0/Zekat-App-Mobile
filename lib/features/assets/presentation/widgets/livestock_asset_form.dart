import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/providers/app_state_provider.dart';
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

    double usdPrice = 46.0;
    double eurPrice = 53.0;
    for (var r in rates) {
      if (r.currencyCode == 'USD') usdPrice = r.buyingPrice;
      if (r.currencyCode == 'EUR') eurPrice = r.buyingPrice;
    }

    double conversionRate = 1.0;
    if (appState.currency == AppCurrency.usd) {
      conversionRate = usdPrice > 0 ? usdPrice : 46.0;
    } else if (appState.currency == AppCurrency.eur) {
      conversionRate = eurPrice > 0 ? eurPrice : 53.0;
    }

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
          Text(isTr ? 'HAYVAN TÜRÜ' : 'LIVESTOCK TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: animalTypes.map((type) {
              final isSelected = _livestockType == type;
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
                    onPressed: () => setState(() => _livestockType = type),
                    child: Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSelected ? const Color(0xFFF3A712) : (appState.isDark ? Colors.white70 : Colors.black54))),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'YETİŞTİRME AMACI' : 'PURPOSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_isTrade ? const Color(0xFFF3A712).withValues(alpha: 0.1) : Colors.transparent,
                      side: BorderSide(color: !_isTrade ? const Color(0xFFF3A712) : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => setState(() => _isTrade = false),
                    child: Column(
                      children: [
                        Text(isTr ? 'Saime' : 'Grazing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: !_isTrade ? const Color(0xFFF3A712) : (appState.isDark ? Colors.white70 : Colors.black54))),
                        Text(isTr ? 'Süt/Üreme' : 'Milk/Breeding', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _isTrade ? const Color(0xFFF3A712).withValues(alpha: 0.1) : Colors.transparent,
                      side: BorderSide(color: _isTrade ? const Color(0xFFF3A712) : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => setState(() => _isTrade = true),
                    child: Column(
                      children: [
                        Text(isTr ? 'Ticaret' : 'Trade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _isTrade ? const Color(0xFFF3A712) : (appState.isDark ? Colors.white70 : Colors.black54))),
                        Text(isTr ? 'Alım-Satım' : 'Buying-Selling', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _livestockQuantityController,
            decoration: InputDecoration(
              labelText: isTr ? 'Adet' : 'Quantity',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: isTr ? 'adet' : 'pcs',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir miktar girin' : 'Please enter a quantity') : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _livestockUnitPriceController,
            decoration: InputDecoration(
              labelText: isTr ? 'Birim Değer ($currencySymbol)' : 'Unit Value ($currencySymbol)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: currencySymbol,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir birim değer girin' : 'Please enter a unit value') : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isTr ? 'Tahmini Toplam:' : 'Estimated Total:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$currencySymbol${totalValueConverted.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF3A712))),
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
