import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/database/local_db_service.dart';
import 'features/assets/domain/asset_model.dart';
import 'core/presentation/main_screen.dart';

void main() async {
  // Flutter binding başlatılması
  WidgetsFlutterBinding.ensureInitialized();

  // Hive başlatılması
  await Hive.initFlutter();
  
  // Hive adaptörlerinin kaydedilmesi (Bu dosya build_runner ile oluştu)
  Hive.registerAdapter(AssetTypeAdapter());
  Hive.registerAdapter(AssetModelAdapter());
  
  // Kutuların açılması
  await LocalDbService.init();

  runApp(
    // Riverpod State Yönetimi için ProviderScope sarıcısı
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zekat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
