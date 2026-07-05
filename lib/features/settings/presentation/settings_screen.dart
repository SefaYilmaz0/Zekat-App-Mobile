import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../assets/domain/asset_model.dart';
import '../../history/domain/history_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Görünüm (Tema)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Görünüm',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          SwitchListTile(
            title: const Text('Karanlık Mod (Dark Mode)'),
            subtitle: const Text('Göz yorgunluğunu azaltır.'),
            value: appState.isDark,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              notifier.toggleTheme();
            },
          ),
          
          const Divider(),

          // Tercihler
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Tercihler',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            title: const Text('Mezhep'),
            subtitle: Text(_getSectName(appState.sect)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSectDialog(context, appState, notifier),
          ),
          ListTile(
            title: const Text('Para Birimi'),
            subtitle: Text(appState.currency.name.toUpperCase().replaceAll('CURRENCY', '')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyDialog(context, appState, notifier),
          ),
          ListTile(
            title: const Text('Dil'),
            subtitle: Text(appState.language == Language.tr ? 'Türkçe' : 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, appState, notifier),
          ),

          const Divider(),

          // Veri Yönetimi
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Veri Yönetimi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Tüm Verileri Sıfırla', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Varlıklarınız ve geçmiş kayıtlarınız silinir.'),
            onTap: () => _showResetDialog(context, ref),
          ),
        ],
      ),
    );
  }

  String _getSectName(Sect sect) {
    switch (sect) {
      case Sect.hanefi: return 'Hanefi';
      case Sect.safi: return 'Şafii';
      case Sect.maliki: return 'Maliki';
      case Sect.hanbeli: return 'Hanbeli';
    }
  }

  void _showSectDialog(BuildContext context, AppState state, AppStateNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mezhep Seçimi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Sect.values.map((sect) {
              return RadioListTile<Sect>(
                title: Text(_getSectName(sect)),
                value: sect,
                groupValue: state.sect,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (val) {
                  if (val != null) {
                    notifier.setSect(val);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showCurrencyDialog(BuildContext context, AppState state, AppStateNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Para Birimi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppCurrency.values.map((c) {
              return RadioListTile<AppCurrency>(
                title: Text(c.name.toUpperCase().replaceAll('CURRENCY', '')),
                value: c,
                groupValue: state.currency,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (val) {
                  if (val != null) {
                    notifier.setCurrency(val);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, AppState state, AppStateNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dil / Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Language.values.map((l) {
              return RadioListTile<Language>(
                title: Text(l == Language.tr ? 'Türkçe' : 'English'),
                value: l,
                groupValue: state.language,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (val) {
                  if (val != null) {
                    notifier.setLanguage(val);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dikkat!', style: TextStyle(color: Colors.red)),
          content: const Text('Tüm varlıklarınız ve geçmiş kayıtlarınız silinecek ve başlangıç ekranına döneceksiniz. Bu işlem geri alınamaz.\n\nEmin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final assetsBox = Hive.box<AssetModel>('assets');
                await assetsBox.clear();
                
                final historyBox = Hive.box<HistoryModel>('history');
                await historyBox.clear();

                ref.read(appStateProvider.notifier).resetApp();

                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/welcome');
                }
              },
              child: const Text('Evet, Sıfırla'),
            ),
          ],
        );
      },
    );
  }
}
