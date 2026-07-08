import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../assets/domain/asset_model.dart';
import '../../history/domain/history_model.dart';
import '../../exchange_rates/data/exchange_rate_repository.dart';
import '../../exchange_rates/domain/exchange_rate_model.dart';
import '../../calculator/presentation/calculator_provider.dart';
import '../../../core/theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<ExchangeRateModel> _rates = [];
  bool _isLoadingRates = true;
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _fetchRates();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = '${info.version}+${info.buildNumber}';
      });
    } catch (_) {}
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
    final settingsBox = Hive.box('settings');
    final currencyFormat = settingsBox.get('currency_format', defaultValue: 'auto');

    final privacyTitle = isTr ? 'Gizlilik Politikası' : 'Privacy Policy';
    final privacyContent = isTr
        ? 'ZekatApp, kullanıcı gizliliğine büyük önem verir. Uygulama tamamen çevrimdışı çalışır ve girdiğiniz hiçbir finansal veya kişisel veri sunucularımıza gönderilmez.\n\nTüm verileriniz yalnızca cihazınızın yerel depolama alanında saklanır. Uygulamayı sildiğinizde veya verileri sıfırladığınızda bu bilgiler kalıcı olarak silinir.'
        : 'ZakatApp attaches great importance to user privacy. The application works completely offline and no financial or personal data you enter is sent to our servers.\n\nAll your data is stored only in your device\'s local storage. When you delete the app or reset the data, this information is permanently deleted.';

    final termsTitle = isTr ? 'Kullanım Şartları' : 'Terms of Use';
    final termsContent = isTr
        ? 'ZekatApp, zekat hesaplamalarınızı kolaylaştırmak amacıyla geliştirilmiş bir araçtır. Uygulama tarafından sağlanan hesaplamalar ve piyasa verileri bilgilendirme amaçlıdır.\n\nZekat ibadetinizi yerine getirirken, güncel altın, gümüş ve döviz fiyatlarını yerel kuyumcunuzdan veya güvenilir kaynaklardan teyit etmeniz önerilir.'
        : 'ZakatApp is a tool developed to facilitate your zakat calculations. Calculations and market data provided by the application are for informational purposes.\n\nWhen fulfilling your zakat worship, it is recommended that you confirm the current gold, silver, and foreign exchange prices from your local jeweler or reliable sources.';

    final contactTitle = isTr ? 'Bize Ulaşın' : 'Contact Us';
    final contactContent = isTr
        ? 'Soru, görüş ve önerileriniz için bizimle iletişime geçebilirsiniz:\n\nE-posta: support@zekatapp.com'
        : 'You can contact us for your questions, comments, and suggestions:\n\nEmail: support@zekatapp.com';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(isTr ? 'Ayarlar' : 'Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Theme.of(context).textTheme.displayLarge?.color)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Privacy Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appState.isDark ? AppTheme.surfaceDark : const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appState.isDark ? Colors.white10 : const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline_rounded, color: Color(0xFFF3A712)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isTr ? 'Verileriniz Cihazınızda' : 'Your Data is Local', style: TextStyle(fontWeight: FontWeight.bold, color: appState.isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 4),
                      Text(
                        isTr 
                          ? 'Uygulama herhangi bir sunucuya veri göndermez. Tüm hesaplamalarınız ve tercihleriniz bu cihazda güvenle saklanır.'
                          : 'No data is uploaded. All calculations and preferences are securely stored locally on this device.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.5),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Market Data Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isTr ? 'PİYASA VERİSİ' : 'MARKET DATA', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Row(
                children: [
                  Text(
                    isTr 
                      ? 'Son Güncelleme: ${_rates.isNotEmpty ? "${_rates.first.lastUpdate.hour.toString().padLeft(2, '0')}:${_rates.first.lastUpdate.minute.toString().padLeft(2, '0')}" : "--:--"}' 
                      : 'Last Sync: ${_rates.isNotEmpty ? "${_rates.first.lastUpdate.hour.toString().padLeft(2, '0')}:${_rates.first.lastUpdate.minute.toString().padLeft(2, '0')}" : "--:--"}', 
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11)
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    color: Theme.of(context).primaryColor,
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
              color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: appState.isDark ? Colors.white10 : Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: _isLoadingRates 
              ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: Color(0xFFF3A712))))
              : Column(
                  children: [
                    _buildRateRow('GOLD', isTr ? 'Gram Altın (24K)' : 'Gold (24K)', Icons.grid_goldenratio_rounded, appState.language),
                    const Divider(height: 1, indent: 56),
                    _buildRateRow('USD', 'Amerikan Doları (USD)', Icons.attach_money_rounded, appState.language),
                    const Divider(height: 1, indent: 56),
                    _buildRateRow('EUR', 'Euro (EUR)', Icons.euro_rounded, appState.language),
                  ],
                ),
          ),
          const SizedBox(height: 24),

          // Preferences Section
          Text(isTr ? 'TERCİHLER VE HESAPLAMA' : 'PREFERENCES & CALCULATION', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: appState.isDark ? Colors.white10 : Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: Color(0xFFF3A712)),
                  title: Text(isTr ? 'Dil' : 'Language', style: const TextStyle(fontWeight: FontWeight.w500)),
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
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: Color(0xFFF3A712)),
                  title: Text(isTr ? 'Karanlık Mod' : 'Dark Mode', style: const TextStyle(fontWeight: FontWeight.w500)),
                  value: appState.isDark,
                  activeThumbColor: const Color(0xFFF3A712),
                  onChanged: (val) => notifier.toggleTheme(),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.bookmark_border_rounded, color: Color(0xFFF3A712)),
                  title: Text(isTr ? 'Mezhep' : 'Sect', style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: DropdownButton<Sect>(
                    value: appState.sect,
                    underline: const SizedBox(),
                    items: Sect.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                    onChanged: (val) { if(val != null) notifier.setSect(val); },
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.monetization_on_outlined, color: Color(0xFFF3A712)),
                  title: Text(isTr ? 'Para Birimi' : 'Currency', style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: DropdownButton<AppCurrency>(
                    value: appState.currency,
                    underline: const SizedBox(),
                    items: AppCurrency.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase().replaceAll('CURRENCY', '')))).toList(),
                    onChanged: (val) { if(val != null) notifier.setCurrency(val); },
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.pin_outlined, color: Color(0xFFF3A712)),
                  title: Text(isTr ? 'Sayı ve Para Formatı' : 'Number & Currency Format', style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: DropdownButton<String>(
                    value: currencyFormat,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'auto', child: Text(isTr ? 'Otomatik' : 'Auto')),
                      const DropdownMenuItem(value: 'tr', child: Text('1.234.567,89')),
                      const DropdownMenuItem(value: 'us', child: Text('1,234,567.89')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          settingsBox.put('currency_format', val);
                        });
                        ref.invalidate(calculatorProvider);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Legal & Info Section
          Text(isTr ? 'UYGULAMA BİLGİLERİ VE DESTEK' : 'APP INFO & SUPPORT', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: appState.isDark ? Colors.white10 : Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined, color: Color(0xFFF3A712)),
                  title: Text(privacyTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _showInfoDialog(context, privacyTitle, privacyContent),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: Color(0xFFF3A712)),
                  title: Text(termsTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _showInfoDialog(context, termsTitle, termsContent),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded, color: Color(0xFFF3A712)),
                  title: Text(contactTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _showInfoDialog(context, contactTitle, contactContent),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: Text(isTr ? 'Tüm Verileri Sıfırla' : 'Reset All Data', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
                  onTap: () => _showResetDialog(context, ref, isTr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Footer info
          Center(
            child: Column(
              children: [
                const Icon(Icons.calculate_rounded, color: Color(0xFFF3A712), size: 40),
                const SizedBox(height: 12),
                Text('ZekatApp v$_version (Offline)', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRateRow(String code, String name, IconData icon, Language lang) {
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
      title: Text(name, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: Text('${appState.currency.symbol}${formatCurrency(rate.buyingPrice, lang)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    final isTr = ref.read(appStateProvider).language == Language.tr;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(child: Text(content, style: const TextStyle(height: 1.5, fontSize: 14))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isTr ? 'Kapat' : 'Close', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref, bool isTr) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isTr ? 'Dikkat!' : 'Warning!', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final assetsBox = Hive.box<AssetModel>('assets');
                await assetsBox.clear();
                
                final historyBox = Hive.box<HistoryModel>('history');
                await historyBox.clear();

                ref.read(appStateProvider.notifier).resetApp();

                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/');
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

