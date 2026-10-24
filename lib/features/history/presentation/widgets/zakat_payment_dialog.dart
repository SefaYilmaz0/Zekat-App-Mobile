import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/currency_constants.dart';
import '../../../../core/domain/app_state.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/hijri_date_helper.dart';
import '../../../assets/domain/asset_model.dart';
import '../../../calculator/domain/calculation_result.dart';
import '../../../calculator/presentation/calculator_provider.dart';
import '../../../exchange_rates/domain/exchange_rate_model.dart';
import '../../domain/history_model.dart';

enum ZakatPaymentMethod {
  cashDeduction,
  addedDebt,
  recordOnly,
}

class ZakatPaymentDialog extends ConsumerStatefulWidget {
  final double zakatAmount;
  final CalculationResult calculationResult;
  final AppState appState;
  final List<ExchangeRateModel> exchangeRates;

  const ZakatPaymentDialog({
    super.key,
    required this.zakatAmount,
    required this.calculationResult,
    required this.appState,
    required this.exchangeRates,
  });

  static Future<bool?> show({
    required BuildContext context,
    required double zakatAmount,
    required CalculationResult calculationResult,
    required AppState appState,
    required List<ExchangeRateModel> exchangeRates,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ZakatPaymentDialog(
        zakatAmount: zakatAmount,
        calculationResult: calculationResult,
        appState: appState,
        exchangeRates: exchangeRates,
      ),
    );
  }

  @override
  ConsumerState<ZakatPaymentDialog> createState() => _ZakatPaymentDialogState();
}

class _ZakatPaymentDialogState extends ConsumerState<ZakatPaymentDialog> {
  late ZakatPaymentMethod _selectedMethod;
  String? _selectedCashAssetId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final cashAssets = _getCashAssets();
    if (cashAssets.isNotEmpty) {
      _selectedMethod = ZakatPaymentMethod.cashDeduction;
      _selectedCashAssetId = cashAssets.first.id;
    } else {
      _selectedMethod = ZakatPaymentMethod.addedDebt;
    }
  }

  List<AssetModel> _getCashAssets() {
    final box = Hive.box<AssetModel>('assets');
    return box.values.where((a) => a.category == AssetCategory.cash).toList();
  }

  double _calculateAmountInAssetCurrency(AssetModel asset, double zakatInAppCurrency) {
    final assetCurrency = asset.details?['currency']?.toString().toUpperCase() ?? 'TRY';
    final appCurrencyStr = widget.appState.currency.name.toUpperCase().replaceAll('CURRENCY', '');

    if (assetCurrency == appCurrencyStr) {
      return zakatInAppCurrency;
    }

    // Convert zakat (app currency) -> TRY -> asset currency
    final toTryRate = CurrencyConstants.getCurrencyToTryRate(appCurrencyStr, widget.exchangeRates);
    final zakatInTry = zakatInAppCurrency * toTryRate;
    final assetToTryRate = CurrencyConstants.getCurrencyToTryRate(assetCurrency, widget.exchangeRates);
    return zakatInTry / (assetToTryRate > 0 ? assetToTryRate : 1.0);
  }

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

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final isTr = widget.appState.language == Language.tr;
      final assetsBox = Hive.box<AssetModel>('assets');
      final allCurrentAssets = assetsBox.values.toList();
      final calc = widget.calculationResult;

      // 1. Snapshot all assets and debts before modifying current portfolio
      final snapshotAssets = allCurrentAssets
          .where((a) => a.category != AssetCategory.debt)
          .map((a) {
            final clone = a.clone();
            final dynamicTry = CurrencyConstants.calculateDynamicAssetValueTRY(
              asset: a,
              goldRate: calc.goldRate * calc.conversionRate,
              silverRate: calc.silverRate * calc.conversionRate,
              exchangeRates: widget.exchangeRates,
            );
            clone.details = {
              ...(clone.details ?? {}),
              'snapshotValueTRY': dynamicTry,
              'snapshotValueCurrency': dynamicTry / calc.conversionRate,
            };
            return clone;
          })
          .toList();

      final snapshotLiabilities = allCurrentAssets
          .where((a) => a.category == AssetCategory.debt)
          .map((a) {
            final clone = a.clone();
            final dynamicTry = CurrencyConstants.calculateDynamicAssetValueTRY(
              asset: a,
              goldRate: calc.goldRate * calc.conversionRate,
              silverRate: calc.silverRate * calc.conversionRate,
              exchangeRates: widget.exchangeRates,
            );
            clone.details = {
              ...(clone.details ?? {}),
              'snapshotValueTRY': dynamicTry,
              'snapshotValueCurrency': dynamicTry / calc.conversionRate,
            };
            return clone;
          })
          .toList();

      // 2. Perform portfolio update based on selected method
      String paymentMethodTag;
      if (_selectedMethod == ZakatPaymentMethod.cashDeduction && _selectedCashAssetId != null) {
        paymentMethodTag = 'cash_deduction';
        final targetAsset = assetsBox.get(_selectedCashAssetId);
        if (targetAsset != null) {
          final deductAmount = _calculateAmountInAssetCurrency(targetAsset, widget.zakatAmount);
          final currentVal = double.tryParse(targetAsset.details?['originalAmount']?.toString() ?? '') ?? targetAsset.value;
          final updatedVal = (currentVal - deductAmount).clamp(0.0, double.infinity);

          targetAsset.value = updatedVal;
          final updatedDetails = Map<dynamic, dynamic>.from(targetAsset.details ?? {});
          updatedDetails['originalAmount'] = updatedVal;
          targetAsset.details = updatedDetails;
          await targetAsset.save();
        }
      } else if (_selectedMethod == ZakatPaymentMethod.addedDebt) {
        paymentMethodTag = 'added_debt';
        final now = DateTime.now();
        final periodStr = DateFormat('MM/yyyy').format(now);
        final debtName = isTr ? 'Zekat Ödemesi ($periodStr)' : 'Zakat Payment ($periodStr)';
        final appCurrencyCode = widget.appState.currency.name.toUpperCase().replaceAll('CURRENCY', '');

        // Convert zakat amount to TRY for debt storage value
        final toTryRate = CurrencyConstants.getCurrencyToTryRate(appCurrencyCode, widget.exchangeRates);
        final debtValTRY = widget.zakatAmount * toTryRate;

        final zakatDebt = AssetModel(
          id: const Uuid().v4(),
          name: debtName,
          category: AssetCategory.debt,
          value: debtValTRY,
          description: isTr ? 'Ödenen zekat yükümlülüğü' : 'Zakat payment liability',
          details: {
            'currency': appCurrencyCode,
            'originalAmount': widget.zakatAmount,
            'isShortTerm': true,
            'isZakatPayment': true,
          },
        );
        await assetsBox.put(zakatDebt.id, zakatDebt);
      } else {
        paymentMethodTag = 'record_only';
      }

      // 3. Save HistoryModel to Hive
      final today = DateTime.now();
      final periodName = isTr ? 'Zekat Ödemesi' : 'Zakat Payment';
      final gregorian = DateFormat('MMMM yyyy', isTr ? 'tr_TR' : 'en_US').format(today);

      final historyItem = HistoryModel(
        id: today.millisecondsSinceEpoch,
        period: periodName,
        gregorian: gregorian,
        amount: widget.zakatAmount,
        currency: widget.appState.currency.name.toUpperCase().replaceAll('CURRENCY', ''),
        status: 'paid',
        assetCount: snapshotAssets.length,
        date: today.toIso8601String(),
        assets: snapshotAssets,
        liabilities: snapshotLiabilities,
        hijriDate: HijriDateHelper.formatHijriMonthYear(today, widget.appState.language),
        totalAssets: calc.totalAssets,
        totalDebts: calc.totalDebts,
        netZakatableAmount: calc.netZakatableAmount,
        nisabThreshold: calc.nisabThreshold,
        paymentMethod: paymentMethodTag,
      );

      final historyBox = Hive.box<HistoryModel>('history');
      await historyBox.add(historyItem);

      // Invalidate providers
      ref.invalidate(calculatorProvider);
      ref.invalidate(assetsProvider);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.appState.language == Language.tr;
    final isDark = widget.appState.isDark;
    final cashAssets = _getCashAssets();
    final sym = widget.appState.currency.symbol;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3A712).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payments_rounded, color: Color(0xFFF3A712), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTr ? 'Zekat Ödemesini Onayla' : 'Confirm Zakat Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).textTheme.displayLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTr ? 'Ödeme tutarının düşüm yöntemini seçin' : 'Select how this payment is deducted',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Hero Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E3643),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTr ? 'Ödenecek Zekat Tutarı' : 'Zakat Amount to Pay',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM yyyy', isTr ? 'tr_TR' : 'en_US').format(DateTime.now()),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                      ),
                    ],
                  ),
                  Text(
                    '$sym${formatCurrency(widget.zakatAmount, widget.appState.language)}',
                    style: const TextStyle(
                      color: Color(0xFFF3A712),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isTr ? 'DÜŞÜM YÖNTEMİ' : 'DEDUCTION METHOD',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),

            // Option 1: Cash Deduction
            _buildOptionTile(
              context: context,
              title: isTr ? 'Nakit Varlıktan Düş' : 'Deduct from Cash Asset',
              subtitle: isTr
                  ? 'Mevcut nakit veya banka hesabınızdan zekat tutarı eksiltilir.'
                  : 'Deducts the zakat amount from your selected cash or bank account.',
              icon: Icons.account_balance_wallet_rounded,
              value: ZakatPaymentMethod.cashDeduction,
              enabled: cashAssets.isNotEmpty,
              extraWidget: (_selectedMethod == ZakatPaymentMethod.cashDeduction && cashAssets.isNotEmpty)
                  ? _buildCashAssetSelector(cashAssets, isTr, isDark)
                  : (cashAssets.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            isTr ? 'Kayıtlı nakit varlığınız bulunmamaktadır.' : 'No cash assets available.',
                            style: TextStyle(color: Colors.orange.shade400, fontSize: 11),
                          ),
                        )
                      : null),
            ),
            const SizedBox(height: 10),

            // Option 2: Add as Debt
            _buildOptionTile(
              context: context,
              title: isTr ? 'Borç Olarak Ekle' : 'Add as Liability / Debt',
              subtitle: isTr
                  ? 'Borçlar hanesine zekat borcu olarak eklenir ve net matrahtan düşülür.'
                  : 'Adds to your debts list and automatically reduces net zakatable wealth.',
              icon: Icons.money_off_rounded,
              value: ZakatPaymentMethod.addedDebt,
              enabled: true,
            ),
            const SizedBox(height: 10),

            // Option 3: Record Only
            _buildOptionTile(
              context: context,
              title: isTr ? 'Sadece Geçmişe Kaydet' : 'Record to History Only',
              subtitle: isTr
                  ? 'Mevcut varlık ve borçlarınız değiştirilmez, yalnızca geçmiş kaydı tutulur.'
                  : 'Leaves existing assets and debts unchanged, only saves a history record.',
              icon: Icons.history_edu_rounded,
              value: ZakatPaymentMethod.recordOnly,
              enabled: true,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isTr ? 'İptal' : 'Cancel',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3A712),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                          )
                        : Text(
                            isTr ? 'Ödemeyi Tamamla' : 'Complete Payment',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashAssetSelector(List<AssetModel> cashAssets, bool isTr, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCashAssetId,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded),
          dropdownColor: Theme.of(context).colorScheme.surface,
          items: cashAssets.map((asset) {
            final assetCurrency = asset.details?['currency']?.toString().toUpperCase() ?? 'TRY';
            final deductAmount = _calculateAmountInAssetCurrency(asset, widget.zakatAmount);
            final currentVal = double.tryParse(asset.details?['originalAmount']?.toString() ?? '') ?? asset.value;
            final remainingVal = (currentVal - deductAmount).clamp(0.0, double.infinity);
            final currSym = _getCurrencySymbol(assetCurrency);

            return DropdownMenuItem<String>(
              value: asset.id,
              child: Text(
                '${asset.name} ($currSym${formatCurrency(currentVal, widget.appState.language)} → $currSym${formatCurrency(remainingVal, widget.appState.language)})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCashAssetId = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ZakatPaymentMethod value,
    required bool enabled,
    Widget? extraWidget,
  }) {
    final isSelected = _selectedMethod == value;
    final isDark = widget.appState.isDark;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? () => setState(() => _selectedMethod = value) : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF3A712).withValues(alpha: isDark ? 0.12 : 0.08)
                : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF3A712)
                  : (isDark ? Colors.white10 : Colors.grey.shade200),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? const Color(0xFFF3A712) : Colors.grey.shade500,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF3A712) : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF3A712),
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              if (extraWidget != null) extraWidget,
            ],
          ),
        ),
      ),
    );
  }
}
