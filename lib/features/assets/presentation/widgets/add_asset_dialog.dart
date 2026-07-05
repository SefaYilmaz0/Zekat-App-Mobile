import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../assets/domain/asset_model.dart';
import '../../calculator/presentation/calculator_provider.dart';

class AddAssetDialog extends ConsumerStatefulWidget {
  const AddAssetDialog({super.key});

  @override
  ConsumerState<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends ConsumerState<AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;

    return AlertDialog(
      title: Text(isTr ? 'Varlık Ekle' : 'Add Asset'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<AssetCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: isTr ? 'Kategori' : 'Category',
                border: const OutlineInputBorder(),
              ),
              items: AssetCategory.values.map((cat) {
                String catName = cat.name.toUpperCase();
                return DropdownMenuItem(
                  value: cat,
                  child: Text(catName),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isTr ? 'Varlık Adı' : 'Asset Name',
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? (isTr ? 'Lütfen bir ad girin' : 'Please enter a name') : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: isTr ? 'Değer (TRY)' : 'Value (TRY)',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return isTr ? 'Lütfen bir değer girin' : 'Please enter a value';
                if (double.tryParse(value) == null) return isTr ? 'Geçerli bir sayı girin' : 'Please enter a valid number';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isTr ? 'İptal' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAsset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(isTr ? 'Kaydet' : 'Save'),
        ),
      ],
    );
  }
}
