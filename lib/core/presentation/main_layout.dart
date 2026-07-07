import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../domain/enums.dart';

import '../../features/assets/presentation/widgets/add_asset_dialog.dart';
import '../../features/summary/presentation/summary_screen.dart';
import '../../features/guide/presentation/guide_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../core/theme.dart';

import '../utils/version_check_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runVersionCheck();
    });
  }

  Future<void> _runVersionCheck() async {
    final service = VersionCheckService();
    final result = await service.checkVersion();
    if (result != null && result.shouldUpdate && mounted) {
      _showUpdateDialog(result);
    }
  }

  void _showUpdateDialog(VersionCheckResult result) {
    final isTr = ref.read(appStateProvider).language == Language.tr;
    showDialog(
      context: context,
      barrierDismissible: !result.isForce,
      builder: (context) {
        return PopScope(
          canPop: !result.isForce,
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.system_update_rounded, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(isTr ? 'Güncelleme Mevcut' : 'Update Available', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
            content: Text(isTr ? result.messageTr : result.messageEn, style: const TextStyle(fontSize: 14, height: 1.4)),
            actions: [
              if (!result.isForce)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isTr ? 'Daha Sonra' : 'Later', style: const TextStyle(color: Colors.grey)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final uri = Uri.parse(result.updateUrl);
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      // Fallback: Just try launching anyway, or show error.
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isTr ? 'Bağlantı açılamadı.' : 'Could not open link.')),
                      );
                    }
                  }
                },
                child: Text(isTr ? 'Şimdi Güncelle' : 'Update Now', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
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
      final color = isSelected ? Theme.of(context).primaryColor : Colors.grey.shade500;
      return Expanded(
        child: InkWell(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          backgroundColor: Theme.of(context).primaryColor,
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
        color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        elevation: 16,
        shadowColor: Colors.black45,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildNavItem(0, Icons.calculate_rounded, isTr ? 'Özet' : 'Summary'),
            buildNavItem(1, Icons.menu_book_rounded, isTr ? 'Rehber' : 'Guide'),
            const SizedBox(width: 56), // Space for FAB
            buildNavItem(2, Icons.history_rounded, isTr ? 'Geçmiş' : 'History'),
            buildNavItem(3, Icons.settings_rounded, isTr ? 'Ayarlar' : 'Settings'),
          ],
        ),
      ),
    );
  }
}

