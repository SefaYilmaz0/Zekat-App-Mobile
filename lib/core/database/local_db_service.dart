import 'package:hive_flutter/hive_flutter.dart';

class LocalDbService {
  static Future<void> init() async {
    // Uygulama başlarken kullanılacak kutuları açıyoruz
    await Hive.openBox('assetsBox');
    await Hive.openBox('settingsBox');
  }

  // Pratik erişim için getter'lar
  static Box get assetsBox => Hive.box('assetsBox');
  static Box get settingsBox => Hive.box('settingsBox');
}
