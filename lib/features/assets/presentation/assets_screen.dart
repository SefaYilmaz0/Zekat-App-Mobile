import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'asset_provider.dart';
import 'widgets/add_asset_dialog.dart';

class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsList = ref.watch(assetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Varlıklarım'),
        centerTitle: true,
      ),
      body: assetsList.isEmpty
          ? const Center(child: Text('Henüz hiç varlık eklemediniz.'))
          : ListView.builder(
              itemCount: assetsList.length,
              itemBuilder: (context, index) {
                final asset = assetsList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(asset.type.name[0].toUpperCase()),
                    ),
                    title: Text(asset.name),
                    subtitle: Text('Tür: ${asset.type.name.toUpperCase()}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          asset.amount.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            ref.read(assetsProvider.notifier).deleteAsset(asset.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddAssetDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
