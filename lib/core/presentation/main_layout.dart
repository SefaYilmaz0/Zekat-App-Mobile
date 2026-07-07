import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../domain/enums.dart';

import '../../features/assets/presentation/widgets/add_asset_dialog.dart';
import '../../features/summary/presentation/summary_screen.dart';
import '../../features/guide/presentation/guide_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;

    Widget buildNavItem(int index, IconData icon, String label) {
      final isSelected = _currentIndex == index;
      final color = isSelected ? const Color(0xFFF3A712) : Colors.grey.shade400;
      return InkWell(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          SummaryScreen(),
          GuideScreen(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFF3A712),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: const CircleBorder(),
          onPressed: () {
            showDialog(context: context, builder: (context) => const AddAssetDialog());
          },
          child: const Icon(Icons.add_rounded, size: 36),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 16,
        shadowColor: Colors.black45,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNavItem(0, Icons.calculate_rounded, isTr ? 'Özet' : 'Summary'),
            buildNavItem(1, Icons.menu_book_rounded, isTr ? 'Rehber' : 'Guide'),
            const SizedBox(width: 48), // Space for FAB
            buildNavItem(2, Icons.history_rounded, isTr ? 'Geçmiş' : 'History'),
            buildNavItem(3, Icons.settings_rounded, isTr ? 'Ayarlar' : 'Settings'),
          ],
        ),
      ),
    );
  }
}
