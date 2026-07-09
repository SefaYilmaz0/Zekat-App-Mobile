import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/domain/app_state.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/hijri_date_helper.dart';
import '../../assets/domain/asset_model.dart';
import '../../calculator/domain/calculation_result.dart';

class PdfReportService {
  static Future<Uint8List> generateReport({
    required CalculationResult calc,
    required List<AssetModel> assets,
    required AppState appState,
    required bool isTr,
  }) async {
    final pdf = pw.Document();

    // Google Font'u asenkron olarak yükle (Türkçe karakter desteği için)
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final sym = appState.currency.symbol;
    final dateStr =
        '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';
    final hijriStr =
        HijriDateHelper.formatHijri(DateTime.now(), appState.language);
    final currencyName =
        appState.currency.name.toUpperCase().replaceAll('CURRENCY', '');

    final myAssets =
        assets.where((a) => a.category != AssetCategory.debt).toList();
    final myDebts =
        assets.where((a) => a.category == AssetCategory.debt).toList();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ZekatApp',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#F3A712'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      isTr ? 'Zekat Hesaplama Raporu' : 'Zakat Calculation Report',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '${isTr ? "Tarih" : "Date"}: $dateStr',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Hicri: $hijriStr',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            // Metadata / Config Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${isTr ? "Mezhep" : "Sect"}: ${appState.sect.name.toUpperCase()}',
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey800),
                ),
                pw.Text(
                  '${isTr ? "Nisab Türü" : "Nisab Type"}: ${appState.nisabType == NisabType.gold ? (isTr ? "Altın (80.18 gr)" : "Gold (80.18 gr)") : (isTr ? "Gümüş (595 gr)" : "Silver (595 gr)")}',
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey800),
                ),
                pw.Text(
                  '${isTr ? "Para Birimi" : "Currency"}: $currencyName ($sym)',
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey800),
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            // Hero Summary Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#2E3643'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        isTr ? 'TOPLAM ÖDENECEK ZEKAT' : 'TOTAL ZAKAT TO PAY',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '$sym${calc.isNisabReached ? formatCurrency(calc.zakatToPay, appState.language) : formatCurrency(0.0, appState.language)}',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#F3A712'),
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor(0, 0, 0, 0.2),
                      borderRadius:
                          pw.BorderRadius.all(pw.Radius.circular(12)),
                    ),
                    child: pw.Text(
                      calc.isNisabReached
                          ? (isTr ? 'NİSAB ÜSTÜNDE' : 'ABOVE NISAB')
                          : (isTr ? 'NİSABIN ALTINDA' : 'BELOW NISAB'),
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Calculations Table
            pw.Text(
              isTr ? 'HESAPLAMA DETAYLARI' : 'CALCULATION SUMMARY',
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _buildTableRow(
                    isTr ? 'Toplam Varlıklar' : 'Total Assets',
                    '$sym${formatCurrency(calc.totalAssets, appState.language)}',
                    false),
                _buildTableRow(
                    isTr ? 'Toplam Borçlar' : 'Total Debts',
                    '- $sym${formatCurrency(calc.totalDebts, appState.language)}',
                    false,
                    isNegative: true),
                _buildTableRow(
                    isTr ? 'Net Matrah (Zekata Tabi Miktar)' : 'Net Worth (Subject to Zakat)',
                    '$sym${formatCurrency(calc.netZakatableAmount, appState.language)}',
                    true),
                _buildTableRow(
                    isTr ? 'Nisab Eşiği' : 'Nisab Threshold',
                    '$sym${formatCurrency(calc.nisabThreshold, appState.language)}',
                    false),
              ],
            ),

            pw.SizedBox(height: 24),

            // Assets List Table
            if (myAssets.isNotEmpty) ...[
              pw.Text(
                isTr ? 'VARLIK LİSTESİ' : 'ASSETS LIST',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(isTr ? 'Varlık Adı' : 'Asset Name',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(isTr ? 'Kategori' : 'Category',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(isTr ? 'Değer' : 'Value',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  ...myAssets.map((asset) {
                    final isJewelryExempt =
                        (asset.category == AssetCategory.gold ||
                                asset.category == AssetCategory.silver) &&
                            asset.details?['isJewelry'] == true &&
                            appState.sect != Sect.hanefi;
                    final valueStr = isJewelryExempt
                        ? (isTr ? 'Muaf' : 'Exempt')
                        : '$sym${formatCurrency(asset.value / calc.conversionRate, appState.language)}';
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(asset.name,
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(asset.category.name.toUpperCase(),
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey700)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(valueStr,
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: isJewelryExempt
                                      ? PdfColors.grey500
                                      : PdfColors.black)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],

            pw.SizedBox(height: 24),

            // Debts List Table
            if (myDebts.isNotEmpty) ...[
              pw.Text(
                isTr ? 'BORÇ VE LİMİT LİSTESİ' : 'DEBTS & LIABILITIES LIST',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(5),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                            isTr ? 'Borç / Gider Tanımı' : 'Debt Description',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(isTr ? 'Tutar' : 'Amount',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  ...myDebts.map((debt) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(debt.name,
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              '- $sym${formatCurrency(debt.value / calc.conversionRate, appState.language)}',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red700)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],

            pw.SizedBox(height: 16),

            // Footer Section
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                isTr
                    ? 'Bu rapor ZekatApp uygulaması ile üretilmiştir. Kesin fetvalar için yetkili mercilere danışınız.'
                    : 'This report was generated with ZakatApp. Consult official authorities for final rulings.',
                style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(String label, String value, bool isBold,
      {bool isNegative = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: isNegative ? PdfColors.red700 : PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }
}
