import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../domain/history_model.dart';
import '../../calculator/presentation/calculator_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/hijri_date_helper.dart';
import '../../../core/theme.dart';
import 'package:intl/intl.dart';
import '../../exchange_rates/presentation/exchange_rate_provider.dart';
import 'history_detail_screen.dart';
import 'widgets/zakat_payment_dialog.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;
    final calcAsync = ref.watch(calculatorProvider);
    final currentZakat = calcAsync.value?.zakatToPay ?? 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(isTr ? 'Geçmiş' : 'History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Theme.of(context).textTheme.displayLarge?.color)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              isTr ? 'Zekat hesaplama ve ödeme geçmişiniz' : 'Your zakat calculation and payment history',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Mevcut Dönem Card
          Text(isTr ? 'MEVCUT DÖNEM' : 'CURRENT PERIOD', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appState.isDark ? Colors.white10 : Colors.transparent),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isTr ? 'Dönem Zekatı' : 'Period Zakat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        Text('${DateFormat('MMMM yyyy', isTr ? 'tr_TR' : 'en_US').format(DateTime.now())} / ${HijriDateHelper.formatHijriMonthYear(DateTime.now(), appState.language)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(isTr ? 'Beklemede' : 'Pending', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Text('${isTr ? "Hesaplanan Tutar:" : "Calculated Amount:"} ${appState.currency.symbol}${formatCurrency(currentZakat, appState.language)}', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (currentZakat <= 0.0 || calcAsync.value == null)
                        ? null
                        : () async {
                            final rates = ref.read(exchangeRatesProvider).value ?? [];
                            final success = await ZakatPaymentDialog.show(
                              context: context,
                              zakatAmount: currentZakat,
                              calculationResult: calcAsync.value!,
                              appState: appState,
                              exchangeRates: rates,
                            );

                            if (success == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isTr ? 'Zekat ödemesi başarıyla kaydedildi!' : 'Zakat payment saved successfully!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: appState.isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(isTr ? 'Ödeme Yap' : 'Make Payment', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )

              ],
            ),
          ),
          const SizedBox(height: 32),

          // Arşiv Section
          Text(isTr ? 'ARŞİV' : 'ARCHIVE', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),

          ValueListenableBuilder<Box<HistoryModel>>(
            valueListenable: Hive.box<HistoryModel>('history').listenable(),
            builder: (context, box, _) {
              if (box.values.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      isTr ? 'Henüz geçmiş ödeme kaydı bulunmuyor.' : 'No history records found.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                );
              }

              final items = box.values.toList().reversed.toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryDetailScreen(historyItem: item),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: appState.isDark ? Colors.white10 : Colors.transparent),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3A712).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFFF3A712), size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.period, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                            Text(
                                              item.hijriDate != null 
                                                  ? '${item.gregorian} / ${item.hijriDate}' 
                                                  : item.gregorian, 
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    Text('${_getCurrencySymbol(item.currency)}${formatCurrency(item.amount, appState.language)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).primaryColor)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item.assetCount} ${isTr ? "Varlık Kalemi" : "Asset Items"}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(item.date)), style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

