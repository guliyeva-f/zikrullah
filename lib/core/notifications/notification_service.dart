import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:convert';
import 'notification_context.dart';
import 'notification_engine.dart';
import 'notification_messages.dart';
class _NotifIds {
  static const int morningBase = 10; 
  static const int noonBase = 20; 
  static const int eveningBase = 30;
  static const int nightBase = 40;
  static const int seriesDays = 6;
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
  static const _channelId = 'zikrullah_channel';
  static const _channelName = 'Zikrullah Xatırlatmaları';
  static const _channelDesc = 'Gündəlik zikrullah xatırlatmaları';
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
    value ? await refreshTodayNotifications() : await _plugin.cancelAll();
  }
  Future<bool> isNightEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNight) ?? true;
  }
  Future<void> setNightEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNight, value);
    await refreshTodayNotifications();
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
    await refreshTodayNotifications();
  }
  Future<void> setNoonTime(TimeOfDay t) async {
    await _setTime(_keyNoon, t);
    await refreshTodayNotifications();
  }
  Future<void> setEveningTime(TimeOfDay t) async {
    await _setTime(_keyEvening, t);
    await refreshTodayNotifications();
  }
  // ─── SCHEDULE ────────────────────────────────────────────────────────────
  Future<void> _cancelDailyOnly() async {
    for (final base in [
      _NotifIds.morningBase,
      _NotifIds.noonBase,
      _NotifIds.eveningBase,
      _NotifIds.nightBase,
    ]) {
      for (var d = 0; d < _NotifIds.seriesDays; d++) {
        await _plugin.cancel(id: base + d);
      }
    }
  }
  // ─── KEŞLƏNMİŞ "BU GÜN NATAMAM ƏMƏLLƏR" ────────────────────────────────────
  static const _keyCachedSnapshots = 'notif_cached_snapshots';
  static const _keyCachedTotalCount = 'notif_cached_total_count';
  Future<void> _cacheSnapshots(
    List<AmalSnapshot> remaining,
    int totalCount,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyCachedSnapshots,
      jsonEncode(remaining.map((s) => s.toJson()).toList()),
    );
    await prefs.setInt(_keyCachedTotalCount, totalCount);
  }
  Future<(List<AmalSnapshot>, int)> _getCachedSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCachedSnapshots);
    final totalCount = prefs.getInt(_keyCachedTotalCount) ?? 0;
    if (raw == null) return (<AmalSnapshot>[], totalCount);
    try {
      final list = (jsonDecode(raw) as List)
          .map((m) => AmalSnapshot.fromJson(m as Map<String, dynamic>))
          .toList();
      return (list, totalCount);
    } catch (_) {
      return (<AmalSnapshot>[], totalCount);
    }
  }
  Future<void> updateTodayProgress(
    List<AmalSnapshot> remaining,
    int totalCount,
  ) async {
    await _cacheSnapshots(remaining, totalCount);
    await refreshTodayNotifications();
  }
  Future<void> refreshTodayNotifications() async {
    try {
      if (!await isEnabled()) return;
      await _cancelDailyOnly();
      final (remaining, totalCount) = await _getCachedSnapshots();
      final morning = await getMorningTime();
      final noon = await getNoonTime();
      final evening = await getEveningTime();
      final pushToTomorrow = totalCount == 0;
      final todayBody = <NotifSlot, String>{
        NotifSlot.morning: await _composeForSlot(
          NotifSlot.morning,
          remaining,
          totalCount,
        ),
        NotifSlot.noon: await _composeForSlot(
          NotifSlot.noon,
          remaining,
          totalCount,
        ),
        NotifSlot.evening: await _composeForSlot(
          NotifSlot.evening,
          remaining,
          totalCount,
        ),
        NotifSlot.night: await _composeForSlot(
          NotifSlot.night,
          remaining,
          totalCount,
        ),
      };
      await _scheduleSeries(
        baseId: _NotifIds.morningBase,
        slot: NotifSlot.morning,
        hour: morning.hour,
        minute: morning.minute,
        todayBody: todayBody[NotifSlot.morning]!,
        pushToTomorrow: pushToTomorrow,
      );
      await _scheduleSeries(
        baseId: _NotifIds.noonBase,
        slot: NotifSlot.noon,
        hour: noon.hour,
        minute: noon.minute,
        todayBody: todayBody[NotifSlot.noon]!,
        pushToTomorrow: pushToTomorrow,
      );
      await _scheduleSeries(
        baseId: _NotifIds.eveningBase,
        slot: NotifSlot.evening,
        hour: evening.hour,
        minute: evening.minute,
        todayBody: todayBody[NotifSlot.evening]!,
        pushToTomorrow: pushToTomorrow,
      );
      if (await isNightEnabled()) {
        await _scheduleSeries(
          baseId: _NotifIds.nightBase,
          slot: NotifSlot.night,
          hour: 23,
          minute: 0,
          todayBody: todayBody[NotifSlot.night]!,
          pushToTomorrow: pushToTomorrow,
        );
      }
    } catch (e) {
      debugPrint('refreshTodayNotifications xətası: $e');
    }
  }
  Future<String> _composeForSlot(
    NotifSlot slot,
    List<AmalSnapshot> remaining,
    int totalCount,
  ) async {
    final ctx = NotificationContext(
      slot: slot,
      remaining: remaining,
      totalCount: totalCount,
    );
    final pick = NotificationEngine.decide(ctx);
    return NotificationMessages.compose(pick, slot);
  }
  Future<void> _scheduleSeries({
    required int baseId,
    required NotifSlot slot,
    required int hour,
    required int minute,
    required String todayBody,
    required bool pushToTomorrow,
  }) async {
    try {
      final title = NotificationMessages.titleFor(slot);
      final now = tz.TZDateTime.now(tz.local);
      var anchor = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (anchor.isBefore(now)) {
        anchor = anchor.add(const Duration(days: 1));
      }
      if (pushToTomorrow) {
        anchor = anchor.add(const Duration(days: 1));
      }
      final mode = await canScheduleExact()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      for (var d = 0; d < _NotifIds.seriesDays; d++) {
        final body = d <= 1
            ? todayBody
            : await NotificationMessages.composeDecay(slot, d);
        await _plugin.zonedSchedule(
          id: baseId + d,
          title: title,
          body: body,
          scheduledDate: anchor.add(Duration(days: d)),
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
        );
      }
    } catch (e) {
      debugPrint('Schedule series xətası (baseId=$baseId): $e');
    }
  }
  // ─── GERİ QAYT BİLDİRİŞİ ─────────────────────────────────────────────────
  Future<void> scheduleReturnNotifications(
    List<String> amalTitles, {
    int inactiveDays = 1,
  }) async {
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
      final body = await NotificationMessages.composeReturn(inactiveDays);
      final mode = await canScheduleExact()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      await _plugin.zonedSchedule(
        id: _NotifIds.returnReminder,
        title: NotificationMessages.returnTitle,
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
