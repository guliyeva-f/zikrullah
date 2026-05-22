import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class HeatmapWidget extends StatefulWidget {
  final Map<String, double> data;
  const HeatmapWidget({super.key, required this.data});

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget> {
  final _scrollCtrl = ScrollController();

  static const _cellSize = 11.0;
  static const _gap = 2.0;
  static const _total = _cellSize + _gap;

  static const _monthNames = [
    '',
    'Yan',
    'Fev',
    'Mar',
    'Apr',
    'May',
    'İyn',
    'İyl',
    'Avq',
    'Sen',
    'Okt',
    'Noy',
    'Dek',
  ];

  @override
  void initState() {
    super.initState();
    // Ən son tarixə (sağa) avtomatik scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Color _cellColor(double? ratio) {
    if (ratio == null || ratio == 0) return AppColors.bgElevated;
    if (ratio < 0.25) return AppColors.accentMuted.withValues(alpha: 0.35);
    if (ratio < 0.5) return AppColors.accentMuted;
    if (ratio < 0.75) return AppColors.accentLight;
    return AppColors.accent;
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Həftə sütunlarını qurur — Monday-first
  List<List<DateTime?>> _buildWeeks() {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    var start = todayNorm.subtract(const Duration(days: 364));
    start = start.subtract(Duration(days: start.weekday - 1));

    final weeks = <List<DateTime?>>[];
    var cur = start;

    while (!cur.isAfter(todayNorm)) {
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final day = cur.add(Duration(days: d));
        week.add(day.isAfter(todayNorm) ? null : day);
      }
      weeks.add(week);
      cur = cur.add(const Duration(days: 7));
    }
    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final weeks = _buildWeeks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          controller: _scrollCtrl,
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthRow(weeks),
              const SizedBox(height: 3),
              _buildGrid(weeks, todayNorm),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildLegend(),
      ],
    );
  }

  // ─── AY BAŞLIQLAR ────────────────────────────────────────────────────────

  Widget _buildMonthRow(List<List<DateTime?>> weeks) {
    String? lastKey;
    return Row(
      children: weeks.map((week) {
        final first = week.firstWhere((d) => d != null, orElse: () => null);
        String? label;
        if (first != null) {
          final key = '${first.year}-${first.month}';
          if (key != lastKey) {
            lastKey = key;
            label = _monthNames[first.month];
          }
        }
        return SizedBox(
          width: _total,
          child: label != null
              ? Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
        );
      }).toList(),
    );
  }

  // ─── GRID ─────────────────────────────────────────────────────────────────

  Widget _buildGrid(List<List<DateTime?>> weeks, DateTime todayNorm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: weeks.map((week) {
        return Column(
          children: week.map((day) {
            if (day == null) {
              return const SizedBox(width: _total, height: _total);
            }
            final ratio = widget.data[_fmt(day)];
            final isToday = day == todayNorm;

            return Container(
              width: _cellSize,
              height: _cellSize,
              margin: const EdgeInsets.all(_gap / 2),
              decoration: BoxDecoration(
                color: _cellColor(ratio),
                borderRadius: BorderRadius.circular(2),
                border: isToday
                    ? Border.all(color: AppColors.accent, width: 1.2)
                    : null,
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  // ─── LEGEND ───────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Az',
          style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textHint),
        ),
        const SizedBox(width: 4),
        ...[null, 0.2, 0.4, 0.7, 1.0].map(
          (r) => Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: _cellColor(r),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Çox',
          style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textHint),
        ),
      ],
    );
  }
}
