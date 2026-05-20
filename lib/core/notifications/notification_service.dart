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
  static const _keyNoon    = 'notif_noon';
  static const _keyEvening = 'notif_evening';

  static const _channelId   = 'amal_channel';
  static const _channelName = 'Əməl Xatırlatmaları';
  static const _channelDesc = 'Gündəlik əməl xatırlatmaları';

  // ─── INIT ────────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Baku'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    // v21: 'settings' named parametr oldu
    await _plugin.initialize(settings: initSettings);

    // resolvePlatformSpecificImplementation<T> tək sətirdə yazılmalıdır
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<void> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
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
  Future<TimeOfDay> getNoonTime()    => _getTime(_keyNoon, 13);
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
    await _plugin.cancelAll();
  }

  Future<void> reschedule() async {
    await _plugin.cancelAll();
    if (!await isEnabled()) return;

    final morning = await getMorningTime();
    final noon    = await getNoonTime();
    final evening = await getEveningTime();

    await _scheduleDaily(id: 1, hour: morning.hour, minute: morning.minute,
        body: 'Günün əməlləri sənini gözləyir 🤲');
    await _scheduleDaily(id: 2, hour: noon.hour, minute: noon.minute,
        body: 'Əməllərini tamamlamağı unutma');
    await _scheduleDaily(id: 3, hour: evening.hour, minute: evening.minute,
        body: 'Günün hələ bitməyib');
    await _scheduleDaily(id: 4, hour: 23, minute: 0,
        body: 'Günün bitmə vaxtı yaxınlaşır ⏳');
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // v21: bütün parametrlər named oldu
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}