import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/notification_service.dart';

// ─── STATE ───────────────────────────────────────────────────────────────────

class SettingsState {
  final bool notificationsEnabled;
  final TimeOfDay morningTime;
  final TimeOfDay noonTime;
  final TimeOfDay eveningTime;

  const SettingsState({
    required this.notificationsEnabled,
    required this.morningTime,
    required this.noonTime,
    required this.eveningTime,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    TimeOfDay? morningTime,
    TimeOfDay? noonTime,
    TimeOfDay? eveningTime,
  }) =>
      SettingsState(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        morningTime:          morningTime          ?? this.morningTime,
        noonTime:             noonTime             ?? this.noonTime,
        eveningTime:          eveningTime          ?? this.eveningTime,
      );
}

// ─── NOTIFIER ────────────────────────────────────────────────────────────────

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  final _notifService = NotificationService();

  @override
  Future<SettingsState> build() async {
    return SettingsState(
      notificationsEnabled: await _notifService.isEnabled(),
      morningTime:          await _notifService.getMorningTime(),
      noonTime:             await _notifService.getNoonTime(),
      eveningTime:          await _notifService.getEveningTime(),
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _notifService.setEnabled(value);
    state = AsyncData(state.value!.copyWith(notificationsEnabled: value));
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

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);