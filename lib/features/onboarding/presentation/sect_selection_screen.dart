import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';

class SectSelectionScreen extends ConsumerWidget {
  const SectSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final isTr = appState.language == Language.tr;

    final sects = [
      {
        'id': Sect.hanefi,
        'title': 'Hanefi',
        'icon': Icons.mosque_rounded,
        'desc': isTr 
            ? 'Altın için nisab miktarı 80.18 gram olarak hesaplanır. Borçlar toplam varlıktan düşülür.'
            : 'Nisab for gold is calculated as 80.18 grams. Debts are deducted from total assets.',
      },
      {
        'id': Sect.safi,
        'title': 'Şafi',
        'icon': Icons.menu_book_rounded,
        'desc': isTr
            ? 'Altın için nisab miktarı 80.18 gram olarak hesaplanır. Borçlar zekat matrahından düşülmez.'
            : 'Nisab for gold is calculated as 80.18 grams. Debts are not deducted from the zakatable amount.',
      },
      {
        'id': Sect.maliki,
        'title': 'Maliki',
        'icon': Icons.history_edu_rounded,
        'desc': isTr
            ? 'Şafi mezhebi ile benzer hesaplama yöntemleri kullanılır.'
            : 'Similar calculation methods as the Shafi\'i sect are used.',
      },
      {
        'id': Sect.hanbeli,
        'title': 'Hanbeli',
        'icon': Icons.auto_stories_rounded,
        'desc': isTr
            ? 'Hanefi mezhebi ile benzer hesaplama yöntemleri kullanılır.'
            : 'Similar calculation methods as the Hanafi sect are used.',
      },
    ];

    final selectedSectData = sects.firstWhere((s) => s['id'] == appState.sect);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isTr ? 'ADIM 2 / 3' : 'STEP 2 OF 3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Progress Indicator
              Row(
                children: [
                  Container(width: 32, height: 6, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 4),
                  Container(width: 32, height: 6, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 4),
                  Container(width: 32, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isTr ? 'Mezhebinizi Seçin' : 'Select Your Sect',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isTr
                    ? 'Zekat hesaplamaları mezheplere göre farklılık gösterebilir. Lütfen tabi olduğunuz mezhebi seçin.'
                    : 'Zakat calculations may vary according to sects. Please select the sect you follow.',
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6), height: 1.5),
              ),
              const SizedBox(height: 24),

              // Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: sects.map((sectData) {
                    final isSelected = appState.sect == sectData['id'];
                    return GestureDetector(
                      onTap: () => notifier.setSect(sectData['id'] as Sect),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      sectData['icon'] as IconData,
                                      color: isSelected ? Colors.white : Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    sectData['title'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onBackground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.check_circle_rounded, color: Theme.of(context).primaryColor, size: 20),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Description Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedSectData['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedSectData['desc'] as String,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    notifier.completeOnboarding();
                    context.go('/summary');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isTr ? 'Devam Et' : 'Continue',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
