import 'package:hive/hive.dart';
import 'enums.dart';

part 'app_state.g.dart';

@HiveType(typeId: 5)
class AppState extends HiveObject {
  @HiveField(0)
  Sect sect;

  @HiveField(1)
  AppCurrency currency;

  @HiveField(2)
  bool isDark;

  @HiveField(3)
  Language language;

  @HiveField(4)
  bool onboardingComplete;

  @HiveField(5)
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

