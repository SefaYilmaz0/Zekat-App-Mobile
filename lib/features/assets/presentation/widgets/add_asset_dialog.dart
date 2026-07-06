import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../domain/asset_model.dart';
import '../../../calculator/presentation/calculator_provider.dart';

class AddAssetDialog extends ConsumerStatefulWidget {
  const AddAssetDialog({super.key});

  @override
  ConsumerState<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends ConsumerState<AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  
  bool _isCategorySelected = false;
  AssetCategory _selectedCategory = AssetCategory.cash;

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _saveAsset() {
    if (_formKey.currentState!.validate()) {
      final value = double.tryParse(_valueController.text) ?? 0.0;
      
      final asset = AssetModel(
        id: const Uuid().v4(),
        name: _nameController.text,
        category: _selectedCategory,
        value: value,
      );

      final box = Hive.box<AssetModel>('assets');
      box.put(asset.id, asset);

      Navigator.of(context).pop();
    }
  }

  Widget _buildCategoryGrid(bool isTr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text(isTr ? 'Vazgeç' : 'Cancel', style: TextStyle(color: Colors.grey.shade600))
            ),
            Text(isTr ? 'Varlık Ekle' : 'Add Asset', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 64), // Balance the row
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: AssetCategory.values.map((cat) {
            Color bgColor, iconColor;
            IconData icon;
            String name;
            if (cat == AssetCategory.gold) { bgColor = const Color(0xFFFEF3C7); iconColor = const Color(0xFFF3A712); icon = Icons.grid_goldenratio_rounded; name = isTr ? 'Altın' : 'Gold'; }
            else if (cat == AssetCategory.cash) { bgColor = const Color(0xFFD1FAE5); iconColor = const Color(0xFF10B981); icon = Icons.payments_rounded; name = isTr ? 'Nakit' : 'Cash'; }
            else if (cat == AssetCategory.debt) { bgColor = const Color(0xFFFEE2E2); iconColor = const Color(0xFFEF4444); icon = Icons.money_off_rounded; name = isTr ? 'Borç / Gider' : 'Debt'; }
            else if (cat == AssetCategory.receivable) { bgColor = const Color(0xFFDBEAFE); iconColor = const Color(0xFF3B82F6); icon = Icons.account_balance_rounded; name = isTr ? 'Alacaklar' : 'Receivables'; }
            else if (cat == AssetCategory.livestock) { bgColor = const Color(0xFFFFEDD5); iconColor = const Color(0xFFF97316); icon = Icons.pets_rounded; name = isTr ? 'Hayvanlar' : 'Livestock'; }
            else { bgColor = const Color(0xFFDCFCE7); iconColor = const Color(0xFF22C55E); icon = Icons.agriculture_rounded; name = isTr ? 'Tarım Ürünleri' : 'Agriculture'; }

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _isCategorySelected = true;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                      child: Icon(icon, color: iconColor, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildForm(bool isTr) {
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
                onPressed: () => setState(() => _isCategorySelected = false),
              ),
              const SizedBox(width: 8),
              Text(isTr ? 'Varlık Detayları' : 'Asset Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: isTr ? 'Varlık Adı (Örn: Maaş Hesabı)' : 'Asset Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) => value == null || value.isEmpty ? (isTr ? 'Lütfen bir ad girin' : 'Please enter a name') : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: isTr ? 'Değer (TRY)' : 'Value (TRY)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) return isTr ? 'Lütfen bir değer girin' : 'Please enter a value';
              if (double.tryParse(value) == null) return isTr ? 'Geçerli bir sayı girin' : 'Please enter a valid number';
              return null;
            },
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
                onPressed: _saveAsset,
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

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isCategorySelected ? _buildForm(isTr) : _buildCategoryGrid(isTr),
      ),
    );
  }
}
