import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheckResult {
  final bool shouldUpdate;
  final bool isForce;
  final String updateUrl;
  final String messageTr;
  final String messageEn;

  VersionCheckResult({
    required this.shouldUpdate,
    required this.isForce,
    required this.updateUrl,
    required this.messageTr,
    required this.messageEn,
  });
}

class VersionCheckService {
  static const String _versionUrl = 'https://raw.githubusercontent.com/SefaYilmaz0/Zekat-App-Mobile/master/version.json';

  Future<VersionCheckResult?> checkVersion() async {
    try {
      final dio = Dio();
      final response = await dio.get(_versionUrl);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data is String 
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
            
        final minVersionCode = data['min_version_code'] as int;
        final latestVersionCode = data['latest_version_code'] as int;
        final forceUpdate = data['force_update'] as bool? ?? false;
        final updateUrl = data['update_url'] as String? ?? '';
        final messageTr = data['message_tr'] as String? ?? 'Yeni bir sürüm mevcut. Lütfen güncelleyin.';
        final messageEn = data['message_en'] as String? ?? 'A new version is available. Please update.';

        final packageInfo = await PackageInfo.fromPlatform();
        final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

        if (currentBuildNumber < minVersionCode) {
          return VersionCheckResult(
            shouldUpdate: true,
            isForce: true,
            updateUrl: updateUrl,
            messageTr: messageTr,
            messageEn: messageEn,
          );
        } else if (currentBuildNumber < latestVersionCode) {
          return VersionCheckResult(
            shouldUpdate: true,
            isForce: forceUpdate,
            updateUrl: updateUrl,
            messageTr: messageTr,
            messageEn: messageEn,
          );
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
