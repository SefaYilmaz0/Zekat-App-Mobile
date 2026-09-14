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
  static const String _primaryVersionUrl =
      'https://raw.githubusercontent.com/SefaYilmaz0/Zekat-App-Mobile/master/version.json';
  static const String _fallbackVersionUrl =
      'https://zekatapp-17822178084.us-west1.run.app/version.json';
  static const String defaultPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.sefayilmaz.zekatapp.zekat_app_mobile';

  Future<VersionCheckResult?> checkVersion() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );

    Response<dynamic>? response;
    try {
      response = await dio.get(_primaryVersionUrl);
    } catch (_) {
      try {
        response = await dio.get(_fallbackVersionUrl);
      } catch (_) {
        return null;
      }
    }

    if (response.statusCode == 200 && response.data != null) {
      try {
        final Map<String, dynamic> data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        final minVersionCode = (data['min_version_code'] as num?)?.toInt() ?? 0;
        final latestVersionCode = (data['latest_version_code'] as num?)?.toInt() ?? 0;
        final forceUpdate = data['force_update'] as bool? ?? false;
        String updateUrl = (data['update_url'] as String?)?.trim() ?? '';
        if (updateUrl.isEmpty) {
          updateUrl = defaultPlayStoreUrl;
        }
        final messageTr = data['message_tr'] as String? ??
            'Yeni bir sürüm mevcut. Lütfen güncelleyin.';
        final messageEn = data['message_en'] as String? ??
            'A new version is available. Please update.';

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
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

