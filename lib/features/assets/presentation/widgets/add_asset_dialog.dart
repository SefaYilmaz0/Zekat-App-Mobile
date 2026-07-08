import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../domain/asset_model.dart';
import 'gold_asset_form.dart';
import 'cash_asset_form.dart';
import 'livestock_asset_form.dart';
import 'agriculture_asset_form.dart';

class AddAssetDialog extends ConsumerStatefulWidget {
  const AddAssetDialog({super.key});

  @override
  ConsumerState<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends ConsumerState<AddAssetDialog> {
  bool _isCategorySelected = false;
  AssetCategory _selectedCategory = AssetCategory.cash;

  Widget _buildCategoryGrid(bool isTr, bool isDark) {
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
            const SizedBox(width: 64), 
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
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

  Widget _buildForm() {
    switch (_selectedCategory) {
      case AssetCategory.gold:
        return GoldAssetForm(onBack: () => setState(() => _isCategorySelected = false));
      case AssetCategory.cash:
      case AssetCategory.receivable:
      case AssetCategory.debt:
        return CashAssetForm(category: _selectedCategory, onBack: () => setState(() => _isCategorySelected = false));
      case AssetCategory.livestock:
        return LivestockAssetForm(onBack: () => setState(() => _isCategorySelected = false));
      case AssetCategory.agriculture:
        return AgricultureAssetForm(onBack: () => setState(() => _isCategorySelected = false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isCategorySelected ? _buildForm() : _buildCategoryGrid(isTr, appState.isDark),
        ),
      ),
    );
  }
}
