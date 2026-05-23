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
  final String today;
  final List<Amal> recentlyArchived;

  const AmalState({
    required this.amals,
    required this.records,
    required this.streaks,
    required this.today,
    this.recentlyArchived = const [],
  });

  int get totalCount => amals.length;
  int get completedCount =>
      records.values.where((r) => r?.isCompleted == true).length;
  bool get allCompleted => totalCount > 0 && completedCount == totalCount;

  AmalState copyWith({
    List<Amal>? amals,
    Map<int, AmalRecord?>? records,
    Map<int, int>? streaks,
    String? today,
    List<Amal>? recentlyArchived,
  }) => AmalState(
    amals: amals ?? this.amals,
    records: records ?? this.records,
    streaks: streaks ?? this.streaks,
    today: today ?? this.today,
    recentlyArchived: recentlyArchived ?? this.recentlyArchived,
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

  /// BUG #5 DÜZƏLİŞİ:
  /// Əvvəlki kod hər əməl üçün ayrıca getRecord() çağırırdı → N əməl = N sorğu.
  /// Həll: getRecordsForDate(today) ilə bütün bu günün recordlarını TEK sorğuda alırıq.
  /// Streak hesabı hələ ayrı-ayrı (N sorğu) — bunun SQL-də batching-i çox
  /// mürəkkəbdir, amma record sorğusu N→1-ə endirildi.
  /// Nəticə: 2N+2 sorğu → N+3 sorğuya endirilib.
  Future<AmalState> _load() async {
    // Müddəti bitmiş əməlləri arxivlə
    final archived = await _repo.archiveExpiredAmals();

    final broken = await _repo.getStreakBrokenAmals();
    if (broken.isNotEmpty) {
      await _notifService.scheduleReturnNotifications(broken);
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final amals = await _repo.getActiveAmals();

    // FIX #5: bütün bu günün record-larını TEK sorğu ilə al
    final todayRecordsList = await _repo.getRecordsForDate(today);
    final todayRecordsMap = <int, AmalRecord>{
      for (final r in todayRecordsList) r.amalId: r,
    };

    final records = <int, AmalRecord?>{};
    final streaks = <int, int>{};
    for (final amal in amals) {
      records[amal.id] = todayRecordsMap[amal.id]; // map-dən O(1) lookup
      streaks[amal.id] = await _repo.calculateStreak(amal.id);
    }

    return AmalState(
      amals: amals,
      records: records,
      streaks: streaks,
      today: today,
      recentlyArchived: archived,
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

  // ─── TAMAMLAMA HƏRƏKƏTLƏRİ ───────────────────────────────────────────────

  Future<void> completeCheckbox(int amalId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final existing = state.value?.records[amalId];
    final record = AmalRecord(
      id: existing?.id,
      amalId: amalId,
      recordDate: today,
      isCompleted: true,
      completedAt: DateTime.now().toIso8601String(),
    );
    await _repo.upsertRecord(record);
    await _patchRecord(amalId, record);
  }

  /// BUG #9 DÜZƏLİŞİ:
  /// Əvvəlki kodda checkbox tamamlandıqdan sonra geri almaq mümkün deyildi.
  /// Həll: undoCheckbox() metodu əlavə edildi.
  /// UI-da: checkbox-a uzun basmaqla (long press) çağırılır.
  Future<void> undoCheckbox(int amalId) async {
    final current = state.value;
    if (current == null) return;
    final existing = current.records[amalId];
    // Əgər bu gün tamamlanmayıbsa, geri almağa ehtiyac yoxdur
    if (existing == null || !existing.isCompleted) return;

    final record = AmalRecord(
      id: existing.id,
      amalId: amalId,
      recordDate: current.today,
      isCompleted: false,
      countDone: 0,
      completedAt: null,
    );
    await _repo.upsertRecord(record);
    await _patchRecord(amalId, record);
  }

  Future<void> incrementCounter(int amalId) async {
    final current = state.value;
    if (current == null) return;

    final amal = current.amals.firstWhere((a) => a.id == amalId);
    final existing = current.records[amalId];
    final newCount = (existing?.countDone ?? 0) + 1;
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

  /// BUG #8 DÜZƏLİŞİ:
  /// Əvvəlki kodda counter-i artırdıqdan sonra azaltmaq mümkün deyildi.
  /// Həll: decrementCounter() metodu əlavə edildi.
  /// UI-da: sayğac düyməsinə uzun basmaqla (long press) çağırılır.
  Future<void> decrementCounter(int amalId) async {
    final current = state.value;
    if (current == null) return;

    final existing = current.records[amalId];
    final currentCount = existing?.countDone ?? 0;
    if (currentCount <= 0) return; // artıq 0-dadır, azaltmaq olmaz

    final newCount = currentCount - 1;
    final amal = current.amals.firstWhere((a) => a.id == amalId);
    final target = amal.countTarget ?? 1;

    final record = AmalRecord(
      id: existing?.id,
      amalId: amalId,
      recordDate: current.today,
      isCompleted: newCount >= target,
      countDone: newCount,
      // Tamamlama zamanı: əgər hələ hədəfə çatmayıbsa sıfırla
      completedAt: newCount >= target ? existing?.completedAt : null,
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

  Future<void> _patchRecord(int amalId, AmalRecord record) async {
    final current = state.value;
    if (current == null) return;

    final newRecords = Map<int, AmalRecord?>.from(current.records)
      ..[amalId] = record;
    final newStreak = await _repo.calculateStreak(amalId);
    final newStreaks = Map<int, int>.from(current.streaks)
      ..[amalId] = newStreak;
    final newState = current.copyWith(records: newRecords, streaks: newStreaks);

    state = AsyncData(newState);

    if (newState.allCompleted) {
      await _notifService.cancelTodayIfAllDone();
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
    state = AsyncData(state.value!.copyWith(amals: reordered));
  }
}

// ─── PROVIDER ────────────────────────────────────────────────────────────────

final amalProvider = AsyncNotifierProvider<AmalNotifier, AmalState>(
  AmalNotifier.new,
);
