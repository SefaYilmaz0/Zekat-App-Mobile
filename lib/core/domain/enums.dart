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
