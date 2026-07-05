import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../calculator/presentation/calculator_provider.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final calcAsync = ref.watch(calculatorProvider);
    final isTr = appState.language == Language.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Özet' : 'Summary', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            color: Theme.of(context).primaryColor,
            onScaleUpdate: (details) {}, // Dummy
            onPressed: () {
              // Share logic
            },
          )
        ],
      ),
      body: calcAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
        data: (calc) {
          final progressPercent = calc.nisabThreshold > 0 
            ? (calc.netZakatableAmount / calc.nisabThreshold).clamp(0.0, 1.0) 
            : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: calc.isNisabReached 
                        ? [Theme.of(context).primaryColor, Colors.orange.shade400]
                        : [Colors.grey.shade600, Colors.grey.shade800],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (calc.isNisabReached ? Theme.of(context).primaryColor : Colors.grey).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        isTr ? 'TOPLAM ZEKAT' : 'TOTAL ZAKAT',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₺${calc.isNisabReached ? calc.zakatToPay.toStringAsFixed(2) : '0.00'}',
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(calc.isNisabReached ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              calc.isNisabReached ? (isTr ? 'NİSAB AŞILDI' : 'NISAB MET') : (isTr ? 'NİSABA ULAŞILMADI' : 'NISAB NOT MET'),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Nisab Progress Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isTr ? 'Net Varlık' : 'Net Worth', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text('₺${calc.netZakatableAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(calc.isNisabReached ? Colors.green : Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(isTr ? 'Nisab Sınırı' : 'Nisab Limit', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              Text('₺${calc.nisabThreshold.toStringAsFixed(0)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Breakdown section title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isTr ? 'Varlıklarım' : 'My Assets', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => context.go('/assets'),
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        foregroundColor: Theme.of(context).primaryColorDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isTr ? 'Yeni Ekle' : 'Add New', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Dummy Assets view (We will wire up the actual list next)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.post_add_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(isTr ? 'Varlıklarınız Varlıklar sekmesinde eklenebilir.' : 'Your assets can be added from the Assets tab.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
