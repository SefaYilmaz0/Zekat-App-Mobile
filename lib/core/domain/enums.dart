import 'package:hive/hive.dart';

part 'enums.g.dart';

@HiveType(typeId: 2)
enum Language {
  @HiveField(0)
  tr,
  @HiveField(1)
  en,
}

@HiveType(typeId: 3)
enum Sect {
  @HiveField(0)
  hanefi,
  @HiveField(1)
  safi,
  @HiveField(2)
  maliki,
  @HiveField(3)
  hanbeli,
}

@HiveType(typeId: 4)
enum AppCurrency {
  @HiveField(0)
  tryCurrency,
  @HiveField(1)
  usd,
  @HiveField(2)
  eur,
}

extension AppCurrencyExtension on AppCurrency {
  String get symbol {
    switch (this) {
      case AppCurrency.tryCurrency:
        return '₺';
      case AppCurrency.usd:
        return '\$';
      case AppCurrency.eur:
        return '€';
    }
  }
}

@HiveType(typeId: 7)
enum NisabType {
  @HiveField(0)
  gold,
  @HiveField(1)
  silver,
}


