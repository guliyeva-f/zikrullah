import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/amal.dart';
import '../../domain/amal_record.dart';
import '../../data/amal_repository.dart';
import '../../../../core/notifications/notification_service.dart';

// ─── STATE ───────────────────────────────────────────────────────────────────

class AmalState {
  final List<Amal> amals;
  final Map<int, AmalRecord?> records;
  final Map<int, int> streaks;
  final Map<int, int> completedCounts;
  final String today;
  final List<Amal> recentlyArchived;
  final List<Amal> recentlyReset;

  const AmalState({
    required this.amals,
    required this.records,
    required this.streaks,
    required this.completedCounts,
    required this.today,
    this.recentlyArchived = const [],
    this.recentlyReset = const [],
  });

  int get totalCount => amals.length;
  int get completedCount =>
      records.values.where((r) => r?.isCompleted == true).length;
  bool get allCompleted => totalCount > 0 && completedCount == totalCount;

  AmalState copyWith({
    List<Amal>? amals,
    Map<int, AmalRecord?>? records,
    Map<int, int>? streaks,
    Map<int, int>? completedCounts,
    String? today,
    List<Amal>? recentlyArchived,
    List<Amal>? recentlyReset,
  }) => AmalState(
    amals: amals ?? this.amals,
    records: records ?? this.records,
    streaks: streaks ?? this.streaks,
    completedCounts: completedCounts ?? this.completedCounts,
    today: today ?? this.today,
    recentlyArchived: recentlyArchived ?? this.recentlyArchived,
    recentlyReset: recentlyReset ?? this.recentlyReset,
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
    final archived = await _repo.archiveCompletedAmals();
    final resetAmals = await _repo.processStrictBreaks();
    final broken = await _repo.getStreakBrokenAmals();
    if (broken.isNotEmpty) {
      await _notifService.scheduleReturnNotifications(
        broken.map((a) => a.title).toList(),
      );
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final amals = await _repo.getActiveAmals();

    final todayRecordsList = await _repo.getRecordsForDate(today);
    final todayRecordsMap = <int, AmalRecord>{
      for (final r in todayRecordsList) r.amalId: r,
    };

    final records = <int, AmalRecord?>{};
    final streaks = <int, int>{};
    final completedCounts = <int, int>{};

    await Future.wait(
      amals.map((amal) async {
        records[amal.id] = todayRecordsMap[amal.id];
        final streakFromDate = amal.durationDays != null
            ? amal.effectiveCycleStart.substring(0, 10)
            : null;
        streaks[amal.id] = await _repo.calculateStreak(
          amal.id,
          fromDate: streakFromDate,
        );
        final cycleStart = amal.effectiveCycleStart.substring(0, 10);
        completedCounts[amal.id] = await _repo.countCompletedDays(
          amal.id,
          fromDate: cycleStart,
        );
      }),
    );

    final incompleteTitles = amals
        .where((a) => !(todayRecordsMap[a.id]?.isCompleted ?? false))
        .map((a) => a.title)
        .toList();
    await _notifService.updateTodayProgress(incompleteTitles);

    return AmalState(
      amals: amals,
      records: records,
      streaks: streaks,
      completedCounts: completedCounts,
      today: today,
      recentlyArchived: archived,
      recentlyReset: resetAmals,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  void clearArchived() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(recentlyArchived: []));
  }

  void clearReset() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(recentlyReset: []));
  }

  // ─── TAMAMLAMA HƏRƏKƏTLƏRİ ───────────────────────────────────────────────

  Future<void> completeCheckbox(int amalId) async {
    final current = state.value;
    if (current == null) return;
    final today = current.today;
    final existing = current.records[amalId];
    final isCurrentlyDone = existing?.isCompleted ?? false;

    final amal = current.amals.firstWhere((a) => a.id == amalId);
    final isCounter = amal.type == AmalType.counter;
    final target = amal.countTarget ?? 1;
    final newCountDone = isCurrentlyDone
        ? (existing?.countDone ?? 0)
        : isCounter
        ? target
        : (existing?.countDone ?? 0);

    final record = AmalRecord(
      id: existing?.id,
      amalId: amalId,
      recordDate: today,
      isCompleted: !isCurrentlyDone,
      countDone: newCountDone,
      completedAt: !isCurrentlyDone ? DateTime.now().toIso8601String() : null,
    );
    await _repo.upsertRecord(record);
    await _patchRecord(amalId, record);
  }

  Future<void> incrementCounter(int amalId) => incrementCounterBy(amalId, 1);

  Future<void> decrementCounter(int amalId) => decrementCounterBy(amalId, 1);

  Future<void> incrementCounterBy(int amalId, int amount) async {
    final current = state.value;
    if (current == null) return;
    final amal = current.amals.firstWhere((a) => a.id == amalId);
    final existing = current.records[amalId];
    final newCount = (existing?.countDone ?? 0) + amount;
    final target = amal.countTarget ?? 1;
    final done = newCount >= target;

    final record = AmalRecord(
      id: existing?.id,
      amalId: amalId,
      recordDate: current.today,
      isCompleted: done,
      countDone: newCount,
      completedAt: done ? DateTime.now().toIso8601String() : null,
    );
    await _repo.upsertRecord(record);
    await _patchRecord(amalId, record);
  }

  Future<void> decrementCounterBy(int amalId, int amount) async {
    final current = state.value;
    if (current == null) return;
    final existing = current.records[amalId];
    final currentCount = existing?.countDone ?? 0;
    if (currentCount <= 0) return;

    final newCount = (currentCount - amount).clamp(0, currentCount);
    final amal = current.amals.firstWhere((a) => a.id == amalId);
    final target = amal.countTarget ?? 1;

    final record = AmalRecord(
      id: existing?.id,
      amalId: amalId,
      recordDate: current.today,
      isCompleted: newCount >= target,
      countDone: newCount,
      completedAt: newCount >= target ? existing?.completedAt : null,
    );
    await _repo.upsertRecord(record);
    await _patchRecord(amalId, record);
  }

  Future<void> _patchRecord(int amalId, AmalRecord record) async {
    final current = state.value;
    if (current == null) return;

    final newRecords = Map<int, AmalRecord?>.from(current.records)
      ..[amalId] = record;

    final amal = current.amals.firstWhere((a) => a.id == amalId);
    final streakFromDate = amal.durationDays != null
        ? amal.effectiveCycleStart.substring(0, 10)
        : null;
    final newStreak = await _repo.calculateStreak(
      amalId,
      fromDate: streakFromDate,
    );
    final newStreaks = Map<int, int>.from(current.streaks)
      ..[amalId] = newStreak;

    final cycleStart = amal.effectiveCycleStart.substring(0, 10);
    final newCompletedCount = await _repo.countCompletedDays(
      amalId,
      fromDate: cycleStart,
    );
    final newCompletedCounts = Map<int, int>.from(current.completedCounts)
      ..[amalId] = newCompletedCount;

    state = AsyncData(
      current.copyWith(
        records: newRecords,
        streaks: newStreaks,
        completedCounts: newCompletedCounts,
      ),
    );

    final updated = state.value;
    if (updated != null) {
      final incompleteTitles = updated.amals
          .where((a) => !(updated.records[a.id]?.isCompleted ?? false))
          .map((a) => a.title)
          .toList();
      await _notifService.updateTodayProgress(incompleteTitles);
    }
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

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
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(amals: reordered));
  }

  Future<void> reactivateAmal(int id) async {
    await _repo.reactivateAmal(id);
    await refresh();
  }
}

// ─── PROVIDER ────────────────────────────────────────────────────────────────

final amalProvider = AsyncNotifierProvider<AmalNotifier, AmalState>(
  AmalNotifier.new,
);
