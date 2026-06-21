import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:app_settings/app_settings.dart';

class _NotifIds {
  static const int morning = 1;
  static const int noon = 2;
  static const int evening = 3;
  static const int night = 4;
  static const int returnReminder = 5; 
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _keyEnabled = 'notif_enabled';
  static const _keyMorning = 'notif_morning';
  static const _keyNoon = 'notif_noon';
  static const _keyEvening = 'notif_evening';
  static const _keyNight = 'notif_night';

  static const _channelId = 'amal_channel';
  static const _channelName = 'Əməl Xatırlatmaları';
  static const _channelDesc = 'Gündəlik əməl xatırlatmaları';

  AndroidFlutterLocalNotificationsPlugin? get _androidImpl => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  // ─── INIT ────────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz_data.initializeTimeZones();

    final tzInfo = await FlutterTimezone.getLocalTimezone();

    try {
      tz.setLocalLocation(tz.getLocation(tzInfo.toString()));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Baku'));
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification clicked: ${response.payload}");
      },
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<bool> requestPermission() async {
    try {
      final granted =
          await _androidImpl?.requestNotificationsPermission() ?? false;
      if (granted) await _androidImpl?.requestExactAlarmsPermission();
      return granted;
    } catch (e) {
      debugPrint('İcazə xətası: $e');
      return false;
    }
  }

  Future<void> openSystemSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<bool> hasNotificationPermission() async {
    try {
      final granted = await _androidImpl?.areNotificationsEnabled() ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canScheduleExact() async {
    try {
      return await _androidImpl?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─── PREFERENCES ─────────────────────────────────────────────────────────

  Future<bool> isEnabled() async {
    final systemGranted = await hasNotificationPermission();
    if (!systemGranted) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    value ? await reschedule() : await _plugin.cancelAll();
  }

  Future<bool> isNightEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNight) ?? true;
  }

  Future<void> setNightEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNight, value);
    await reschedule();
  }

  Future<TimeOfDay> _getTime(String key, int defaultHour) async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(key) ?? defaultHour * 60;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  Future<void> _setTime(String key, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, time.hour * 60 + time.minute);
  }

  Future<TimeOfDay> getMorningTime() => _getTime(_keyMorning, 9);
  Future<TimeOfDay> getNoonTime() => _getTime(_keyNoon, 13);
  Future<TimeOfDay> getEveningTime() => _getTime(_keyEvening, 20);

  Future<void> setMorningTime(TimeOfDay t) async {
    await _setTime(_keyMorning, t);
    await reschedule();
  }

  Future<void> setNoonTime(TimeOfDay t) async {
    await _setTime(_keyNoon, t);
    await reschedule();
  }

  Future<void> setEveningTime(TimeOfDay t) async {
    await _setTime(_keyEvening, t);
    await reschedule();
  }

  // ─── SCHEDULE ────────────────────────────────────────────────────────────
  Future<void> _cancelDailyOnly() async {
    await _plugin.cancel(id: _NotifIds.morning);
    await _plugin.cancel(id: _NotifIds.noon);
    await _plugin.cancel(id: _NotifIds.evening);
    await _plugin.cancel(id: _NotifIds.night);
  }

  Future<void> cancelTodayIfAllDone() async {
    try {
      if (!await isEnabled()) return;
      await _cancelDailyOnly();

      final morning = await getMorningTime();
      final noon = await getNoonTime();
      final evening = await getEveningTime();

      await _scheduleDailyFromTomorrow(
        id: _NotifIds.morning,
        hour: morning.hour,
        minute: morning.minute,
        body: 'Günün əməlləri sənini gözləyir 🤲',
      );
      await _scheduleDailyFromTomorrow(
        id: _NotifIds.noon,
        hour: noon.hour,
        minute: noon.minute,
        body: 'Əməllərini tamamlamağı unutma',
      );
      await _scheduleDailyFromTomorrow(
        id: _NotifIds.evening,
        hour: evening.hour,
        minute: evening.minute,
        body: 'Günün hələ bitməyib',
      );

      if (await isNightEnabled()) {
        await _scheduleDailyFromTomorrow(
          id: _NotifIds.night,
          hour: 23,
          minute: 0,
          body: 'Günün bitmə vaxtı yaxınlaşır ⏳',
        );
      }
    } catch (e) {
      debugPrint('cancelTodayIfAllDone xətası: $e');
    }
  }

  Future<void> reschedule() async {
    try {
      await _plugin.cancelAll();
      if (!await isEnabled()) return;

      final morning = await getMorningTime();
      final noon = await getNoonTime();
      final evening = await getEveningTime();

      await _scheduleDaily(
        id: _NotifIds.morning,
        hour: morning.hour,
        minute: morning.minute,
        body: 'Günün əməlləri sənini gözləyir 🤲',
      );
      await _scheduleDaily(
        id: _NotifIds.noon,
        hour: noon.hour,
        minute: noon.minute,
        body: 'Əməllərini tamamlamağı unutma',
      );
      await _scheduleDaily(
        id: _NotifIds.evening,
        hour: evening.hour,
        minute: evening.minute,
        body: 'Günün hələ bitməyib',
      );

      if (await isNightEnabled()) {
        await _scheduleDaily(
          id: _NotifIds.night,
          hour: 23,
          minute: 0,
          body: 'Günün bitmə vaxtı yaxınlaşır ⏳',
        );
      }
    } catch (e) {
      debugPrint('Reschedule xətası: $e');
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String body,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final mode = await canScheduleExact()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.zonedSchedule(
        id: id,
        title: 'Zikrullah',
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Schedule xətası (id=$id): $e');
    }
  }

  Future<void> _scheduleDailyFromTomorrow({
    required int id,
    required int hour,
    required int minute,
    required String body,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);

      final scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).add(const Duration(days: 1));

      final mode = await canScheduleExact()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.zonedSchedule(
        id: id,
        title: 'Zikrullah',
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Schedule tomorrow xətası (id=$id): $e');
    }
  }

  // ─── GERİ QAYT BİLDİRİŞİ ─────────────────────────────────────────────────

  Future<void> scheduleReturnNotifications(List<String> amalTitles) async {
    if (amalTitles.isEmpty) {
      await _plugin.cancel(id: _NotifIds.returnReminder);
      return;
    }

    if (!await isEnabled()) return;

    try {
      final now = tz.TZDateTime.now(tz.local);

      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        10,
        0,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final body = amalTitles.length == 1
          ? '"${amalTitles.first}" əməlinə qayıt 🤲'
          : '${amalTitles.length} əməlin sənini gözləyir 🤲';

      final mode = await canScheduleExact()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.zonedSchedule(
        id: _NotifIds.returnReminder,
        title: 'Zikrullah',
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('scheduleReturnNotifications xətası: $e');
    }
  }

  // ─── ONBOARDING ──────────────────────────────────────────────────────────

  static const _keyNotifAsked = 'notif_onboarding_asked';

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyNotifAsked) ?? false);
  }

  Future<void> markNotifAsked({required bool granted}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifAsked, true);
    await prefs.setBool(_keyEnabled, granted);
    if (!granted) await _plugin.cancelAll();
  }
}
