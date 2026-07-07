import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:share_plus/share_plus.dart';
import '../../calculator/presentation/calculator_provider.dart';
import '../../assets/domain/asset_model.dart';
import '../../assets/presentation/widgets/add_asset_dialog.dart';
import '../../../core/theme.dart';

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
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
  IconData _getIconForCategory(AssetCategory category) {
    switch (category) {
      case AssetCategory.gold: return Icons.grid_goldenratio_rounded;
      case AssetCategory.cash: return Icons.payments_rounded;
      case AssetCategory.agriculture: return Icons.agriculture_rounded;
      case AssetCategory.livestock: return Icons.pets_rounded;
      case AssetCategory.receivable: return Icons.account_balance_rounded;
      case AssetCategory.debt: return Icons.money_off_rounded;
    }
  }

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(isTr ? 'Özet' : 'Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Theme.of(context).textTheme.displayLarge?.color)),
        centerTitle: true,
        actions: [
          if (calc != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              color: const Color(0xFFF3A712),
              onPressed: () {
                final text = isTr
                    ? 'ZekatApp ile hesaplanan Toplam Zekat Tutarı: ₺${calc.isNisabReached ? formatCurrency(calc.zakatToPay, appState.language) : formatCurrency(0.0, appState.language)}\nNisab Sınırı: ₺${formatCurrency(calc.nisabThreshold, appState.language, decimalDigits: 0)}\nNet Varlık: ₺${formatCurrency(calc.netZakatableAmount, appState.language, decimalDigits: 0)}'
                    : 'Total Zakat calculated with ZakatApp: ₺${calc.isNisabReached ? formatCurrency(calc.zakatToPay, appState.language) : formatCurrency(0.0, appState.language)}\nNisab Limit: ₺${formatCurrency(calc.nisabThreshold, appState.language, decimalDigits: 0)}\nNet Worth: ₺${formatCurrency(calc.netZakatableAmount, appState.language, decimalDigits: 0)}';
                Share.share(text);
              },
            )
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
                        color: Colors.black.withOpacity(0.1),
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
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₺${calc.isNisabReached ? formatCurrency(calc.zakatToPay, appState.language) : formatCurrency(0.0, appState.language)}',
                                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
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

                // Nisab Progress Card (White)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appState.isDark ? Colors.white10 : Colors.transparent),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(isTr ? 'Mevcut Net Varlık' : 'Net Worth', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                           Text('₺${formatCurrency(calc.netZakatableAmount, appState.language, decimalDigits: 0)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               Text(isTr ? 'Nisab Sınırı' : 'Nisab Limit', style: const TextStyle(color: Color(0xFFF3A712), fontSize: 12)),
                               Text('₺${formatCurrency(calc.nisabThreshold, appState.language, decimalDigits: 0)}', style: const TextStyle(color: Color(0xFFF3A712), fontWeight: FontWeight.bold)),
                            ],
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
                        showDialog(context: context, builder: (context) => const AddAssetDialog());
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF3A712).withOpacity(0.1),
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
                Container(
                  decoration: BoxDecoration(
                    color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appState.isDark ? Colors.white10 : Colors.transparent),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: myAssets.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                child: Icon(Icons.post_add_rounded, color: Colors.grey.shade400, size: 32),
                              ),
                              const SizedBox(height: 16),
                              Text(isTr ? 'Henüz varlık eklenmedi.' : 'No assets added yet.', style: TextStyle(color: Colors.grey.shade500)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => showDialog(context: context, builder: (context) => const AddAssetDialog()),
                                child: Text(isTr ? 'Varlık Ekle' : 'Add Asset', style: const TextStyle(color: Color(0xFFF3A712), fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: myAssets.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final asset = myAssets[index];
                          return ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3A712).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(_getIconForCategory(asset.category), color: const Color(0xFFF3A712), size: 20),
                            ),
                            title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                            subtitle: Text(asset.category.name.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                             Text('₺${formatCurrency(asset.value, appState.language)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 20),
                                  onPressed: () => _deleteAsset(context, asset, isTr),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 24),

                // Debts Card
                Container(
                  decoration: BoxDecoration(
                    color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appState.isDark ? Colors.white10 : Colors.transparent),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: appState.isDark ? const Color(0xFF3F1C1C) : const Color(0xFFFEF2F2),
                          borderRadius: myDebts.isEmpty 
                            ? BorderRadius.circular(16)
                            : const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.money_off_rounded, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(isTr ? 'Toplam Borçlar' : 'Total Debts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
                              ],
                            ),
                             Text('- ₺${formatCurrency(calc.totalDebts, appState.language)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      if (myDebts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Text(isTr ? 'Borç kaydı bulunmuyor.' : 'No debts found.', style: TextStyle(color: Colors.grey.shade400)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: myDebts.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.red.shade50),
                          itemBuilder: (context, index) {
                            final asset = myDebts[index];
                            return ListTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_getIconForCategory(asset.category), color: Colors.red, size: 20),
                              ),
                              title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   Text('- ₺${formatCurrency(asset.value, appState.language)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                                IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 20),
                                    onPressed: () => _deleteAsset(context, asset, isTr),
                                  ),
                                ],
                              ),
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
                      BoxShadow(color: const Color(0xFFD97706).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
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
                            ? "Zekat hesaplaması, mevcut varlıklarınızdan borçlarınız düşüldükten sonra kalan net varlığın %2.5'i (1/40) üzerinden yapılmıştır."
                            : "Zakat calculation is based on 2.5% (1/40) of your net wealth after deducting your debts from your assets.",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.5),
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
