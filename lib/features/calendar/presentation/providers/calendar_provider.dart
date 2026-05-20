import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../amal/domain/amal.dart';
import '../../../amal/domain/amal_record.dart';
import '../../../amal/data/amal_repository.dart';

// ─── DAY STATUS ──────────────────────────────────────────────────────────────

enum DayStatus { allDone, partial, noneDone, future, empty }

// ─── STATE ───────────────────────────────────────────────────────────────────

class CalendarState {
  final int year;
  final int month;
  final List<Amal> amals;
  final Map<String, List<AmalRecord>> recordsByDate;
  final String? selectedDate; // basılan gün

  const CalendarState({
    required this.year,
    required this.month,
    required this.amals,
    required this.recordsByDate,
    this.selectedDate,
  });

  int get totalAmals => amals.length;

  DayStatus statusForDate(String date) {
    final now = DateTime.now();
    final day = DateTime.parse(date);

    // Gələcək gün
    if (day.isAfter(DateTime(now.year, now.month, now.day))) {
      return DayStatus.future;
    }

    final dayRecords = recordsByDate[date] ?? [];
    if (dayRecords.isEmpty) return DayStatus.noneDone;

    final completedCount = dayRecords.where((r) => r.isCompleted).length;
    if (completedCount == 0) return DayStatus.noneDone;
    if (completedCount >= totalAmals) return DayStatus.allDone;
    return DayStatus.partial;
  }

  List<AmalRecord> recordsForSelected() {
    if (selectedDate == null) return [];
    return recordsByDate[selectedDate!] ?? [];
  }

  CalendarState copyWith({
    int? year,
    int? month,
    List<Amal>? amals,
    Map<String, List<AmalRecord>>? recordsByDate,
    String? selectedDate,
    bool clearSelected = false,
  }) =>
      CalendarState(
        year:          year          ?? this.year,
        month:         month         ?? this.month,
        amals:         amals         ?? this.amals,
        recordsByDate: recordsByDate ?? this.recordsByDate,
        selectedDate:  clearSelected ? null : (selectedDate ?? this.selectedDate),
      );
}

// ─── NOTIFIER ────────────────────────────────────────────────────────────────

class CalendarNotifier extends AsyncNotifier<CalendarState> {
  late final AmalRepository _repo;

  @override
  Future<CalendarState> build() async {
    _repo = AmalRepository();
    final now = DateTime.now();
    return _loadMonth(now.year, now.month);
  }

  Future<CalendarState> _loadMonth(int year, int month) async {
    final amals   = await _repo.getActiveAmals();
    final records = await _repo.getRecordsForMonth(year, month);

    final byDate = <String, List<AmalRecord>>{};
    for (final r in records) {
      (byDate[r.recordDate] ??= []).add(r);
    }

    return CalendarState(
      year: year, month: month,
      amals: amals,
      recordsByDate: byDate,
    );
  }

  Future<void> goToPreviousMonth() async {
    final current = state.value;
    if (current == null) return;

    int y = current.year;
    int m = current.month - 1;
    if (m < 1) { m = 12; y--; }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadMonth(y, m));
  }

  Future<void> goToNextMonth() async {
    final current = state.value;
    if (current == null) return;

    final now = DateTime.now();
    // Gələcək aya keçmək olmaz
    if (current.year == now.year && current.month >= now.month) return;

    int y = current.year;
    int m = current.month + 1;
    if (m > 12) { m = 1; y++; }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadMonth(y, m));
  }

  void selectDate(String date) {
    final current = state.value;
    if (current == null) return;
    // Eyni gün ikinci dəfə basılsa panel bağlanır
    final newSelected = current.selectedDate == date ? null : date;
    state = AsyncData(current.copyWith(selectedDate: newSelected));
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadMonth(current.year, current.month));
  }
}

// ─── PROVIDER ────────────────────────────────────────────────────────────────

final calendarProvider =
    AsyncNotifierProvider<CalendarNotifier, CalendarState>(CalendarNotifier.new);