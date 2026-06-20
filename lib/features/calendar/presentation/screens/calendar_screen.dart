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
  static const partialBg = Color(0xFFE8D5BC);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(_calendarDayProvider);
      ref.invalidate(_amalCountProvider);
    });
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String get _monthKey =>
      '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}';

  void _goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    ref.invalidate(_calendarDayProvider);
    setState(() {
      _selectedDate = today;
      _displayMonth = DateTime(today.year, today.month, 1);
    });
  }

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

  bool get _isOnToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _selectedDate == today;
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
          'təqvim',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (!_isOnToday)
            TextButton(
              onPressed: _goToToday,
              child: Text(
                'bu gün',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Ay naviqasiyası ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                _NavButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: _canGoPrev(earliest),
                  onTap: () => _prevMonth(earliest),
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
                _NavButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: _canGoNext(),
                  onTap: _nextMonth,
                ),
              ],
            ),
          ),

          // ── Həftə başlıqları ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: AppConstants.weekdaysShort
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

          const SizedBox(height: 14),

          // ── Legend ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: _Cal.doneBg, label: 'tamamlandı'),
                const SizedBox(width: 14),
                _LegendItem(color: _Cal.partialBg, label: 'qismən'),
                const SizedBox(width: 14),
                _LegendItem(color: _Cal.missedBg, label: 'buraxıldı'),
                const SizedBox(width: 14),
                _LegendItem(color: _Cal.selectedBg, label: 'seçili'),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.separator, height: 1),

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.textHint,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Məlumat açılmadı',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              data: (data) => _buildDayList(data, todayNorm),
            ),
          ),
        ],
      ),
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

            final isDone = !isFuture && ratio != null && ratio >= 1.0;
            final isMissed =
                !isFuture &&
                !isToday &&
                hasAmals &&
                (ratio == null || ratio == 0.0);
            final isPartial =
                !isFuture &&
                !isToday &&
                ratio != null &&
                ratio > 0.0 &&
                ratio < 1.0;

            Color? bgColor;
            Color textColor = AppColors.textPrimary;
            Border? border;

            if (isSelected && !isDone) {
              bgColor = _Cal.selectedBg;
              textColor = _Cal.selectedText;
            } else if (isDone) {
              bgColor = _Cal.doneBg;
              textColor = isSelected ? Colors.white : _Cal.doneText;
              if (isSelected) {
                border = Border.all(color: _Cal.selectedBg, width: 2);
              }
            } else if (isMissed) {
              bgColor = _Cal.missedBg;
              textColor = _Cal.missedText;
            } else if (isPartial) {
              bgColor = _Cal.partialBg;
              textColor = AppColors.accent;
            } else if (isToday) {
              border = Border.all(color: _Cal.todayBorder, width: 1.5);
            } else if (isFuture) {
              textColor = _Cal.futureTxt;
            }

            return Expanded(
              child: GestureDetector(
                onTap: isFuture
                    ? null
                    : () {
                        ref.invalidate(_calendarDayProvider);
                        setState(() => _selectedDate = date);
                      },
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
    final isToday = _selectedDate == todayNorm;
    final isPast = _selectedDate.isBefore(todayNorm);

    if (data.amals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✦',
              style: TextStyle(fontSize: 20, color: AppColors.accentMuted),
            ),
            const SizedBox(height: 12),
            Text(
              'Bu tarixdə heç bir əməl yox idi',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final done = data.amals
        .where((a) => data.recordMap[a.id]?.isCompleted == true)
        .toList();
    final notDone = data.amals
        .where((a) => data.recordMap[a.id]?.isCompleted != true)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        if (notDone.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              isToday
                  ? 'gözlənilir'
                  : (isPast ? 'yerinə yetirilmədi' : 'gözlənilir'),
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...notDone.map(
            (a) => _Tile(amal: a, isDone: false, isToday: isToday),
          ),
        ],
        if (done.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(
              top: notDone.isNotEmpty ? 14 : 0,
              bottom: 10,
            ),
            child: notDone.isNotEmpty
                ? Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.separator),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'yerinə yetirildi',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.separator),
                      ),
                    ],
                  )
                : Text(
                    'yerinə yetirildi',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
          ...done.map((a) => _Tile(amal: a, isDone: true, isToday: isToday)),
        ],
      ],
    );
  }
}

// ─── NAV BUTTON ──────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 28,
          color: enabled ? AppColors.accent : AppColors.textHint,
        ),
      ),
    );
  }
}

// ─── LEGEND ITEM ─────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
      iconColor = AppColors.accent;
    } else if (isToday) {
      icon = Icons.radio_button_unchecked_rounded;
      iconColor = AppColors.textHint;
    } else {
      icon = Icons.remove_circle_outline_rounded;
      iconColor = _Cal.missedText.withValues(alpha: 0.7);
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
                color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
