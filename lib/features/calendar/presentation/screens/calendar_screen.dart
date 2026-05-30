import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../amal/data/amal_repository.dart';
import '../../../amal/domain/amal.dart';
import '../../../amal/domain/amal_record.dart';

// ─── RƏNGLƏR ──────────────────────────────────────────────────────────────────

class _Cal {
  static const doneBg = Color(0xFF8B6F47);
  static const doneText = Colors.white;
  static const selectedBg = Color(0xFF5A8A5E);
  static const selectedText = Colors.white;
  static const todayBorder = Color(0xFF8B6F47);
  static const missedBg = Color(0xFFF5DADA);
  static const missedText = Color(0xFFC0594A);
  static const futureTxt = Color(0xFFCEC5BB);
}

// ─── PROVIDER ─────────────────────────────────────────────────────────────────

final _calendarDayProvider = FutureProvider.family<_DayData, String>((
  ref,
  dateStr,
) async {
  final repo = AmalRepository();
  final allAmals = await repo.getAllAmals();
  final amals = allAmals
      .where((a) => a.createdAt.substring(0, 10).compareTo(dateStr) <= 0)
      .toList();
  final records = await repo.getRecordsForDate(dateStr);
  final recordMap = {for (final r in records) r.amalId: r};
  return _DayData(amals: amals, recordMap: recordMap);
});

final _earliestAmalDateProvider = FutureProvider<DateTime?>((ref) async {
  final repo = AmalRepository();
  final amals = await repo.getAllAmals();
  if (amals.isEmpty) return null;
  final dates = amals.map((a) => a.createdAt.substring(0, 10)).toList()..sort();
  final parts = dates.first.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
});

// Ayın hansı günlərində əməl mövcud idi
final _amalCountProvider = FutureProvider.family<Map<String, int>, String>((
  ref,
  monthKey,
) async {
  final parts = monthKey.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final from = DateTime(year, month, 1);
  final to = DateTime(year, month + 1, 0);
  return AmalRepository().getAmalCountPerDay(from: from, to: to);
});

class _DayData {
  final List<Amal> amals;
  final Map<int, AmalRecord> recordMap;
  const _DayData({required this.amals, required this.recordMap});
}

// ─── SCREEN ───────────────────────────────────────────────────────────────────

class CalendarScreen extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final Map<String, double> heatmapData;

  const CalendarScreen({
    super.key,
    required this.initialDate,
    this.heatmapData = const {},
  });

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String get _monthKey =>
      '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}';

  void _prevMonth(DateTime? earliest) {
    final prev = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    if (earliest != null && prev.isBefore(earliest)) return;
    setState(() => _displayMonth = prev);
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    if (next.isAfter(DateTime(now.year, now.month, 1))) return;
    setState(() => _displayMonth = next);
  }

  bool _canGoNext() {
    final now = DateTime.now();
    final next = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    return !next.isAfter(DateTime(now.year, now.month, 1));
  }

  bool _canGoPrev(DateTime? earliest) {
    if (earliest == null) return false;
    final prev = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    return !prev.isBefore(earliest);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _fmt(_selectedDate);
    final dayAsync = ref.watch(_calendarDayProvider(dateStr));
    final earliestAsync = ref.watch(_earliestAmalDateProvider);
    final amalCountAsync = ref.watch(_amalCountProvider(_monthKey));
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final earliest = earliestAsync.when(
      data: (d) => d,
      loading: () => null,
      error: (_, _) => null,
    );
    final amalCount = amalCountAsync.when(
      data: (d) => d,
      loading: () => <String, int>{},
      error: (_, _) => <String, int>{},
    );

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Təqvim',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Ay naviqasiyası ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: _canGoPrev(earliest)
                      ? () => _prevMonth(earliest)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: _canGoPrev(earliest)
                      ? AppColors.accent
                      : AppColors.textHint,
                  iconSize: 28,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${AppConstants.months[_displayMonth.month - 1]} ${_displayMonth.year}',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _canGoNext() ? _nextMonth : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: _canGoNext() ? AppColors.accent : AppColors.textHint,
                  iconSize: 28,
                ),
              ],
            ),
          ),

          // ── Həftə başlıqları ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: ['B.e', 'Ç.a', 'Ç', 'C.a', 'C', 'Ş', 'B']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // ── Təqvim grid ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildGrid(todayNorm, amalCount),
          ),

          const SizedBox(height: 12),

          // ── Legend ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(_Cal.doneBg, 'Tamamlandı'),
              const SizedBox(width: 14),
              _legendItem(_Cal.missedBg, 'Buraxıldı'),
              const SizedBox(width: 14),
              _legendItem(_Cal.selectedBg, 'Seçili'),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.separator, height: 1),
          const SizedBox(height: 4),

          // ── Gün siyahısı ─────────────────────────────────────────────────
          Expanded(
            child: dayAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
              error: (_, _) => Center(
                child: Text(
                  'Məlumat yüklənmədi',
                  style: GoogleFonts.nunito(color: AppColors.textSecondary),
                ),
              ),
              data: (data) => _buildDayList(data, todayNorm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildGrid(DateTime todayNorm, Map<String, int> amalCount) {
    final firstDay = _displayMonth;
    final daysInMonth = DateTime(firstDay.year, firstDay.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final rows = ((startOffset + daysInMonth) / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final dayNum = row * 7 + col - startOffset + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }

            final date = DateTime(firstDay.year, firstDay.month, dayNum);
            final isFuture = date.isAfter(todayNorm);
            final isToday = date == todayNorm;
            final isSelected = date == _selectedDate;
            final dateStr = _fmt(date);
            final ratio = widget.heatmapData[dateStr];
            final hasAmals = amalCount.containsKey(dateStr);

            // Tam tamamlanmış: ratio == 1.0
            final isDone = !isFuture && ratio != null && ratio >= 1.0;
            // Əməl var idi amma heç biri edilməyib (keçmiş gün)
            final isMissed =
                !isFuture &&
                !isToday &&
                hasAmals &&
                (ratio == null || ratio == 0.0);
            // Qismən — ratio > 0 amma < 1
            final isPartial =
                !isFuture &&
                !isToday &&
                ratio != null &&
                ratio > 0.0 &&
                ratio < 1.0;

            Color? bgColor;
            Color textColor = AppColors.textPrimary;
            Border? border;

            if (isSelected) {
              bgColor = _Cal.selectedBg;
              textColor = _Cal.selectedText;
            } else if (isDone) {
              bgColor = _Cal.doneBg;
              textColor = _Cal.doneText;
            } else if (isMissed) {
              bgColor = _Cal.missedBg;
              textColor = _Cal.missedText;
            } else if (isPartial) {
              bgColor = AppColors.accentMuted.withValues(
                alpha: 0.35 + ratio * 0.4,
              );
            } else if (isToday) {
              border = Border.all(color: _Cal.todayBorder, width: 1.5);
            } else if (isFuture) {
              textColor = _Cal.futureTxt;
            }
            // Əməl olmayan keçmiş gün — şəffaf (ağ)

            return Expanded(
              child: GestureDetector(
                onTap: isFuture
                    ? null
                    : () => setState(() => _selectedDate = date),
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: border,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: isSelected || isToday || isDone
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildDayList(_DayData data, DateTime todayNorm) {
    if (data.amals.isEmpty) {
      return Center(
        child: Text(
          'Bu tarixdə heç bir əməl yox idi',
          style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textHint),
        ),
      );
    }

    final done = data.amals
        .where((a) => data.recordMap[a.id]?.isCompleted == true)
        .toList();
    final notDone = data.amals
        .where((a) => data.recordMap[a.id]?.isCompleted != true)
        .toList();
    final isToday = _selectedDate == todayNorm;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (notDone.isNotEmpty)
          ...notDone.map(
            (a) => _Tile(amal: a, isDone: false, isToday: isToday),
          ),
        if (done.isNotEmpty) ...[
          if (notDone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.separator)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'tamamlandı',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.separator)),
                ],
              ),
            ),
          ...done.map((a) => _Tile(amal: a, isDone: true, isToday: isToday)),
        ],
      ],
    );
  }
}

// ─── TILE ─────────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final Amal amal;
  final bool isDone;
  final bool isToday;

  const _Tile({
    required this.amal,
    required this.isDone,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;

    if (isDone) {
      icon = Icons.check_circle_outline_rounded;
      iconColor = _Cal.doneBg;
    } else if (isToday) {
      // Cari gün — sual işarəsi
      icon = Icons.help_outline_rounded;
      iconColor = AppColors.textHint;
    } else {
      // Buraxılmış keçmiş gün — x
      icon = Icons.cancel_outlined;
      iconColor = _Cal.missedText;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              amal.title,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
