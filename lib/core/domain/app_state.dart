import 'package:hive/hive.dart';
import 'enums.dart';

part 'app_state.g.dart';

@HiveType(typeId: 5)
class AppState extends HiveObject {
  @HiveField(0, defaultValue: Sect.hanefi)
  Sect sect;

  @HiveField(1, defaultValue: AppCurrency.tryCurrency)
  AppCurrency currency;

  @HiveField(2, defaultValue: false)
  bool isDark;

  @HiveField(3, defaultValue: Language.tr)
  Language language;

  @HiveField(4, defaultValue: false)
  bool onboardingComplete;

  @HiveField(5, defaultValue: NisabType.gold)
  NisabType nisabType;

  AppState({
    required this.sect,
    required this.currency,
    required this.isDark,
    required this.language,
    required this.onboardingComplete,
    required this.nisabType,
  });
}

