import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../assets/domain/asset_model.dart';
import '../domain/history_model.dart';

class HistoryDetailScreen extends ConsumerWidget {
  final HistoryModel historyItem;

  const HistoryDetailScreen({
    super.key,
    required this.historyItem,
  });

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'TRY':
      default:
        return '₺';
    }
  }

  IconData _getCategoryIcon(AssetCategory category) {
    switch (category) {
      case AssetCategory.gold:
        return Icons.circle_rounded;
      case AssetCategory.silver:
        return Icons.blur_circular_rounded;
      case AssetCategory.cash:
        return Icons.payments_rounded;
      case AssetCategory.receivable:
        return Icons.receipt_long_rounded;
      case AssetCategory.debt:
        return Icons.money_off_rounded;
      case AssetCategory.livestock:
        return Icons.pets_rounded;
      case AssetCategory.agriculture:
        return Icons.grass_rounded;
    }
  }

  Color _getCategoryColor(AssetCategory category) {
    switch (category) {
      case AssetCategory.gold:
        return const Color(0xFFF3A712);
      case AssetCategory.silver:
        return Colors.blueGrey;
      case AssetCategory.cash:
        return const Color(0xFF10B981);
      case AssetCategory.receivable:
        return Colors.blue;
      case AssetCategory.debt:
        return AppColors.debtRed;
      case AssetCategory.livestock:
        return Colors.brown;
      case AssetCategory.agriculture:
        return Colors.green;
    }
  }

  String _formatAssetSubtitle(AssetModel asset, bool isTr) {
    final details = asset.details;
    if (details == null) return asset.description ?? '';

    switch (asset.category) {
      case AssetCategory.gold:
        final goldType = details['goldType']?.toString() ?? 'Gram';
        final purity = details['purity']?.toString() ?? '24';
        final qty = details['quantity']?.toString() ?? '${asset.value}';
        return '$goldType • $purity ${isTr ? "Ayar" : "Carat"} • $qty ${isTr ? "gr" : "g"}';
      case AssetCategory.silver:
        final purity = details['purity']?.toString() ?? '925';
        final qty = details['quantity']?.toString() ?? '${asset.value}';
        return '$purity ${isTr ? "Ayar" : "Purity"} • $qty ${isTr ? "gr" : "g"}';
      case AssetCategory.cash:
      case AssetCategory.receivable:
      case AssetCategory.debt:
        final currency = details['currency']?.toString().toUpperCase() ?? 'TRY';
        final orig = details['originalAmount']?.toString() ?? '${asset.value}';
        return '$orig $currency';
      case AssetCategory.livestock:
        final type = details['livestockType']?.toString() ?? '';
        final qty = details['quantity']?.toString() ?? '';
        return '$type • $qty ${isTr ? "Adet" : "Count"}';
      case AssetCategory.agriculture:
        final irrigation = details['irrigationType']?.toString() ?? 'natural';
        final irrLabel = irrigation == 'natural'
            ? (isTr ? 'Doğal Sulama (%10)' : 'Natural Irrigation (10%)')
            : (isTr ? 'Yapay Sulama (%5)' : 'Artificial Irrigation (5%)');
        return irrLabel;
    }
  }

  double _getAssetDisplayValue(AssetModel asset) {
    final snapVal = asset.details?['snapshotValueCurrency'];
    if (snapVal is num) return snapVal.toDouble();

    final snapTry = asset.details?['snapshotValueTRY'];
    if (snapTry is num) return snapTry.toDouble();

    return asset.value;
  }

  Widget _buildPaymentMethodBadge(BuildContext context, String? method, bool isTr) {
    String label;
    IconData icon;
    Color color;

    switch (method) {
      case 'cash_deduction':
        label = isTr ? 'Nakit Varlıktan Düşüldü' : 'Deducted from Cash';
        icon = Icons.account_balance_wallet_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'added_debt':
        label = isTr ? 'Borç Olarak Eklendi' : 'Added as Debt';
        icon = Icons.money_off_rounded;
        color = Colors.orange;
        break;
      case 'record_only':
        label = isTr ? 'Sadece Kaydedildi' : 'Recorded Only';
        icon = Icons.history_edu_rounded;
        color = Colors.blueGrey;
        break;
      default:
        label = isTr ? 'Ödeme Kaydı' : 'Payment Record';
        icon = Icons.check_circle_rounded;
        color = const Color(0xFFF3A712);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(BuildContext context, bool isTr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          isTr ? 'Kaydı Sil' : 'Delete Record',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          isTr
              ? 'Bu zekat geçmişi kaydını silmek istediğinize emin misiniz? (Mevcut portföyünüz etkilenmez.)'
              : 'Are you sure you want to delete this zakat history record? (Your current portfolio will not be affected.)',
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isTr ? 'Sil' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await historyItem.delete();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTr ? 'Geçmiş kaydı silindi.' : 'History record deleted.'),
            backgroundColor: Colors.grey.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;
    final isDark = appState.isDark;
    final sym = _getCurrencySymbol(historyItem.currency);

    // Group assets vs liabilities (backwards compatible: older records stored all in `assets`)
    final allSavedAssets = historyItem.assets;
    final allSavedLiabilities = historyItem.liabilities;

    final assetsList = [
      ...allSavedAssets.where((a) => a.category != AssetCategory.debt),
      ...allSavedLiabilities.where((a) => a.category != AssetCategory.debt),
    ];

    final debtsList = [
      ...allSavedAssets.where((a) => a.category == AssetCategory.debt),
      ...allSavedLiabilities.where((a) => a.category == AssetCategory.debt),
    ];

    // Computed totals if snapshot was saved before new fields existed
    double totalAssetsVal = historyItem.totalAssets ?? 0.0;
    double totalDebtsVal = historyItem.totalDebts ?? 0.0;

    if (totalAssetsVal <= 0.0 && assetsList.isNotEmpty) {
      totalAssetsVal = assetsList.fold(0.0, (sum, a) => sum + _getAssetDisplayValue(a));
    }
    if (totalDebtsVal <= 0.0 && debtsList.isNotEmpty) {
      totalDebtsVal = debtsList.fold(0.0, (sum, a) => sum + _getAssetDisplayValue(a));
    }

    final netMatrahVal = historyItem.netZakatableAmount ?? (totalAssetsVal - totalDebtsVal).clamp(0.0, double.infinity);

    DateTime recordDate;
    try {
      recordDate = DateTime.parse(historyItem.date);
    } catch (_) {
      recordDate = DateTime.now();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isTr ? 'Ödeme Detayı' : 'Payment Detail',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Theme.of(context).textTheme.displayLarge?.color,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: isTr ? 'Kaydı Sil' : 'Delete Record',
            onPressed: () => _deleteRecord(context, isTr),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Card (Slate Blue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF2E3643),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              isTr ? 'ÖDENDİ' : 'PAID',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('dd MMMM yyyy, HH:mm', isTr ? 'tr_TR' : 'en_US').format(recordDate),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Text(
                    isTr ? 'Ödenen Zekat Tutarı' : 'Zakat Amount Paid',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$sym${formatCurrency(historyItem.amount, appState.language)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    historyItem.hijriDate != null
                        ? '${historyItem.gregorian} / ${historyItem.hijriDate}'
                        : historyItem.gregorian,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPaymentMethodBadge(context, historyItem.paymentMethod, isTr),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Financial Overview Cards
            Text(
              isTr ? 'ÖDEME ANINDAKİ FİNANSAL DURUM' : 'FINANCIAL OVERVIEW AT PAYMENT',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    isTr ? 'Toplam Varlık' : 'Total Assets',
                    '$sym${formatCurrency(totalAssetsVal, appState.language, decimalDigits: 0)}',
                    context,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    isTr ? 'Toplam Borç' : 'Total Debts',
                    '- $sym${formatCurrency(totalDebtsVal, appState.language, decimalDigits: 0)}',
                    context,
                    color: AppColors.debtRed,
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    isTr ? 'Net Zekat Matrahı' : 'Net Zakatable Amount',
                    '$sym${formatCurrency(netMatrahVal, appState.language, decimalDigits: 0)}',
                    context,
                    isBold: true,
                    color: const Color(0xFFF3A712),
                  ),
                  if (historyItem.nisabThreshold != null && historyItem.nisabThreshold! > 0) ...[
                    const Divider(height: 16),
                    _buildSummaryRow(
                      isTr ? 'Dönem Nisab Eşiği' : 'Period Nisab Limit',
                      '$sym${formatCurrency(historyItem.nisabThreshold!, appState.language, decimalDigits: 0)}',
                      context,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Assets Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTr ? 'O GÜNKÜ VARLIKLAR' : 'ASSETS AT CALCULATION',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3A712).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${assetsList.length} ${isTr ? "Kalem" : "Items"}',
                    style: const TextStyle(
                      color: Color(0xFFF3A712),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (assetsList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    isTr ? 'Kayıtlı varlık bulunmuyor.' : 'No assets recorded.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assetsList.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    final asset = assetsList[index];
                    final catColor = _getCategoryColor(asset.category);
                    final catIcon = _getCategoryIcon(asset.category);
                    final subtitle = _formatAssetSubtitle(asset, isTr);
                    final displayVal = _getAssetDisplayValue(asset);

                    return Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(catIcon, color: catColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asset.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '$sym${formatCurrency(displayVal, appState.language, decimalDigits: 0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // 4. Debts Section (if any existed at snapshot)
            if (debtsList.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTr ? 'O GÜNKÜ BORÇLAR' : 'DEBTS AT CALCULATION',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.debtRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${debtsList.length} ${isTr ? "Borç" : "Debts"}',
                      style: const TextStyle(
                        color: AppColors.debtRed,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: debtsList.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.red.shade50,
                  ),
                  itemBuilder: (context, index) {
                    final debt = debtsList[index];
                    final subtitle = _formatAssetSubtitle(debt, isTr);
                    final displayVal = _getAssetDisplayValue(debt);

                    return Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.debtRed.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.money_off_rounded, color: AppColors.debtRed, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  debt.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '- $sym${formatCurrency(displayVal, appState.language, decimalDigits: 0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.debtRed,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 5. Information Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3A712).withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3A712).withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFF3A712), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isTr
                          ? 'Bu ekran, ${DateFormat('dd MMMM yyyy').format(recordDate)} tarihindeki ödeme anında kayıt altına alınan varlık ve borç anlık görüntüsünü (snapshot) göstermektedir.'
                          : 'This screen displays the historical snapshot of assets and liabilities saved on ${DateFormat('dd MMMM yyyy').format(recordDate)}.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    BuildContext context, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 15 : 13,
            color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}
