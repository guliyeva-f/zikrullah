import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

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
    tz.setLocalLocation(tz.getLocation('Asia/Baku'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);

    await _androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<void> requestPermission() async {
    try {
      await _androidImpl?.requestNotificationsPermission();
      await _androidImpl?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('İcazə xətası: $e');
    }
  }

  Future<bool> _canUseExactAlarms() async {
    try {
      return await _androidImpl?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─── PREFERENCES ─────────────────────────────────────────────────────────

  Future<bool> isEnabled() async {
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

  Future<void> cancelTodayIfAllDone() async {
    try {
      await _plugin.cancelAll();
      if (!await isEnabled()) return;

      final morning = await getMorningTime();
      final noon = await getNoonTime();
      final evening = await getEveningTime();

      await _scheduleDailyFromTomorrow(
        id: 1,
        hour: morning.hour,
        minute: morning.minute,
        body: 'Günün əməlləri sənini gözləyir 🤲',
      );
      await _scheduleDailyFromTomorrow(
        id: 2,
        hour: noon.hour,
        minute: noon.minute,
        body: 'Əməllərini tamamlamağı unutma',
      );
      await _scheduleDailyFromTomorrow(
        id: 3,
        hour: evening.hour,
        minute: evening.minute,
        body: 'Günün hələ bitməyib',
      );

      if (await isNightEnabled()) {
        await _scheduleDailyFromTomorrow(
          id: 4,
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
        id: 1,
        hour: morning.hour,
        minute: morning.minute,
        body: 'Günün əməlləri sənini gözləyir 🤲',
      );
      await _scheduleDaily(
        id: 2,
        hour: noon.hour,
        minute: noon.minute,
        body: 'Əməllərini tamamlamağı unutma',
      );
      await _scheduleDaily(
        id: 3,
        hour: evening.hour,
        minute: evening.minute,
        body: 'Günün hələ bitməyib',
      );

      if (await isNightEnabled()) {
        await _scheduleDaily(
          id: 4,
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

      final mode = await _canUseExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.zonedSchedule(
        id: id,
        title: 'Şəxsi Əməllər',
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

      final mode = await _canUseExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.zonedSchedule(
        id: id,
        title: 'Şəxsi Əməllər',
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
    // Siyahı boşdursa bildirişi ləğv et
    if (amalTitles.isEmpty) {
      await _plugin.cancel(id: 5);
      return;
    }

    if (!await isEnabled()) return;

    try {
      final now = tz.TZDateTime.now(tz.local);

      // Gün ərzində yalnız bir dəfə planlaşdır — artıq keçibsə sabah
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

      final mode = await _canUseExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.zonedSchedule(
        id: 5,
        title: 'Şəxsi Əməllər',
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
}
