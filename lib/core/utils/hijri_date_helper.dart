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
}
