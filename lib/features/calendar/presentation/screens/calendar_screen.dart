import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../amal/domain/amal.dart';
import '../../../amal/domain/amal_record.dart';
import '../providers/calendar_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const _months = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'İyun',
    'İyul', 'Avqust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
  ];

  // Həftə Bazar ertəsindən başlayır (Monday-first)
  static const _weekHeaders = ['BE', 'ÇA', 'Ç', 'CA', 'C', 'Ş', 'B'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(calendarProvider);

    return SafeArea(
      child: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(child: Text('Xəta: $e')),
        data: (state) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tarixçə',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildMonthNav(ref, state),
              const SizedBox(height: 14),
              _buildWeekHeaders(),
              const SizedBox(height: 6),
              _buildGrid(ref, state),
              const SizedBox(height: 16),
              _buildLegend(),
              if (state.selectedDate != null) ...[
                const SizedBox(height: 16),
                _buildDayPanel(state),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── AY NAVİGASİYASI ─────────────────────────────────────────────────────

  Widget _buildMonthNav(WidgetRef ref, CalendarState state) {
    final now = DateTime.now();
    final isCurrentMonth =
        state.year == now.year && state.month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          onPressed: () =>
              ref.read(calendarProvider.notifier).goToPreviousMonth(),
        ),
        SizedBox(
          width: 160,
          child: Text(
            '${_months[state.month - 1]} ${state.year}',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: isCurrentMonth
                ? AppColors.textHint
                : AppColors.textPrimary,
          ),
          onPressed: isCurrentMonth
              ? null
              : () =>
                  ref.read(calendarProvider.notifier).goToNextMonth(),
        ),
      ],
    );
  }

  // ─── HƏFTƏ BAŞLIQLAR ─────────────────────────────────────────────────────

  Widget _buildWeekHeaders() {
    return Row(
      children: _weekHeaders
          .map((h) => Expanded(
                child: Center(
                  child: Text(
                    h,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ─── TƏQVİM GRİD ─────────────────────────────────────────────────────────

  Widget _buildGrid(WidgetRef ref, CalendarState state) {
    final firstDay     = DateTime(state.year, state.month, 1);
    final leadingEmpty = (firstDay.weekday - 1) % 7; // Mon=0, Sun=6
    final daysInMonth  = DateTime(state.year, state.month + 1, 0).day;
    final totalCells   = leadingEmpty + daysInMonth;
    final rowCount     = (totalCells / 7).ceil();

    final now      = DateTime.now();
    final todayStr = _fmt(now.year, now.month, now.day);

    return Column(
      children: List.generate(rowCount, (row) {
        return Row(
          children: List.generate(7, (col) {
            final idx = row * 7 + col;
            final day = idx - leadingEmpty + 1;

            // Boş xana
            if (idx < leadingEmpty || day > daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }

            final dateStr  = _fmt(state.year, state.month, day);
            final status   = state.statusForDate(dateStr);
            final isToday  = dateStr == todayStr;
            final isSelected = state.selectedDate == dateStr;
            final isFuture = status == DayStatus.future;

            return Expanded(
              child: GestureDetector(
                onTap: isFuture
                    ? null
                    : () => ref
                        .read(calendarProvider.notifier)
                        .selectDate(dateStr),
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dayBg(status),
                    border: isSelected
                        ? Border.all(
                            color: AppColors.accent, width: 2)
                        : isToday
                            ? Border.all(
                                color: AppColors.accentLight,
                                width: 1.5)
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: isToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _dayText(status),
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

  String _fmt(int y, int m, int d) =>
      '${y.toString().padLeft(4, '0')}-'
      '${m.toString().padLeft(2, '0')}-'
      '${d.toString().padLeft(2, '0')}';

  Color _dayBg(DayStatus s) {
    switch (s) {
      case DayStatus.allDone:  return AppColors.accent;
      case DayStatus.partial:  return AppColors.accentMuted;
      case DayStatus.noneDone: return AppColors.bgElevated;
      case DayStatus.future:
      case DayStatus.empty:    return Colors.transparent;
    }
  }

  Color _dayText(DayStatus s) {
    switch (s) {
      case DayStatus.allDone:  return Colors.white;
      case DayStatus.partial:  return AppColors.textPrimary;
      case DayStatus.noneDone: return AppColors.textSecondary;
      case DayStatus.future:
      case DayStatus.empty:    return AppColors.textHint;
    }
  }

  // ─── LEGEND ───────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    final items = [
      (AppColors.accent,      'Hamısı tamamlandı'),
      (AppColors.accentMuted, 'Qismən tamamlandı'),
      (AppColors.bgElevated,  'Heç biri edilməyib'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.$1,
                border: item.$1 == AppColors.bgElevated
                    ? Border.all(color: AppColors.border)
                    : null,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              item.$2,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─── GÜN PANELİ ──────────────────────────────────────────────────────────

  Widget _buildDayPanel(CalendarState state) {
    final date      = state.selectedDate!;
    final records   = state.recordsForSelected();
    final parts     = date.split('-');
    final dayNum    = int.parse(parts[2]);
    final monthName = _months[int.parse(parts[1]) - 1];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$dayNum $monthName',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.separator, height: 1),
          ),
          if (state.amals.isEmpty)
            Text(
              'Əməl tapılmadı',
              style: GoogleFonts.nunito(
                  color: AppColors.textHint, fontSize: 13),
            )
          else
            ...state.amals.map((amal) {
              final rec = records.firstWhere(
                (r) => r.amalId == amal.id,
                orElse: () => AmalRecord(
                    amalId: amal.id, recordDate: date),
              );
              final done = rec.isCompleted;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 17,
                      color: done
                          ? AppColors.accent
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        amal.title,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: done
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          decoration: done
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (amal.type == AmalType.counter)
                      Text(
                        '${rec.countDone}/${amal.countTarget ?? 1}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}