import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/app_state.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/hijri_date_helper.dart';
import '../../assets/domain/asset_model.dart';
import '../../history/domain/history_model.dart';
import '../../exchange_rates/data/exchange_rate_repository.dart';
import '../../exchange_rates/presentation/exchange_rate_provider.dart';
import '../../exchange_rates/domain/exchange_rate_model.dart';
import '../../calculator/presentation/calculator_provider.dart';
import '../../../core/constants/currency_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_form_controls.dart';

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
      if (mounted) {
        setState(() {
          _version = '${info.version}+${info.buildNumber}';
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchRates() async {
    setState(() => _isLoadingRates = true);
    final repo = ExchangeRateRepository();
    final rates = await repo.getRates();
    if (mounted) {
      setState(() {
        _rates = rates;
        _isLoadingRates = false;
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return AppSectionHeader(title: title);
  }

  Widget _buildCard({required List<Widget> children, required bool isDark}) {
    return AppCard(
      child: Column(children: children),
    );
  }

  Widget _buildSelectorPill<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return AppDropdownPill<T>(
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final isTr = appState.language == Language.tr;
    final isDark = appState.isDark;
    final settingsBox = Hive.box('settings');
    final currencyFormat = settingsBox.get('currency_format', defaultValue: 'auto');
    final zakatMonth = settingsBox.get('zakat_hijri_month') as int?;
    final zakatDay = settingsBox.get('zakat_hijri_day') as int?;
    final hasZakatDate = zakatMonth != null && zakatDay != null;
    final zakatDateDisplay = hasZakatDate
        ? '$zakatDay ${HijriDateHelper.getHijriMonthName(zakatMonth, appState.language)}'
        : (isTr ? 'Belirlenmedi' : 'Not Set');

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
        ? 'Soru, görüş ve önerileriniz için bizimle iletişime geçebilirsiniz:\n\nE-posta: sefa1986@gmail.com'
        : 'You can contact us for your questions, comments, and suggestions:\n\nEmail: sefa1986@gmail.com';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          isTr ? 'Ayarlar' : 'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Theme.of(context).textTheme.displayLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          // 1. Fıkıh ve Hesaplama
          _buildSectionHeader(isTr ? 'FIKIH VE HESAPLAMA' : 'FIQH & CALCULATION'),
          _buildCard(
            isDark: isDark,
            children: [
              // Mezhep
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3A712).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bookmark_border_rounded, color: Color(0xFFF3A712), size: 20),
                ),
                title: Text(isTr ? 'Mezhep' : 'Sect', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  isTr ? 'Ziynet muafiyeti ve borç kuralları' : 'Rules for jewelry exemption & debts',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                trailing: _buildSelectorPill<Sect>(
                  value: appState.sect,
                  isDark: isDark,
                  items: Sect.values.map((s) {
                    String label;
                    switch (s) {
                      case Sect.hanefi: label = isTr ? 'Hanefi' : 'Hanafi'; break;
                      case Sect.safi: label = isTr ? 'Şafii' : 'Shafi\'i'; break;
                      case Sect.maliki: label = isTr ? 'Maliki' : 'Maliki'; break;
                      case Sect.hanbeli: label = isTr ? 'Hanbeli' : 'Hanbali'; break;
                    }
                    return DropdownMenuItem(
                      value: s,
                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) notifier.setSect(val);
                  },
                ),
              ),
              const Divider(height: 1, indent: 64),

              // Nisab Türü
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.scale_rounded, color: Color(0xFFF3A712), size: 20),
                ),
                title: Text(isTr ? 'Nisab Türü' : 'Nisab Type', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  isTr ? 'Zenginlik asgari sınırı' : 'Minimum obligation threshold',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                trailing: _buildSelectorPill<NisabType>(
                  value: appState.nisabType,
                  isDark: isDark,
                  items: [
                    DropdownMenuItem(
                      value: NisabType.gold,
                      child: Text(isTr ? 'Altın (80.18 gr)' : 'Gold (80.18 gr)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: NisabType.silver,
                      child: Text(isTr ? 'Gümüş (595 gr)' : 'Silver (595 gr)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      notifier.setNisabType(val);
                      ref.invalidate(calculatorProvider);
                    }
                  },
                ),
              ),
              const Divider(height: 1, indent: 64),

              // Para Birimi
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.currency_exchange_rounded, color: Color(0xFFF3A712), size: 20),
                ),
                title: Text(isTr ? 'Para Birimi' : 'Base Currency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  isTr ? 'Değerleme ve gösterim para birimi' : 'Display and valuation currency',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                trailing: _buildSelectorPill<AppCurrency>(
                  value: appState.currency,
                  isDark: isDark,
                  items: AppCurrency.values.map((c) {
                    String label;
                    switch (c) {
                      case AppCurrency.tryCurrency: label = '₺ TRY'; break;
                      case AppCurrency.usd: label = '\$ USD'; break;
                      case AppCurrency.eur: label = '€ EUR'; break;
                    }
                    return DropdownMenuItem(
                      value: c,
                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      notifier.setCurrency(val);
                      ref.invalidate(exchangeRatesProvider);
                    }
                  },
                ),
              ),
              const Divider(height: 1, indent: 64),

              // Sayı ve Para Formatı
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pin_outlined, color: Color(0xFFF3A712), size: 20),
                ),
                title: Text(isTr ? 'Sayı Formatı' : 'Number Format', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  isTr ? 'Basamak ayracı biçimi' : 'Thousand and decimal separator',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                trailing: _buildSelectorPill<String>(
                  value: currencyFormat,
                  isDark: isDark,
                  items: [
                    DropdownMenuItem(value: 'auto', child: Text(isTr ? 'Otomatik' : 'Auto', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    const DropdownMenuItem(value: 'tr', child: Text('1.234.567,89', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    const DropdownMenuItem(value: 'us', child: Text('1,234,567.89', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
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
              const Divider(height: 1, indent: 64),

              // Zekat Yıl Dönümü
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_outlined, color: Color(0xFFF3A712), size: 20),
                ),
                title: Text(isTr ? 'Zekat Yıl Dönümü (Havl)' : 'Zakat Anniversary (Hawl)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  isTr ? 'Hicri takvim üzerinden yıllık takip' : 'Yearly tracking on Hijri calendar',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                trailing: InkWell(
                  onTap: () => _showZakatDateDialog(context, settingsBox, isTr, appState.language, zakatMonth, zakatDay),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasZakatDate
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : (isDark ? Colors.white10 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasZakatDate ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          zakatDateDisplay,
                          style: TextStyle(
                            color: hasZakatDate ? AppColors.primary : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
                onTap: () => _showZakatDateDialog(context, settingsBox, isTr, appState.language, zakatMonth, zakatDay),
              ),
            ],
          ),

          // 2. Görünüm ve Bildirimler
          _buildSectionHeader(isTr ? 'GÖRÜNÜM VE BİLDİRİMLER' : 'APPEARANCE & NOTIFICATIONS'),
          _buildCard(
            isDark: isDark,
            children: [
              // Dil
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.translate_rounded, color: Color(0xFFF3A712), size: 20),
                ),
                title: Text(isTr ? 'Uygulama Dili' : 'Language', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: _buildSelectorPill<Language>(
                  value: appState.language,
                  isDark: isDark,
                  items: const [
                    DropdownMenuItem(value: Language.tr, child: Text('Türkçe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    DropdownMenuItem(value: Language.en, child: Text('English', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                  onChanged: (val) {
                    if (val != null) notifier.setLanguage(val);
                  },
                ),
              ),
              const Divider(height: 1, indent: 64),

              // Karanlık Tema
              SwitchListTile(
                secondary: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    appState.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(isTr ? 'Karanlık Tema' : 'Dark Mode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  isTr ? 'Göz yormayan koyu renkler' : 'Comfortable low-light colors',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                value: appState.isDark,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => notifier.toggleTheme(),
              ),
              const Divider(height: 1, indent: 64),

              // Bildirimler
              SwitchListTile(
                secondary: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFF3A712), size: 20),
                ),
                title: Text(isTr ? 'Zekat Hatırlatıcıları' : 'Zakat Reminders', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  isTr ? 'Yıl dönümüne 30 gün, 7 gün ve gününde bildirim' : 'Notification at 30 days, 7 days and on anniversary',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                value: settingsBox.get('notifications_enabled', defaultValue: false) as bool,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  if (val) {
                    final granted = await NotificationService().requestPermissions();
                    if (!granted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isTr ? 'Bildirim izni verilmedi.' : 'Notification permission denied.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    await settingsBox.put('notifications_enabled', true);
                    setState(() {});

                    if (hasZakatDate) {
                      final days = HijriDateHelper.getDaysUntilNextZakat(zakatMonth, zakatDay) ?? 0;
                      await NotificationService().scheduleZakatReminders(
                        daysUntilAnniversary: days,
                        isTr: isTr,
                      );
                    }

                    await NotificationService().showTestNotification(isTr: isTr);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isTr ? 'Zekat hatırlatıcıları aktif edildi. Test bildirimi gönderildi.' : 'Zakat reminders enabled. Test notification sent.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    await settingsBox.put('notifications_enabled', false);
                    await NotificationService().cancelAllReminders();
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isTr ? 'Hatırlatıcı bildirimler kapatıldı.' : 'Reminders disabled.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          // 3. Canlı Piyasa Kurları
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(isTr ? 'GÜNCEL PİYASA KURLARI' : 'LIVE MARKET RATES'),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Text(
                      isTr
                          ? 'Son Güncelleme: ${_rates.isNotEmpty ? "${_rates.first.lastUpdate.hour.toString().padLeft(2, '0')}:${_rates.first.lastUpdate.minute.toString().padLeft(2, '0')}" : "--:--"}'
                          : 'Last Sync: ${_rates.isNotEmpty ? "${_rates.first.lastUpdate.hour.toString().padLeft(2, '0')}:${_rates.first.lastUpdate.minute.toString().padLeft(2, '0')}" : "--:--"}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      color: Theme.of(context).primaryColor,
                      onPressed: _fetchRates,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(left: 4, right: 4),
                    )
                  ],
                ),
              ),
            ],
          ),
          _buildCard(
            isDark: isDark,
            children: [
              if (_isLoadingRates)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFF3A712))),
                )
              else ...[
                _buildRateRow('GOLD', isTr ? 'Gram Altın (24K)' : 'Gold (24K)', Icons.grid_goldenratio_rounded, appState.language, appState),
                const Divider(height: 1, indent: 56),
                _buildRateRow('SILVER', isTr ? 'Gram Gümüş' : 'Gram Silver', Icons.diamond_outlined, appState.language, appState),
                const Divider(height: 1, indent: 56),
                _buildRateRow('USD', 'Amerikan Doları (USD)', Icons.attach_money_rounded, appState.language, appState),
                const Divider(height: 1, indent: 56),
                _buildRateRow('EUR', 'Euro (EUR)', Icons.euro_rounded, appState.language, appState),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // 4. Güvenlik & Gizlilik Bildirimi (Trust Banner)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B232E) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTr ? '%100 Yerel ve Güvenli Depolama' : '100% Local and Secure Storage',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTr
                            ? 'Hiçbir finansal bilginiz sunuculara yüklenmez. Tüm hesaplamalar sadece cihazınızda saklanır.'
                            : 'No financial data is uploaded. Calculations and assets remain strictly on your device.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. Bilgi ve Destek
          _buildSectionHeader(isTr ? 'UYGULAMA BİLGİLERİ VE DESTEK' : 'APP INFO & SUPPORT'),
          _buildCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.verified_user_outlined, color: Colors.grey.shade600, size: 20),
                ),
                title: Text(privacyTitle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () => _showInfoDialog(context, privacyTitle, privacyContent),
              ),
              const Divider(height: 1, indent: 64),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description_outlined, color: Colors.grey.shade600, size: 20),
                ),
                title: Text(termsTitle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () => _showInfoDialog(context, termsTitle, termsContent),
              ),
              const Divider(height: 1, indent: 64),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.mail_outline_rounded, color: Colors.grey.shade600, size: 20),
                ),
                title: Text(contactTitle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () => _showInfoDialog(context, contactTitle, contactContent),
              ),
              const Divider(height: 1, indent: 64),
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
                ),
                title: Text(
                  isTr ? 'Tüm Verileri Sıfırla' : 'Reset All Data',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
                onTap: () => _showResetDialog(context, ref, isTr),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Footer info
          Center(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  'ZekatApp v$_version',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  isTr ? 'Diyanet Fıkıh Standartları ile Uyumlu' : 'Aligned with Fiqh Standards',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(String code, String name, IconData icon, Language lang, AppState appState) {
    final conversionRate = CurrencyConstants.getConversionRate(appState.currency, _rates);

    final rate = _rates.firstWhere(
      (r) => r.currencyCode == code,
      orElse: () => ExchangeRateModel(
        currencyCode: code,
        currencyName: name,
        buyingPrice: 0,
        sellingPrice: 0,
        lastUpdate: DateTime.now(),
      ),
    );

    final displayPrice = conversionRate > 0 ? rate.buyingPrice / conversionRate : 0.0;

    Color iconColor;
    Color bgColor;
    if (code == 'GOLD') {
      iconColor = AppColors.primary;
      bgColor = const Color(0xFFFEF3C7);
    } else if (code == 'SILVER') {
      iconColor = const Color(0xFF64748B);
      bgColor = const Color(0xFFE2E8F0);
    } else if (code == 'USD') {
      iconColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFD1FAE5);
    } else {
      iconColor = const Color(0xFF3B82F6);
      bgColor = const Color(0xFFDBEAFE);
    }

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: appState.isDark ? iconColor.withValues(alpha: 0.15) : bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(name, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500, fontSize: 13)),
      trailing: Text(
        '${appState.currency.symbol}${formatCurrency(displayPrice, lang)}',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
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
          content: Text(
            isTr
                ? 'Tüm varlıklarınız ve geçmiş kayıtlarınız silinecek ve başlangıç ekranına döneceksiniz. Bu işlem geri alınamaz.\n\nEmin misiniz?'
                : 'All your assets and history will be deleted and you will return to the start screen. This cannot be undone.\n\nAre you sure?',
          ),
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

  void _showZakatDateDialog(BuildContext context, Box settingsBox, bool isTr, Language lang, int? currentMonth, int? currentDay) {
    int selectedMonth = currentMonth ?? 9; // Default to Ramadan
    int selectedDay = currentDay ?? 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isTr ? 'Zekat Yıl Dönümü' : 'Zakat Anniversary', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isTr ? 'Zekatınızı her yıl ödediğiniz Hicri tarihi seçin. (Örn: 15 Ramazan)' : 'Select the Hijri date you pay your Zakat every year.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButton<int>(
                          value: selectedDay,
                          isExpanded: true,
                          items: List.generate(30, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('$d'))).toList(),
                          onChanged: (val) {
                            if (val != null) setStateDialog(() => selectedDay = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButton<int>(
                          value: selectedMonth,
                          isExpanded: true,
                          items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(HijriDateHelper.getHijriMonthName(m, lang)))).toList(),
                          onChanged: (val) {
                            if (val != null) setStateDialog(() => selectedMonth = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (currentMonth != null) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        await settingsBox.delete('zakat_hijri_month');
                        await settingsBox.delete('zakat_hijri_day');
                        await NotificationService().cancelAllReminders();
                        setState(() {});
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      label: Text(isTr ? 'Tarihi Temizle' : 'Clear Date', style: const TextStyle(color: Colors.red)),
                    )
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3A712),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await settingsBox.put('zakat_hijri_month', selectedMonth);
                    await settingsBox.put('zakat_hijri_day', selectedDay);
                    final notifEnabled = settingsBox.get('notifications_enabled', defaultValue: false) as bool;
                    if (notifEnabled) {
                      final days = HijriDateHelper.getDaysUntilNextZakat(selectedMonth, selectedDay) ?? 0;
                      await NotificationService().scheduleZakatReminders(
                        daysUntilAnniversary: days,
                        isTr: isTr,
                      );
                    }
                    setState(() {});
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(isTr ? 'Kaydet' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
