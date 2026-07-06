import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;

    final categories = isTr 
        ? ['Tümü', 'Temel Bilgiler', 'Hesaplama'] 
        : ['All', 'Basics', 'Calculation'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: Text(isTr ? 'Rehber' : 'Guide', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: isTr ? 'Ara...' : 'Search...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF3A712) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Guide Cards List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: [
                _buildGuideCard(
                  context,
                  icon: Icons.scale_rounded,
                  title: isTr ? 'Zekat Nedir?' : 'What is Zakat?',
                  description: isTr 
                    ? 'Zekat, İslam\'ın beş şartından biri olan ve nisap miktarı mala sahip olan Müslümanların, mallarının belirli bir kısmını ihtiyaç sahiplerine vermesidir.'
                    : 'Zakat is one of the Five Pillars of Islam, a religious obligation to donate a certain portion of wealth to charitable causes.',
                  isTr: isTr,
                ),
                const SizedBox(height: 16),
                _buildGuideCard(
                  context,
                  icon: Icons.account_balance_wallet_rounded,
                  title: isTr ? 'Nisab Miktarı Nedir?' : 'What is Nisab?',
                  description: isTr
                    ? 'Nisab, zekat vermekle yükümlü olmak için dinen belirlenmiş asgari zenginlik ölçüsüdür. Altın için bu miktar 80.18 gramdır.'
                    : 'Nisab is the minimum amount of wealth a Muslim must possess before they become eligible to pay Zakat. For gold, it is 80.18 grams.',
                  isTr: isTr,
                ),
                const SizedBox(height: 16),
                _buildGuideCard(
                  context,
                  icon: Icons.calculate_rounded,
                  title: isTr ? 'Nasıl Hesaplanır?' : 'How is it calculated?',
                  description: isTr
                    ? 'Zekat, mevcut varlıklarınızdan borçlarınız düşüldükten sonra kalan net varlığın %2.5\'i (1/40) üzerinden hesaplanır.'
                    : 'Zakat calculation is based on 2.5% (1/40) of your net wealth after deducting your debts from your assets.',
                  isTr: isTr,
                ),
                const SizedBox(height: 16),
                _buildGuideCard(
                  context,
                  icon: Icons.date_range_rounded,
                  title: isTr ? '1 Yıl Şartı' : 'One Lunar Year Rule',
                  description: isTr
                    ? 'Nisab miktarı mala sahip olduktan sonra üzerinden tam bir kameri yıl (354 gün) geçmesi gerekir.'
                    : 'Once your wealth reaches the Nisab threshold, you must possess it for one full lunar year before Zakat becomes due.',
                  isTr: isTr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, {required IconData icon, required String title, required String description, required bool isTr}) {
    return Container(
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
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3A712).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFFF3A712), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black))),
            ],
          ),
          const SizedBox(height: 16),
          Text(description, style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(isTr ? 'Okumaya başla' : 'Start reading', style: const TextStyle(color: Color(0xFFF3A712), fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFFF3A712), size: 16),
            ],
          )
        ],
      ),
    );
  }
}
