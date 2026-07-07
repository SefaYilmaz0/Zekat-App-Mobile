import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/enums.dart';

String formatCurrency(double value, Language language, {int decimalDigits = 2}) {
  final settingsBox = Hive.box('settings');
  final formatSetting = settingsBox.get('currency_format', defaultValue: 'auto');

  String locale;
  if (formatSetting == 'tr') {
    locale = 'tr_TR';
  } else if (formatSetting == 'us') {
    locale = 'en_US';
  } else {
    locale = language == Language.tr ? 'tr_TR' : 'en_US';
  }

  final formatter = NumberFormat.currency(
    locale: locale,
    symbol: '',
    decimalDigits: decimalDigits,
  );
  
  return formatter.format(value).trim();
}
