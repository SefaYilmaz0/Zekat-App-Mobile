import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';

class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Rehber' : 'Guide', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGuideCard(
            context,
            icon: Icons.info_outline_rounded,
            title: isTr ? 'Zekat Nedir?' : 'What is Zakat?',
            description: isTr 
              ? 'Zekat, İslam\'ın beş şartından biri olan ve nisap miktarı mala sahip olan Müslümanların, mallarının belirli bir kısmını (genellikle %2.5) ihtiyaç sahiplerine vermesidir.'
              : 'Zakat is one of the Five Pillars of Islam, a religious obligation for all Muslims who meet the necessary criteria of wealth (Nisab) to donate a certain portion of wealth (usually 2.5%) each year to charitable causes.',
          ),
          const SizedBox(height: 16),
          _buildGuideCard(
            context,
            icon: Icons.balance_rounded,
            title: isTr ? 'Nisab Miktarı Nedir?' : 'What is Nisab?',
            description: isTr
              ? 'Nisab, zekat vermekle yükümlü olmak için dinen belirlenmiş asgari zenginlik ölçüsüdür. Altın için bu miktar 80.18 gramdır.'
              : 'Nisab is the minimum amount of wealth a Muslim must possess before they become eligible to pay Zakat. For gold, it is 80.18 grams.',
          ),
          const SizedBox(height: 16),
          _buildGuideCard(
            context,
            icon: Icons.date_range_rounded,
            title: isTr ? 'Haveleran-ı Havl (1 Yıl Şartı)' : 'One Lunar Year Rule',
            description: isTr
              ? 'Nisab miktarı mala sahip olduktan sonra üzerinden tam bir kameri yıl (354 gün) geçmesi gerekir.'
              : 'Once your wealth reaches the Nisab threshold, you must possess it for one full lunar year (354 days) before Zakat becomes due.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, {required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
        ],
      ),
    );
  }
}
