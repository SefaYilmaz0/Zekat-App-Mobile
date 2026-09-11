import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/presentation/widgets/app_bottom_sheet.dart';
import '../../domain/asset_model.dart';
import 'gold_asset_form.dart';
import 'silver_asset_form.dart';
import 'cash_asset_form.dart';
import 'livestock_asset_form.dart';
import 'agriculture_asset_form.dart';

class AddAssetDialog extends ConsumerStatefulWidget {
  final AssetModel? existingAsset;
  const AddAssetDialog({super.key, this.existingAsset});

  static Future<void> show(BuildContext context, {AssetModel? existingAsset}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAssetDialog(existingAsset: existingAsset),
    );
  }

  @override
  ConsumerState<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends ConsumerState<AddAssetDialog> {
  late bool _isCategorySelected;
  late AssetCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _isCategorySelected = widget.existingAsset != null;
    _selectedCategory = widget.existingAsset?.category ?? AssetCategory.cash;
  }

  Widget _buildCategoryList(bool isTr, bool isDark) {
    final categories = [
      (
        cat: AssetCategory.gold,
        title: isTr ? 'Altın & Ziynet' : 'Gold & Jewelry',
        subtitle: isTr ? 'Gram, çeyrek, cumhuriyet ve ziynet takılar' : 'Gram, coins, jewelry & bullion',
        icon: Icons.grid_goldenratio_rounded,
        iconColor: const Color(0xFFF3A712),
        bgColor: const Color(0xFFFEF3C7),
      ),
      (
        cat: AssetCategory.cash,
        title: isTr ? 'Nakit & Banka' : 'Cash & Bank',
        subtitle: isTr ? 'TL, döviz ve vadesiz/vadeli mevduatlar' : 'TRY, foreign currency & bank accounts',
        icon: Icons.payments_rounded,
        iconColor: const Color(0xFF10B981),
        bgColor: const Color(0xFFD1FAE5),
      ),
      (
        cat: AssetCategory.silver,
        title: isTr ? 'Gümüş' : 'Silver',
        subtitle: isTr ? 'Külçe, gümüş para ve ziynetler' : 'Silver bullion, coins & items',
        icon: Icons.diamond_outlined,
        iconColor: const Color(0xFF64748B),
        bgColor: const Color(0xFFE2E8F0),
      ),
      (
        cat: AssetCategory.receivable,
        title: isTr ? 'Alacaklar' : 'Receivables',
        subtitle: isTr ? 'Tahsil edilecek kesin ticari veya şahsi alacaklar' : 'Trade and personal debts owed to you',
        icon: Icons.account_balance_rounded,
        iconColor: const Color(0xFF3B82F6),
        bgColor: const Color(0xFFDBEAFE),
      ),
      (
        cat: AssetCategory.debt,
        title: isTr ? 'Borçlar & Giderler' : 'Debts & Liabilities',
        subtitle: isTr ? 'Vadesi gelmiş borçlar ve düşülebilir harcamalar' : 'Due debts and deductible obligations',
        icon: Icons.money_off_rounded,
        iconColor: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFEE2E2),
      ),
      (
        cat: AssetCategory.livestock,
        title: isTr ? 'Hayvancılık' : 'Livestock',
        subtitle: isTr ? 'Koyun, keçi, sığır ve deve nisabı' : 'Sheep, goat, cattle & camel',
        icon: Icons.pets_rounded,
        iconColor: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFEDD5),
      ),
      (
        cat: AssetCategory.agriculture,
        title: isTr ? 'Tarım Ürünleri (Öşür)' : 'Agriculture (Ushr)',
        subtitle: isTr ? 'Toprak mahsulleri ve hasat zekatı' : 'Agricultural harvest and produce',
        icon: Icons.agriculture_rounded,
        iconColor: const Color(0xFF059669),
        bgColor: const Color(0xFFDCFCE7),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr ? 'Varlık veya Borç Ekle' : 'Add Asset or Debt',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isTr ? 'Hesaplamaya dahil edilecek türü seçin' : 'Select category to include in calculation',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
              tooltip: isTr ? 'Kapat' : 'Close',
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...categories.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = item.cat;
                    _isCategorySelected = true;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? item.iconColor.withValues(alpha: 0.2) : item.bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  void _handleBack() {
    if (widget.existingAsset != null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isCategorySelected = false);
    }
  }

  Widget _buildForm() {
    switch (_selectedCategory) {
      case AssetCategory.gold:
        return GoldAssetForm(
          existingAsset: widget.existingAsset,
          onBack: _handleBack,
        );
      case AssetCategory.cash:
      case AssetCategory.receivable:
      case AssetCategory.debt:
        return CashAssetForm(
          category: _selectedCategory,
          existingAsset: widget.existingAsset,
          onBack: _handleBack,
        );
      case AssetCategory.livestock:
        return LivestockAssetForm(
          existingAsset: widget.existingAsset,
          onBack: _handleBack,
        );
      case AssetCategory.silver:
        return SilverAssetForm(
          existingAsset: widget.existingAsset,
          onBack: _handleBack,
        );
      case AssetCategory.agriculture:
        return AgricultureAssetForm(
          existingAsset: widget.existingAsset,
          onBack: _handleBack,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;
    final isDark = appState.isDark;

    return AppBottomSheet(
      child: _isCategorySelected
          ? _buildForm()
          : _buildCategoryList(isTr, isDark),
    );
  }
}
