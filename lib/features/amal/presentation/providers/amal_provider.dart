import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/amal.dart';
import '../../domain/amal_record.dart';
import '../../data/amal_repository.dart';
import '../../../../core/notifications/notification_service.dart';

// ─── STATE ───────────────────────────────────────────────────────────────────

class AmalState {
  final List<Amal> amals;
  final Map<int, AmalRecord?> records; // amalId → bu günkü record
  final Map<int, int> streaks;         // amalId → streak günü
  final String today;

  const AmalState({
    required this.amals,
    required this.records,
    required this.streaks,
    required this.today,
  });

  int get totalCount     => amals.length;
  int get completedCount => records.values.where((r) => r?.isCompleted == true).length;
  bool get allCompleted  => totalCount > 0 && completedCount == totalCount;

  AmalState copyWith({
    List<Amal>? amals,
    Map<int, AmalRecord?>? records,
    Map<int, int>? streaks,
    String? today,
  }) =>
      AmalState(
        amals:   amals   ?? this.amals,
        records: records ?? this.records,
        streaks: streaks ?? this.streaks,
        today:   today   ?? this.today,
      );
}

// ─── NOTIFIER ────────────────────────────────────────────────────────────────

class AmalNotifier extends AsyncNotifier<AmalState> {
  late final AmalRepository _repo;
  final _notifService = NotificationService();

  @override
  Future<AmalState> build() async {
    _repo = AmalRepository();
    return _load();
  }

  Future<AmalState> _load() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final amals = await _repo.getActiveAmals();

    final records = <int, AmalRecord?>{};
    final streaks = <int, int>{};
    for (final amal in amals) {
      records[amal.id] = await _repo.getRecord(amal.id, today);
      streaks[amal.id] = await _repo.calculateStreak(amal.id);
    }

    return AmalState(
      amals: amals, records: records, streaks: streaks, today: today,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  // ─── TAMAMLAMA HƏRƏKƏTLƏRİ ───────────────────────────────────────────────

  Future<void> completeCheckbox(int amalId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final record = AmalRecord(
      amalId: amalId,
      recordDate: today,
      isCompleted: true,
      completedAt: DateTime.now().toIso8601String(),
    );
    await _repo.upsertRecord(record);
    await _patchRecord(amalId, record);
  }

  Future<void> incrementCounter(int amalId) async {
    final current = state.value;
    if (current == null) return;

    final amal      = current.amals.firstWhere((a) => a.id == amalId);
    final existing  = current.records[amalId];
    final newCount  = (existing?.countDone ?? 0) + 1;
    final target    = amal.countTarget ?? 1;
    final completed = newCount >= target;

    final record = AmalRecord(
      id:          existing?.id,
      amalId:      amalId,
      recordDate:  current.today,
      isCompleted: completed,
      countDone:   newCount,
      completedAt: completed ? DateTime.now().toIso8601String() : null,
    );
    await _repo.upsertRecord(record);
    await _patchRecord(amalId, record);
  }

  Future<void> completeText(int amalId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final record = AmalRecord(
      amalId: amalId,
      recordDate: today,
      isCompleted: true,
      completedAt: DateTime.now().toIso8601String(),
    );
    await _repo.upsertRecord(record);
    await _patchRecord(amalId, record);
  }

  /// Yalnız dəyişən amalı yeniləyir — bütün state-i yenidən yükləmir
  Future<void> _patchRecord(int amalId, AmalRecord record) async {
    final current = state.value;
    if (current == null) return;

    final newRecords = Map<int, AmalRecord?>.from(current.records)..[amalId] = record;
    final newStreak  = await _repo.calculateStreak(amalId);
    final newStreaks  = Map<int, int>.from(current.streaks)..[amalId] = newStreak;
    final newState   = current.copyWith(records: newRecords, streaks: newStreaks);

    state = AsyncData(newState);

    // Hamısı tamamlandısa bildirişləri ləğv et
    if (newState.allCompleted) {
      await _notifService.cancelTodayIfAllDone();
    }
  }

  // ─── CRUD (ManageScreen üçün) ─────────────────────────────────────────────

  Future<void> addAmal(Amal amal) async {
    await _repo.insertAmal(amal);
    await refresh();
  }

  Future<void> updateAmal(Amal amal) async {
    await _repo.updateAmal(amal);
    await refresh();
  }

  Future<void> deleteAmal(int id) async {
    await _repo.deleteAmal(id);
    await refresh();
  }

  Future<void> updateSortOrders(List<Amal> reordered) async {
    await _repo.updateSortOrders(reordered);
    state = AsyncData(state.value!.copyWith(amals: reordered));
  }
}

// ─── PROVIDER ────────────────────────────────────────────────────────────────

final amalProvider =
    AsyncNotifierProvider<AmalNotifier, AmalState>(AmalNotifier.new);