import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'core/domain/enums.dart';
import 'core/domain/app_state.dart';
import 'core/providers/app_state_provider.dart';
import 'core/presentation/main_layout.dart';
import 'features/assets/domain/asset_model.dart';
import 'features/history/domain/history_model.dart';

import 'features/onboarding/presentation/welcome_screen.dart';
import 'features/onboarding/presentation/sect_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  await Hive.initFlutter();

  Hive.registerAdapter(AssetCategoryAdapter());
  Hive.registerAdapter(AssetModelAdapter());
  Hive.registerAdapter(LanguageAdapter());
  Hive.registerAdapter(SectAdapter());
  Hive.registerAdapter(AppCurrencyAdapter());
  Hive.registerAdapter(AppStateAdapter());
  Hive.registerAdapter(HistoryModelAdapter());

  await Hive.openBox<AppState>('appState');
  await Hive.openBox<AssetModel>('assets');
  await Hive.openBox<HistoryModel>('history');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: ZekatApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class ZekatApp extends ConsumerWidget {
  const ZekatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    final goRouter = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: appState.onboardingComplete ? '/summary' : '/',
      redirect: (context, state) {
        final isOnboardingRoute = state.matchedLocation == '/' || state.matchedLocation == '/sect-select';
        
        if (appState.onboardingComplete && isOnboardingRoute) {
          return '/summary';
        }
        
        if (!appState.onboardingComplete && !isOnboardingRoute) {
          return '/';
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/sect-select',
          builder: (context, state) => const SectSelectionScreen(),
        ),
        GoRoute(
          path: '/summary',
          builder: (context, state) => const MainLayout(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Zekat Hesaplama Aracı',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

