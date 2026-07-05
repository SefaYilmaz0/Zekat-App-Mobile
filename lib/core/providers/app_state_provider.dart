import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/enums.dart';
import '../domain/app_state.dart';

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final box = Hive.box<AppState>('appState');
  AppState? state = box.get('current');
  if (state == null) {
    state = AppState(
      sect: Sect.hanefi,
      currency: AppCurrency.tryCurrency,
      isDark: false,
      language: Language.tr,
      onboardingComplete: false,
    );
    box.put('current', state);
  }
  return AppStateNotifier(state, box);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final Box<AppState> box;

  AppStateNotifier(super.state, this.box);

  void setLanguage(Language language) {
    state = AppState(
      sect: state.sect,
      currency: state.currency,
      isDark: state.isDark,
      language: language,
      onboardingComplete: state.onboardingComplete,
    );
    box.put('current', state);
  }

  void setSect(Sect sect) {
    state = AppState(
      sect: sect,
      currency: state.currency,
      isDark: state.isDark,
      language: state.language,
      onboardingComplete: state.onboardingComplete,
    );
    box.put('current', state);
  }

  void toggleTheme() {
    state = AppState(
      sect: state.sect,
      currency: state.currency,
      isDark: !state.isDark,
      language: state.language,
      onboardingComplete: state.onboardingComplete,
    );
    box.put('current', state);
  }

  void completeOnboarding() {
    state = AppState(
      sect: state.sect,
      currency: state.currency,
      isDark: state.isDark,
      language: state.language,
      onboardingComplete: true,
    );
    box.put('current', state);
  }
}
