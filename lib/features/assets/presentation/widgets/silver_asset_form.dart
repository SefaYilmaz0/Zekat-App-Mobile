import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/providers/app_state_provider.dart';
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
    final silverPrice = silverRateAsync.value ?? 38.0;
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
          Text(isTr ? 'GÜMÜŞ TÜRÜ' : 'SILVER TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: silverTypes.map((type) {
              final isSelected = _silverType == type;
              return ChoiceChip(
                label: Text(type, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (appState.isDark ? Colors.white70 : Colors.black87))),
                selected: isSelected,
                selectedColor: const Color(0xFFF3A712),
                backgroundColor: appState.isDark ? Colors.grey.shade900 : Colors.grey.shade100,
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
          Text(isTr ? 'AYAR (MİLYEM)' : 'PURITY (MILLIEME)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: ['999', '925', '900', '800'].map((k) {
              final isSelected = _purity == k;
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
                    onPressed: () => setState(() => _purity = k),
                    child: Text(k, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFF3A712) : (appState.isDark ? Colors.white70 : Colors.black54))),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _silverQuantityController,
            decoration: InputDecoration(
              labelText: isTr ? 'Miktar (Gram)' : 'Quantity (Grams)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: 'gr',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir miktar girin' : 'Please enter a quantity') : null,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(isTr ? 'Kişisel Takı (Ziynet)' : 'Personal Jewelry'),
            subtitle: Text(
              appState.sect == Sect.hanefi
                  ? (isTr
                      ? 'Hanefi mezhebine göre kişisel takılar zekata tabidir.'
                      : 'According to Hanafi sect, personal jewelry is subject to Zakat.')
                  : (isTr
                      ? 'Seçili mezhebe göre kişisel takılar zekattan muaftır.'
                      : 'According to the selected sect, personal jewelry is exempt from Zakat.'),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            value: _isJewelry,
            onChanged: (val) {
              setState(() {
                _isJewelry = val;
              });
            },
            activeThumbColor: const Color(0xFFF3A712),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appState.isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: appState.isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isTr ? 'Birim Fiyat:' : 'Unit Price:', style: const TextStyle(fontSize: 12)),
                    Text('${appState.currency.symbol}${unitPriceConverted.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isTr ? 'Toplam Değer:' : 'Total Value:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${appState.currency.symbol}${totalValueConverted.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF3A712))),
                  ],
                ),
              ],
            ),
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
                      name: '${_purity}K $_silverType ${isTr ? "Gümüş" : "Silver"}',
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
