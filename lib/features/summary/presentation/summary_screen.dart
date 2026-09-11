import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/hijri_date_helper.dart';
import 'package:share_plus/share_plus.dart';
import '../../calculator/presentation/calculator_provider.dart';
import '../../assets/domain/asset_model.dart';
import '../../assets/presentation/widgets/add_asset_dialog.dart';
import '../services/pdf_report_service.dart';
import 'widgets/pdf_preview_screen.dart';
import '../../../core/theme.dart';
import '../../../core/constants/currency_constants.dart';
import '../../exchange_rates/presentation/exchange_rate_provider.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_asset_tile.dart';

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
      canvas.drawLine(Offset(i + size.height, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  void _deleteAsset(BuildContext context, AssetModel asset, bool isTr) {
    final box = Hive.box<AssetModel>('assets');
    box.delete(asset.id);
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isTr ? '${asset.name} silindi' : '${asset.name} deleted'),
        action: SnackBarAction(
          label: isTr ? 'Geri Al' : 'Undo',
          onPressed: () {
            box.put(asset.id, asset);
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;
    final calcAsync = ref.watch(calculatorProvider);
    final calc = calcAsync.value;
    final assetsAsync = ref.watch(assetsProvider);
    final ratesAsync = ref.watch(exchangeRatesProvider);
    final rates = ratesAsync.value ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(isTr ? 'Özet' : 'Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Theme.of(context).textTheme.displayLarge?.color)),
        centerTitle: true,
        actions: [
          if (calc != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              color: const Color(0xFFF3A712),
              onPressed: () async {
                final assets = assetsAsync.value ?? [];
                final pdfBytes = await PdfReportService.generateReport(
                  calc: calc,
                  assets: assets,
                  appState: appState,
                  isTr: isTr,
                );
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfPreviewScreen(pdfBytes: pdfBytes),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              color: const Color(0xFFF3A712),
              onPressed: () {
                final sym = appState.currency.symbol;
                final text = isTr
                    ? 'ZekatApp ile hesaplanan Toplam Zekat Tutarı: $sym${calc.isNisabReached ? formatCurrency(calc.zakatToPay, appState.language) : formatCurrency(0.0, appState.language)}\nNisab Sınırı: $sym${formatCurrency(calc.nisabThreshold, appState.language, decimalDigits: 0)}\nNet Varlık: $sym${formatCurrency(calc.netZakatableAmount, appState.language, decimalDigits: 0)}'
                    : 'Total Zakat calculated with ZakatApp: $sym${calc.isNisabReached ? formatCurrency(calc.zakatToPay, appState.language) : formatCurrency(0.0, appState.language)}\nNisab Limit: $sym${formatCurrency(calc.nisabThreshold, appState.language, decimalDigits: 0)}\nNet Worth: $sym${formatCurrency(calc.netZakatableAmount, appState.language, decimalDigits: 0)}';
                SharePlus.instance.share(ShareParams(text: text));
              },
            ),
          ],
        ],
      ),
      body: calcAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
        data: (calc) {
          final progressPercent = calc.nisabThreshold > 0 
            ? (calc.netZakatableAmount / calc.nisabThreshold).clamp(0.0, 1.0) 
            : 0.0;
            
          final assets = assetsAsync.value ?? [];
          final myAssets = assets.where((a) => a.category != AssetCategory.debt).toList();
          final myDebts = assets.where((a) => a.category == AssetCategory.debt).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Card (Dark Slate Grey)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3643),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: GridPatternPainter()),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                isTr ? 'TOPLAM ÖDENECEK ZEKAT' : 'TOTAL ZAKAT',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${appState.currency.symbol}${calc.isNisabReached ? formatCurrency(calc.zakatToPay, appState.language) : formatCurrency(0.0, appState.language)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                HijriDateHelper.formatHijri(DateTime.now(), appState.language),
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      calc.isNisabReached ? (isTr ? 'NİSAB MİKTARI ÜSTÜNDE' : 'ABOVE NISAB THRESHOLD') : (isTr ? 'NİSAB MİKTARI ALTINDA' : 'BELOW NISAB THRESHOLD'),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Zakat Anniversary Countdown Card
                ValueListenableBuilder<Box>(
                  valueListenable: Hive.box('settings').listenable(keys: ['zakat_hijri_month', 'zakat_hijri_day']),
                  builder: (context, box, child) {
                    final hMonth = box.get('zakat_hijri_month') as int?;
                    final hDay = box.get('zakat_hijri_day') as int?;
                    if (hMonth == null || hDay == null) return const SizedBox.shrink();

                    final daysLeft = HijriDateHelper.getDaysUntilNextZakat(hMonth, hDay) ?? 0;
                    final totalDays = 354; // Hicri yıl ortalama
                    final progress = (1 - (daysLeft / totalDays)).clamp(0.0, 1.0);
                    final monthName = HijriDateHelper.getHijriMonthName(hMonth, appState.language);
                    final isUrgent = daysLeft <= 30;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isUrgent ? Colors.red.withValues(alpha: 0.3) : (appState.isDark ? Colors.white10 : Colors.transparent)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.event_available_rounded, color: isUrgent ? Colors.red : const Color(0xFFF3A712), size: 18),
                                  const SizedBox(width: 8),
                                  Text(isTr ? 'Zekat Yıl Dönümü' : 'Zakat Anniversary', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text('$hDay $monthName', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isTr ? 'Kalan Süre:' : 'Time Left:', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              Text(isTr ? '$daysLeft Gün' : '$daysLeft Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isUrgent ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(isUrgent ? Colors.red : const Color(0xFFF3A712)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Nisab Progress Card (White)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appState.isDark ? Colors.white10 : Colors.transparent),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isTr ? 'Mevcut Net Varlık' : 'Net Worth', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${appState.currency.symbol}${formatCurrency(calc.netZakatableAmount, appState.language, decimalDigits: 0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF3A712)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(isTr ? 'Nisab Sınırı' : 'Nisab Limit', style: const TextStyle(color: Color(0xFFF3A712), fontSize: 12)),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${appState.currency.symbol}${formatCurrency(calc.nisabThreshold, appState.language, decimalDigits: 0)}',
                                    style: const TextStyle(color: Color(0xFFF3A712), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Breakdown section title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isTr ? 'Varlıklarım' : 'My Assets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.displayLarge?.color)),
                    TextButton.icon(
                      onPressed: () {
                        AddAssetDialog.show(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF3A712).withValues(alpha: 0.1),
                        foregroundColor: const Color(0xFFF3A712),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(isTr ? 'Yeni Ekle' : 'Add New', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Assets List Card
                AppCard(
                  child: myAssets.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: appState.isDark ? Colors.white10 : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.post_add_rounded, color: Colors.grey.shade400, size: 32),
                              ),
                              const SizedBox(height: 16),
                              Text(isTr ? 'Henüz varlık eklenmedi.' : 'No assets added yet.', style: TextStyle(color: Colors.grey.shade500)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => AddAssetDialog.show(context),
                                child: Text(isTr ? 'Varlık Ekle' : 'Add Asset', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myAssets.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: appState.isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        itemBuilder: (context, index) {
                          final asset = myAssets[index];
                          final dynamicValue = CurrencyConstants.calculateDynamicAssetValueTRY(
                            asset: asset,
                            goldRate: calc.goldRate * calc.conversionRate,
                            silverRate: calc.silverRate * calc.conversionRate,
                            exchangeRates: rates,
                          ) / calc.conversionRate;

                          return AppAssetTile(
                            asset: asset,
                            dynamicValue: dynamicValue,
                            isDebt: false,
                            language: appState.language,
                            currencySymbol: appState.currency.symbol,
                            sect: appState.sect,
                            onEdit: () => AddAssetDialog.show(context, existingAsset: asset),
                            onDelete: () => _deleteAsset(context, asset, isTr),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 24),

                // Debts Card
                AppCard(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: appState.isDark ? AppColors.debtRedBgDark : AppColors.debtRedBgLight,
                          borderRadius: myDebts.isEmpty 
                            ? BorderRadius.circular(18)
                            : const BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.money_off_rounded, color: AppColors.debtRed, size: 20),
                                const SizedBox(width: 8),
                                Text(isTr ? 'Toplam Borçlar' : 'Total Debts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '- ${appState.currency.symbol}${formatCurrency(calc.totalDebts, appState.language)}',
                                  style: const TextStyle(color: AppColors.debtRed, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (myDebts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 24),
                          child: Text(isTr ? 'Borç kaydı bulunmuyor.' : 'No debts found.', style: TextStyle(color: Colors.grey.shade400)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: myDebts.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: appState.isDark ? AppColors.borderDark : Colors.red.shade50,
                          ),
                          itemBuilder: (context, index) {
                            final asset = myDebts[index];
                            final dynamicValue = CurrencyConstants.calculateDynamicAssetValueTRY(
                              asset: asset,
                              goldRate: calc.goldRate * calc.conversionRate,
                              silverRate: calc.silverRate * calc.conversionRate,
                              exchangeRates: rates,
                            ) / calc.conversionRate;

                            return AppAssetTile(
                              asset: asset,
                              dynamicValue: dynamicValue,
                              isDebt: true,
                              language: appState.language,
                              currencySymbol: appState.currency.symbol,
                              sect: appState.sect,
                              onEdit: () => AddAssetDialog.show(context, existingAsset: asset),
                              onDelete: () => _deleteAsset(context, asset, isTr),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info Footer Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF3A712),
                        Color(0xFFD97706),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFD97706).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isTr 
                            ? (appState.sect == Sect.hanefi || appState.sect == Sect.hanbeli
                                ? "Zekat hesaplaması, ${appState.sect.name.toUpperCase()} mezhebine uygun olarak mevcut varlıklarınızdan vadesi gelmiş borçlarınız düşüldükten sonra kalan net matrahın %2.5'i (1/40) üzerinden yapılmıştır."
                                : "Zekat hesaplaması, ${appState.sect.name.toUpperCase()} mezhebine uygun olarak elde mevcut zekata tabi varlıklar üzerinden doğrudan (borçlar düşülmeksizin) %2.5 (1/40) olarak yapılmıştır.")
                            : (appState.sect == Sect.hanefi || appState.sect == Sect.hanbeli
                                ? "Zakat calculation is based on 2.5% (1/40) of your net wealth after deducting due debts, according to the ${appState.sect.name.toUpperCase()} school."
                                : "Zakat calculation is based on 2.5% (1/40) directly on eligible assets without deducting debts, according to the ${appState.sect.name.toUpperCase()} school."),
                          style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

