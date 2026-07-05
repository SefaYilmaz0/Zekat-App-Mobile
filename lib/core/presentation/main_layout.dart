import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_state_provider.dart';
import '../domain/enums.dart';

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

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/summary');
              break;
            case 1:
              context.go('/assets');
              break;
            case 2:
              context.go('/guide');
              break;
            case 3:
              context.go('/history');
              break;
            case 4:
              context.go('/settings');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_rounded),
            label: isTr ? 'Özet' : 'Summary',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: isTr ? 'Varlıklar' : 'Assets',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_rounded),
            label: isTr ? 'Rehber' : 'Guide',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            label: isTr ? 'Geçmiş' : 'History',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            label: isTr ? 'Ayarlar' : 'Settings',
          ),
        ],
      ),
    );
  }
}
