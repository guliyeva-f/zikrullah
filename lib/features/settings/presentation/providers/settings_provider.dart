import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ─── STATE ───────────────────────────────────────────────────────────────────
class SettingsState {
  final bool notificationsEnabled;
  final bool nightNotifEnabled;
  final TimeOfDay morningTime;
  final TimeOfDay noonTime;
  final TimeOfDay eveningTime;
  const SettingsState({
    required this.notificationsEnabled,
    required this.nightNotifEnabled,
    required this.morningTime,
    required this.noonTime,
    required this.eveningTime,
  });
  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? nightNotifEnabled,
    TimeOfDay? morningTime,
    TimeOfDay? noonTime,
    TimeOfDay? eveningTime,
  }) => SettingsState(
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    nightNotifEnabled: nightNotifEnabled ?? this.nightNotifEnabled,
    morningTime: morningTime ?? this.morningTime,
    noonTime: noonTime ?? this.noonTime,
    eveningTime: eveningTime ?? this.eveningTime,
  );
}
// ─── NOTIFIER ────────────────────────────────────────────────────────────────
class SettingsNotifier extends AsyncNotifier<SettingsState> {
  final _notifService = NotificationService();
  @override
  Future<SettingsState> build() async {
    return SettingsState(
      notificationsEnabled: await _notifService.isEnabled(),
      nightNotifEnabled: await _notifService.isNightEnabled(),
      morningTime: await _notifService.getMorningTime(),
      noonTime: await _notifService.getNoonTime(),
      eveningTime: await _notifService.getEveningTime(),
    );
  }
  Future<void> setNotificationsEnabled(bool value) async {
    await _notifService.setEnabled(value);
    state = AsyncData(state.value!.copyWith(notificationsEnabled: value));
  }
  Future<void> setNightEnabled(bool value) async {
    await _notifService.setNightEnabled(value);
    state = AsyncData(state.value!.copyWith(nightNotifEnabled: value));
  }
  Future<void> setMorningTime(TimeOfDay time) async {
    await _notifService.setMorningTime(time);
    state = AsyncData(state.value!.copyWith(morningTime: time));
  }
  Future<void> setNoonTime(TimeOfDay time) async {
    await _notifService.setNoonTime(time);
    state = AsyncData(state.value!.copyWith(noonTime: time));
  }
  Future<void> setEveningTime(TimeOfDay time) async {
    await _notifService.setEveningTime(time);
    state = AsyncData(state.value!.copyWith(eveningTime: time));
  }
}
// ─── PROVIDER ────────────────────────────────────────────────────────────────
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
final notifDeclinedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final asked = prefs.getBool('notif_onboarding_asked') ?? false;
  if (!asked) return false;
  final systemGranted = await NotificationService().hasNotificationPermission();
  final prefEnabled = prefs.getBool('notif_enabled') ?? true;
  return !systemGranted || !prefEnabled;
});
final counterHintProvider = FutureProvider.family<bool, int>((
  ref,
  amalId,
) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('counter_hint_$amalId') ?? false;
});
Future<void> markCounterHintShown(int amalId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('counter_hint_$amalId', true);
}
