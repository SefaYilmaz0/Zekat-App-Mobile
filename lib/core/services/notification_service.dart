import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } catch (e) {
      debugPrint('NotificationService requestPermissions error: $e');
      return false;
    }
  }

  Future<void> showTestNotification({required bool isTr}) async {
    try {
      await initialize();
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'zakat_reminders_channel',
        'Zekat Hatırlatıcıları',
        channelDescription: 'Zekat yıl dönümü ve ibadet takibi hatırlatıcıları',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id: 999,
        title: isTr ? 'ZekatApp Bildirimleri Aktif 🌙' : 'ZakatApp Notifications Active 🌙',
        body: isTr
            ? 'Zekat yıl dönümünüz yaklaştığında size haber verilecektir.'
            : 'You will be notified when your zakat anniversary approaches.',
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('NotificationService showTestNotification error: $e');
    }
  }

  Future<void> scheduleZakatReminders({
    required int daysUntilAnniversary,
    required bool isTr,
  }) async {
    try {
      await initialize();
      await cancelAllReminders();

      if (daysUntilAnniversary <= 0) return;

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'zakat_reminders_channel',
        'Zekat Hatırlatıcıları',
        channelDescription: 'Zekat yıl dönümü ve ibadet takibi hatırlatıcıları',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);

      final now = tz.TZDateTime.now(tz.local);

      // 1. Yıldönümüne 30 gün kala hatırlatma
      if (daysUntilAnniversary > 30) {
        final scheduledDate = now.add(Duration(days: daysUntilAnniversary - 30));
        await _notificationsPlugin.zonedSchedule(
          id: 101,
          title: isTr ? 'Zekat Vaktinize 1 Ay Kaldı 🌙' : '1 Month Until Zakat Anniversary 🌙',
          body: isTr
              ? 'Hicri yıl dönümünüze 30 gün kaldı. Varlıklarınızı ve borçlarınızı gözden geçirebilirsiniz.'
              : '30 days left until your zakat anniversary. You can review your assets and debts.',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      // 2. Yıldönümüne 7 gün kala hatırlatma
      if (daysUntilAnniversary > 7) {
        final scheduledDate = now.add(Duration(days: daysUntilAnniversary - 7));
        await _notificationsPlugin.zonedSchedule(
          id: 102,
          title: isTr ? 'Zekat Vaktinize 1 Hafta Kaldı ⏳' : '1 Week Until Zakat Anniversary ⏳',
          body: isTr
              ? 'Zekat yıl dönümünüze 7 gün kaldı. ZekatApp ile güncel hesaplamanızı yapabilirsiniz.'
              : '7 days left until your zakat anniversary. You can calculate your zakat in ZakatApp.',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      // 3. Yıldönümü Gününde hatırlatma
      final anniversaryDate = now.add(Duration(days: daysUntilAnniversary));
      await _notificationsPlugin.zonedSchedule(
        id: 103,
        title: isTr ? 'Bugün Zekat Yıl Dönümünüz 🕋' : 'Today is Your Zakat Anniversary 🕋',
        body: isTr
            ? 'Bir hicri yılı doldurdunuz. Zekat ibadetinizi hesaplayıp ihtiyaç sahiplerine ulaştırma vakti.'
            : 'One full lunar year has elapsed. Time to calculate and fulfill your zakat duty.',
        scheduledDate: anniversaryDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('NotificationService scheduleZakatReminders error: $e');
    }
  }

  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancel(id: 101);
      await _notificationsPlugin.cancel(id: 102);
      await _notificationsPlugin.cancel(id: 103);
    } catch (e) {
      debugPrint('NotificationService cancelAllReminders error: $e');
    }
  }
}
