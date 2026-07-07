import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/enums.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme.dart';

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> {
  void _showGuideDetail(BuildContext context, String title, String content, bool isTr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color))),
            IconButton(
              icon: Icon(Icons.close_rounded, color: Theme.of(context).iconTheme.color),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...content.split('\n').map((line) {
                  final trimmed = line.trim();
                  if (trimmed.startsWith('###')) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        trimmed.replaceFirst('###', '').trim(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
                      ),
                    );
                  } else if (trimmed.startsWith('*') || trimmed.startsWith('-') || trimmed.startsWith('•')) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                          Expanded(
                            child: Text(
                              trimmed.replaceFirst(RegExp(r'^[\*\-•]\s*'), '').trim(),
                              style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (trimmed.isEmpty) {
                    return const SizedBox(height: 8);
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        trimmed,
                        style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
                      ),
                    );
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(isTr ? 'Rehber' : 'Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Theme.of(context).textTheme.displayLarge?.color)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildGuideCard(
            context,
            icon: Icons.scale_rounded,
            title: isTr ? 'Nisab Nedir?' : 'What is Nisab?',
            description: isTr 
              ? 'Zenginlik ölçüsü ve zekatın farz olması için gereken asgari tutar hakkında temel bilgiler.'
              : 'Basic information about the measure of wealth and the minimum amount required for zakat to be obligatory.',
            content: isTr
              ? "### Nisab Nedir?\n\nNisab, zekatın farz olması için bir Müslümanın sahip olması gereken asgari zenginlik ölçüsüdür. Temel ihtiyaçlar ve borçlar düşüldükten sonra eldeki varlıkların bu sınıra ulaşması gerekir.\n\n### Nisab Miktarı Ne Kadardır?\n\nHz. Peygamber (s.a.s.) döneminde nisab miktarları şu şekilde belirlenmiştir:\n\n* Altın: 80.18 gram\n* Hayvanlar: 40 koyun/keçi, 30 sığır, 5 deve\n* Tarım Ürünleri: 650 kg\n\n### Yıllanma (Havl-i Havelin)\n\nNisab miktarına ulaşan malın üzerinden bir kameri yıl (354 gün) geçmesi gerekir. Yıl başında ve yıl sonunda nisab miktarı korunuyorsa zekat farz olur."
              : "### What is Nisab?\n\nNisab is the minimum amount of wealth that a Muslim must possess before they become eligible to pay Zakat. This is calculated after deducting basic needs and debts.\n\n### What is the Nisab Amount?\n\nDuring the time of the Prophet, Nisab was set at:\n\n* Gold: 80.18 grams\n* Animals: 40 sheep/goats, 30 cattle, 5 camels\n* Agriculture: 650 kg\n\n### One Year Rule (Hawl)\n\nYou must hold the Nisab amount of wealth for one full lunar year (354 days) before Zakat becomes due.",
            isTr: isTr,
          ),
          const SizedBox(height: 16),
          _buildGuideCard(
            context,
            icon: Icons.volunteer_activism_rounded,
            title: isTr ? 'Zekat Kimlere Verilir?' : 'Who Receives Zakat?',
            description: isTr
              ? 'Kur\'an-ı Kerim\'de belirtilen zekat verilebilecek 8 sınıfın detayı.'
              : 'Detailed explanation of the 8 classes eligible to receive Zakat.',
            content: isTr
              ? "### Zekat Kimlere Verilir?\n\nTevbe Suresi 60. ayetine göre zekat şu kişilere verilebilir:\n\n* Fakirler ve Miskinler (ihtiyaç sahipleri)\n* Borçlular (borcunu ödeyemeyenler)\n* Allah yolunda olanlar (ilim talebeleri, hayır işi yapanlar)\n* Yolda kalmış yolcular\n\n### Kimlere Zekat Verilmez?\n\n* Anne, baba, büyükbaba, büyükanne\n* Çocuklar ve torunlar\n* Eşler (birbirine zekat veremez)\n* Zengin kimseler"
              : "### Who Receives Zakat?\n\nAccording to Surah At-Tawbah (verse 60), Zakat can be given to:\n\n* The poor and needy\n* Debtors in distress\n* Those striving in the way of Allah (students, community helpers)\n* Wayfarers/travelers stranded without funds\n\n### Who Cannot Receive Zakat?\n\n* Parents and grandparents\n* Children and grandchildren\n* Husband or wife (spouses to each other)\n* Wealthy individuals",
            isTr: isTr,
          ),
          const SizedBox(height: 16),
          _buildGuideCard(
            context,
            icon: Icons.account_balance_wallet_rounded,
            title: isTr ? 'Hangi Varlıklar Tabidir?' : 'Which Assets are Subject?',
            description: isTr
              ? 'Zekata tabi olan altın, nakit, ticaret malları ve diğer varlıklar.'
              : 'Gold, cash, commercial goods and other assets subject to Zakat.',
            content: isTr
              ? "### Zekata Tabi Varlıklar\n\n* Altın ve Gümüş: Süs eşyası dahil nisaba ulaşan altın ve gümüş tabidir.\n* Nakit Para: Bankadaki mevduat, nakit ve döviz birikimleri tabidir.\n* Ticaret Malları: Satış amacıyla elde tutulan her türlü mal tabidir.\n* Hayvanlar: Belirli sayının üzerindeki koyun, keçi, sığır ve develer tabidir.\n* Tarım Ürünleri: Topraktan elde edilen ürünler (Öşür) tabidir."
              : "### Assets Subject to Zakat\n\n* Gold & Silver: All jewelry and savings meeting Nisab are subject.\n* Cash: Money in bank accounts, cash savings, and foreign currencies.\n* Business Assets: Any goods bought/held for resale or commerce.\n* Livestock: Sheep, goats, cattle, and camels exceeding specific limits.\n* Agriculture: Produce harvested from the earth (Ushr).",
            isTr: isTr,
          ),
          const SizedBox(height: 16),
          _buildGuideCard(
            context,
            icon: Icons.calculate_rounded,
            title: isTr ? 'Hesaplama Yöntemleri' : 'Calculation Methods',
            description: isTr
              ? 'Farklı varlıklar için zekat oranları (%2.5, %10, %5).'
              : 'Zakat rates for various assets (2.5%, 10%, 5%).',
            content: isTr
              ? "### Zekat Oranları\n\n* Nakit, Altın, Ticaret Malları: Net değerin %2.5'i (kırkta biri) verilir.\n* Tarım Ürünleri (Öşür): Masrafsız sulanan ürünlerde %10, yapay/masraflı sulanan ürünlerde %5 verilir.\n* Hayvancılık: Koyun/keçide 40 adette 1 koyun; sığırda 30 adette 1 buzağı verilir.\n\n### Genel Formül\n\n(Toplam Varlıklar - Borçlar) * %2.5 = Ödenecek Zekat"
              : "### Zakat Rates\n\n* Cash, Gold, Business Goods: 2.5% (1/40) of the net value.\n* Agriculture (Ushr): 10% for naturally watered crops, 5% for artificially irrigated crops.\n* Livestock: 1 sheep per 40 sheep/goats; 1 calf per 30 cattle.\n\n### General Formula\n\n(Total Assets - Debts) * 2.5% = Zakat Due",
            isTr: isTr,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context, {required IconData icon, required String title, required String description, required String content, required bool isTr}) {
    final appState = ref.read(appStateProvider);
    return InkWell(
      onTap: () => _showGuideDetail(context, title, content, isTr),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: appState.isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: appState.isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color))),
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(isTr ? 'Okumaya başla' : 'Start reading', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: Theme.of(context).primaryColor, size: 16),
              ],
            )
          ],
        ),
      ),
    );
  }
}

