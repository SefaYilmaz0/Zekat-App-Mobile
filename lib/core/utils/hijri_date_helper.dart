import 'package:hijri/hijri_calendar.dart';
import '../domain/enums.dart';

class HijriDateHelper {
  /// Miladi -> Hicri dönüştürücü
  static HijriCalendar fromGregorian(DateTime date) {
    return HijriCalendar.fromDate(date);
  }

  /// Formatlı Hicri tarih string (örn: "12 Muharrem 1448 H")
  static String formatHijri(DateTime date, Language language) {
    final hijri = HijriCalendar.fromDate(date);
    final isTr = language == Language.tr;
    final months = isTr
        ? [
            'Muharrem',
            'Safer',
            'Rebiülevvel',
            'Rebiülahir',
            'Cemaziyelevvel',
            'Cemaziyelahir',
            'Recep',
            'Şaban',
            'Ramazan',
            'Şevval',
            'Zilkade',
            'Zilhicce'
          ]
        : [
            'Muharram',
            'Safar',
            'Rabi al-Awwal',
            'Rabi al-Thani',
            'Jumada al-Ula',
            'Jumada al-Thani',
            'Rajab',
            'Shaban',
            'Ramadan',
            'Shawwal',
            'Dhul Qadah',
            'Dhul Hijjah'
          ];

    final monthName = (hijri.hMonth >= 1 && hijri.hMonth <= 12)
        ? months[hijri.hMonth - 1]
        : '';

    return '${hijri.hDay} $monthName ${hijri.hYear} H';
  }

  /// Kısa format (örn: "Muharrem 1448")
  static String formatHijriMonthYear(DateTime date, Language language) {
    final hijri = HijriCalendar.fromDate(date);
    final isTr = language == Language.tr;
    final months = isTr
        ? [
            'Muharrem',
            'Safer',
            'Rebiülevvel',
            'Rebiülahir',
            'Cemaziyelevvel',
            'Cemaziyelahir',
            'Recep',
            'Şaban',
            'Ramazan',
            'Şevval',
            'Zilkade',
            'Zilhicce'
          ]
        : [
            'Muharram',
            'Safar',
            'Rabi al-Awwal',
            'Rabi al-Thani',
            'Jumada al-Ula',
            'Jumada al-Thani',
            'Rajab',
            'Shaban',
            'Ramadan',
            'Shawwal',
            'Dhul Qadah',
            'Dhul Hijjah'
          ];

    final monthName = (hijri.hMonth >= 1 && hijri.hMonth <= 12)
        ? months[hijri.hMonth - 1]
        : '';

    return '$monthName ${hijri.hYear}';
  }

  /// Seçilen ay ve güne göre bir sonraki Zekat yıl dönümünü (Miladi) döner.
  static DateTime? getNextZakatDate(int? hMonth, int? hDay) {
    if (hMonth == null || hDay == null) return null;
    try {
      final today = HijriCalendar.now();
      int targetYear = today.hYear;

      // Eğer seçilen tarih bu yıl için geçmişse, bir sonraki yıla at
      if (hMonth < today.hMonth || (hMonth == today.hMonth && hDay < today.hDay)) {
        targetYear++;
      }

      final targetHijri = HijriCalendar()
        ..hYear = targetYear
        ..hMonth = hMonth
        ..hDay = hDay;

      return targetHijri.hijriToGregorian(targetYear, hMonth, hDay);
    } catch (e) {
      return null;
    }
  }

  /// Kalan gün sayısını hesaplar
  static int? getDaysUntilNextZakat(int? hMonth, int? hDay) {
    final nextDate = getNextZakatDate(hMonth, hDay);
    if (nextDate == null) return null;
    
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final targetStart = DateTime(nextDate.year, nextDate.month, nextDate.day);
    
    return targetStart.difference(todayStart).inDays;
  }

  /// Ay adını getirir
  static String getHijriMonthName(int monthIndex, Language language) {
    final isTr = language == Language.tr;
    final months = isTr
        ? ['Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir', 'Cemaziyelevvel', 'Cemaziyelahir', 'Recep', 'Şaban', 'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce']
        : ['Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Jumada al-Ula', 'Jumada al-Thani', 'Rajab', 'Shaban', 'Ramadan', 'Shawwal', 'Dhul Qadah', 'Dhul Hijjah'];

    if (monthIndex >= 1 && monthIndex <= 12) {
      return months[monthIndex - 1];
    }
    return '';
  }
}
