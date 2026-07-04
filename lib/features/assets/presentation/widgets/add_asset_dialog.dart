import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/asset_model.dart';
import '../asset_provider.dart';

class AddAssetDialog extends ConsumerStatefulWidget {
  const AddAssetDialog({super.key});

  @override
  ConsumerState<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends ConsumerState<AddAssetDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  AssetType _selectedType = AssetType.cash;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Varlık Ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Varlık Adı (örn: Banka)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Miktar (TL, Gram vb.)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<AssetType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Tür'),
              items: AssetType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text;
            final amount = double.tryParse(_amountController.text) ?? 0.0;
            if (name.isNotEmpty && amount > 0) {
              final newAsset = AssetModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                type: _selectedType,
                amount: amount,
              );
              ref.read(assetsProvider.notifier).addAsset(newAsset);
              Navigator.pop(context);
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
