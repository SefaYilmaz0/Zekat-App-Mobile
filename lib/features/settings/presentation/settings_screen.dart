import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../assets/domain/asset_model.dart';
import '../../history/domain/history_model.dart';
import '../../exchange_rates/data/exchange_rate_repository.dart';
import '../../exchange_rates/domain/exchange_rate_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<ExchangeRateModel> _rates = [];
  bool _isLoadingRates = true;

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() => _isLoadingRates = true);
    final repo = ExchangeRateRepository();
    final rates = await repo.getRates();
    setState(() {
      _rates = rates;
      _isLoadingRates = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final isTr = appState.language == Language.tr;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        title: Text(isTr ? 'Ayarlar' : 'Settings', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Privacy Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_rounded, color: Color(0xFFF3A712)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isTr ? 'Verileriniz Cihazınızda' : 'Your Data is on Your Device', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(
                        isTr 
                          ? 'Uygulama herhangi bir sunucuya veri göndermez. Tüm hesaplamalarınız ve tercihleriniz bu cihazın hafızasında güvenle saklanır.'
                          : 'The app does not send data to any server. All calculations and preferences are securely stored in this device\'s memory.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Market Data
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isTr ? 'PİYASA VERİSİ' : 'MARKET DATA', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Row(
                children: [
                  Text(isTr ? 'Son: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}' : 'Last: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    color: Colors.grey.shade500,
                    onPressed: _fetchRates,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 4),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: _isLoadingRates 
              ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              : Column(
                  children: [
                    _buildRateRow('GOLD', isTr ? 'Gram Altın (24K)' : 'Gold (24K)', Icons.grid_goldenratio_rounded),
                    const Divider(height: 1),
                    _buildRateRow('USD', 'Amerikan Doları', Icons.attach_money_rounded),
                    const Divider(height: 1),
                    _buildRateRow('EUR', 'Euro', Icons.euro_rounded),
                  ],
                ),
          ),
          const SizedBox(height: 24),

          // Preferences
          Text(isTr ? 'TERCİHLER' : 'PREFERENCES', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(isTr ? 'Dil' : 'Language'),
                  trailing: DropdownButton<Language>(
                    value: appState.language,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: Language.tr, child: Text('Türkçe')),
                      DropdownMenuItem(value: Language.en, child: Text('English')),
                    ],
                    onChanged: (val) { if(val != null) notifier.setLanguage(val); },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(isTr ? 'Karanlık Mod' : 'Dark Mode'),
                  value: appState.isDark,
                  activeColor: const Color(0xFFF3A712),
                  onChanged: (val) => notifier.toggleTheme(),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(isTr ? 'Mezhep' : 'Sect'),
                  trailing: DropdownButton<Sect>(
                    value: appState.sect,
                    underline: const SizedBox(),
                    items: Sect.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                    onChanged: (val) { if(val != null) notifier.setSect(val); },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(isTr ? 'Para Birimi' : 'Currency'),
                  trailing: DropdownButton<AppCurrency>(
                    value: appState.currency,
                    underline: const SizedBox(),
                    items: AppCurrency.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase().replaceAll('CURRENCY', '')))).toList(),
                    onChanged: (val) { if(val != null) notifier.setCurrency(val); },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App & Data Management
          Text(isTr ? 'UYGULAMA VE VERİ YÖNETİMİ' : 'APP & DATA MANAGEMENT', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.add_to_home_screen_rounded),
                  title: Text(isTr ? 'Ana Ekrana Ekle' : 'Add to Home Screen'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: Text(isTr ? 'Tüm Verileri Sıfırla' : 'Reset All Data', style: const TextStyle(color: Colors.red)),
                  onTap: () => _showResetDialog(context, ref, isTr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Footer
          Center(
            child: Column(
              children: [
                const Icon(Icons.calculate_rounded, color: Color(0xFFF3A712), size: 48),
                const SizedBox(height: 16),
                Text('ZekatApp Versiyon 1.0.1 (Offline)', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isTr ? 'Gizlilik Politikası' : 'Privacy Policy', style: const TextStyle(color: Color(0xFFF3A712), decoration: TextDecoration.underline)),
                    const SizedBox(width: 16),
                    Text(isTr ? 'Kullanım Koşulları' : 'Terms of Use', style: const TextStyle(color: Color(0xFFF3A712), decoration: TextDecoration.underline)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(isTr ? 'İletişim' : 'Contact Us', style: const TextStyle(color: Color(0xFFF3A712), decoration: TextDecoration.underline)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRateRow(String code, String name, IconData icon) {
    final rate = _rates.firstWhere((r) => r.currencyCode == code, orElse: () => ExchangeRateModel(currencyCode: code, currencyName: name, buyingPrice: 0, sellingPrice: 0, lastUpdate: DateTime.now()));
    
    Color iconColor;
    Color bgColor;
    if (code == 'GOLD') {
      iconColor = const Color(0xFFF3A712);
      bgColor = const Color(0xFFFEF3C7);
    } else if (code == 'USD') {
      iconColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFD1FAE5);
    } else { // EUR
      iconColor = const Color(0xFF3B82F6);
      bgColor = const Color(0xFFDBEAFE);
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(name, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      trailing: Text('₺${rate.buyingPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref, bool isTr) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isTr ? 'Dikkat!' : 'Warning!', style: const TextStyle(color: Colors.red)),
          content: Text(isTr 
            ? 'Tüm varlıklarınız ve geçmiş kayıtlarınız silinecek ve başlangıç ekranına döneceksiniz. Bu işlem geri alınamaz.\n\nEmin misiniz?'
            : 'All your assets and history will be deleted and you will return to the start screen. This cannot be undone.\n\nAre you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
              child: Text(isTr ? 'Evet, Sıfırla' : 'Yes, Reset'),
            ),
          ],
        );
      },
    );
  }
}
