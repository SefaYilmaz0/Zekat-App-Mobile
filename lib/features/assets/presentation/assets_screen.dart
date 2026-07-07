import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../calculator/presentation/calculator_provider.dart';
import '../domain/asset_model.dart';
import 'widgets/add_asset_dialog.dart';

class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  IconData _getIconForCategory(AssetCategory category) {
    switch (category) {
      case AssetCategory.gold: return Icons.grid_goldenratio_rounded;
      case AssetCategory.cash: return Icons.payments_rounded;
      case AssetCategory.agriculture: return Icons.agriculture_rounded;
      case AssetCategory.livestock: return Icons.pets_rounded;
      case AssetCategory.receivable: return Icons.account_balance_rounded;
      case AssetCategory.debt: return Icons.money_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;
    final assetsAsync = ref.watch(assetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Varlıklarım' : 'My Assets', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddAssetDialog(),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(isTr ? 'Yeni Ekle' : 'Add New'),
      ),
      body: assetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (assets) {
          if (assets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    isTr ? 'Henüz varlık eklenmedi.' : 'No assets added yet.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final myAssets = assets.where((a) => a.category != AssetCategory.debt).toList();
          final myDebts = assets.where((a) => a.category == AssetCategory.debt).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (myAssets.isNotEmpty) ...[
                Text(isTr ? 'Varlıklarım' : 'My Assets', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myAssets.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final asset = myAssets[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          foregroundColor: Theme.of(context).primaryColor,
                          child: Icon(_getIconForCategory(asset.category)),
                        ),
                        title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(asset.category.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₺${asset.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () {
                                final box = Hive.box<AssetModel>('assets');
                                box.delete(asset.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              if (myDebts.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.money_off_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(isTr ? 'Borçlarım' : 'My Debts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: Colors.red.shade50.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.shade100)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myDebts.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.red.shade100),
                    itemBuilder: (context, index) {
                      final asset = myDebts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          foregroundColor: Colors.red,
                          child: Icon(_getIconForCategory(asset.category)),
                        ),
                        title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(asset.category.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('-₺${asset.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () {
                                final box = Hive.box<AssetModel>('assets');
                                box.delete(asset.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ]
            ],
          );
        },
      ),
    );
  }
}
