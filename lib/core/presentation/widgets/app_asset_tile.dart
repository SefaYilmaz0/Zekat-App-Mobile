import 'package:flutter/material.dart';
import '../../domain/enums.dart';
import '../../theme.dart';
import '../../../features/assets/domain/asset_model.dart';
import '../../utils/currency_formatter.dart';

class AppAssetTile extends StatelessWidget {
  final AssetModel asset;
  final double dynamicValue;
  final bool isDebt;
  final Language language;
  final String currencySymbol;
  final Sect sect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AppAssetTile({
    super.key,
    required this.asset,
    required this.dynamicValue,
    required this.isDebt,
    required this.language,
    required this.currencySymbol,
    required this.sect,
    required this.onEdit,
    required this.onDelete,
  });

  static IconData getCategoryIcon(AssetCategory category) {
    switch (category) {
      case AssetCategory.gold:
        return Icons.grid_goldenratio_rounded;
      case AssetCategory.silver:
        return Icons.circle_outlined;
      case AssetCategory.cash:
        return Icons.account_balance_wallet_rounded;
      case AssetCategory.receivable:
        return Icons.call_received_rounded;
      case AssetCategory.debt:
        return Icons.money_off_rounded;
      case AssetCategory.livestock:
        return Icons.pets_rounded;
      case AssetCategory.agriculture:
        return Icons.grass_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTr = language == Language.tr;
    final formattedAmount = '${isDebt ? "- " : ""}$currencySymbol${formatCurrency(dynamicValue, language)}';
    final primaryAccent = isDebt ? AppColors.debtRed : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Kategori İkonu
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getCategoryIcon(asset.category),
                  color: primaryAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // 2. Varlık Adı ve Detay Etiketleri (Geniş Alan - ASLA Sıkışmaz)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      asset.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          asset.category.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (asset.category == AssetCategory.gold &&
                            asset.details?['isJewelry'] == true &&
                            sect != Sect.hanefi)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isTr ? 'MUAF' : 'EXEMPT',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white60 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        if (isDebt && asset.details?['isShortTerm'] == false)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isTr ? 'UZUN VADELİ' : 'LONG-TERM',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 3. Tutar ve Kompakt İşlem Butonları (FittedBox ile Taşma Önleme)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.38,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        formattedAmount,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDebt
                              ? AppColors.debtRed
                              : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: isDark ? Colors.white54 : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.red.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
