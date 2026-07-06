import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_state_provider.dart';
import '../domain/enums.dart';

import '../../assets/presentation/widgets/add_asset_dialog.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;

    int getCurrentIndex(String location) {
      if (location.startsWith('/summary')) return 0;
      if (location.startsWith('/assets')) return 1;
      if (location.startsWith('/guide')) return 2;
      if (location.startsWith('/history')) return 3;
      if (location.startsWith('/settings')) return 4;
      return 0;
    }

    final String location = GoRouterState.of(context).uri.toString();
    final currentIndex = getCurrentIndex(location);

    Widget buildNavItem(int index, IconData icon, String label) {
      final isSelected = currentIndex == index;
      final color = isSelected ? const Color(0xFFF3A712) : Colors.grey.shade400;
      return InkWell(
        onTap: () {
          switch (index) {
            case 0: context.go('/summary'); break;
            case 1: context.go('/guide'); break; // Rehber (Guide)
            case 2: context.go('/history'); break;
            case 3: context.go('/settings'); break;
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF3A712),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () {
          showDialog(context: context, builder: (context) => const AddAssetDialog());
        },
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
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
