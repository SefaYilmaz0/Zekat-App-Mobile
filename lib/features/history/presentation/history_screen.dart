import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../domain/history_model.dart';
import '../../calculator/presentation/calculator_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;
    final calcAsync = ref.watch(calculatorProvider);
    final currentZakat = calcAsync.value?.zakatToPay ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: Text(isTr ? 'Geçmiş' : 'History', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
                        const Text('Ramazan 1445', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                        Text('Temmuz 2026', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
                Text('${isTr ? "Hesaplanan Tutar:" : "Calculated Amount:"} ₺${currentZakat.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {}, // Active visually
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3A712),
                      foregroundColor: Colors.white,
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3A712).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFFF3A712), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.period, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                    Text(item.gregorian, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            Text('₺${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFF3A712))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.assetCount} ${isTr ? "Varlık Kalemi" : "Asset Items"}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            Text(item.date.split('T').first, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        )
                      ],
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
