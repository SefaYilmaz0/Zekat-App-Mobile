import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../domain/asset_model.dart';
import '../../../calculator/presentation/calculator_provider.dart';

class GoldAssetForm extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const GoldAssetForm({super.key, required this.onBack});

  @override
  ConsumerState<GoldAssetForm> createState() => _GoldAssetFormState();
}

class _GoldAssetFormState extends ConsumerState<GoldAssetForm> {
  final _formKey = GlobalKey<FormState>();
  String _goldType = 'Gram';
  String _purity = '24';
  final _goldQuantityController = TextEditingController();

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
    final goldPrice = goldRateAsync.value ?? 3650.0;

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

    final unitPrice = getUnitGoldPrice();
    final quantity = double.tryParse(_goldQuantityController.text) ?? 0.0;
    final totalValue = quantity * unitPrice;

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
          Text(isTr ? 'ALTIN TÜRÜ' : 'GOLD TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: goldTypes.map((type) {
              final isSelected = _goldType == type;
              return ChoiceChip(
                label: Text(type, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (appState.isDark ? Colors.white70 : Colors.black87))),
                selected: isSelected,
                selectedColor: const Color(0xFFF3A712),
                backgroundColor: appState.isDark ? Colors.grey.shade900 : Colors.grey.shade100,
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
            Text(isTr ? 'AYAR (SAFLIK DERECESİ)' : 'PURITY (CARAT)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Row(
              children: ['24', '22', '18', '14'].map((k) {
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
                      child: Text('$k K', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFF3A712) : (appState.isDark ? Colors.white70 : Colors.black54))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _goldQuantityController,
            decoration: InputDecoration(
              labelText: _goldType == 'Gram' ? (isTr ? 'Miktar (Gram)' : 'Quantity (Grams)') : (isTr ? 'Adet' : 'Quantity'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: _goldType == 'Gram' ? 'gr' : (isTr ? 'adet' : 'pcs'),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir miktar girin' : 'Please enter a quantity') : null,
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
                    Text('₺${unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isTr ? 'Toplam Değer:' : 'Total Value:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₺${totalValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF3A712))),
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
                      id: const Uuid().v4(),
                      name: _goldType == 'Gram' 
                          ? '${_purity}K $_goldType ${isTr ? "Altın" : "Gold"}'
                          : '$_goldType ${isTr ? "Altın" : "Gold"}',
                      category: AssetCategory.gold,
                      value: totalValue,
                      details: {
                        'goldType': _goldType,
                        'purity': _purity,
                        'quantity': _goldQuantityController.text,
                        'unitPrice': unitPrice.toString(),
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
