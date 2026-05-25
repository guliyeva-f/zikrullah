import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/amal.dart';
import '../../data/amal_repository.dart';
import '../providers/amal_provider.dart';

class AmalDetailScreen extends ConsumerStatefulWidget {
  final Amal amal;
  const AmalDetailScreen({super.key, required this.amal});

  @override
  ConsumerState<AmalDetailScreen> createState() => _AmalDetailScreenState();
}

class _AmalDetailScreenState extends ConsumerState<AmalDetailScreen> {
  final _repo = AmalRepository();

  late int _calYear;
  late int _calMonth;
  Map<String, bool> _calData = {};
  int _totalCompleted = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calYear = now.year;
    _calMonth = now.month;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final cal = await _repo.getAmalCalendarMonth(
      widget.amal.id,
      _calYear,
      _calMonth,
    );
    final total = await _repo.countCompletedDays(widget.amal.id);
    if (!mounted) return;
    setState(() {
      _calData = cal;
      _totalCompleted = total;
      _loading = false;
    });
  }

  void _prevMonth() {
    setState(() {
      if (_calMonth == 1) {
        _calYear--;
        _calMonth = 12;
      } else {
        _calMonth--;
      }
    });
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_calYear == now.year && _calMonth >= now.month) return;
    setState(() {
      if (_calMonth == 12) {
        _calYear++;
        _calMonth = 1;
      } else {
        _calMonth++;
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(amalProvider).value?.streaks[widget.amal.id] ?? 0;
    final now = DateTime.now();
    final isNow = _calYear == now.year && _calMonth == now.month;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.amal.title,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 12),
            if (widget.amal.durationDays != null) ...[
              _buildDurationCard(),
              const SizedBox(height: 12),
            ],
            _buildStatsRow(streak),
            const SizedBox(height: 20),
            _buildCalendarNav(isNow),
            const SizedBox(height: 12),
            _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  )
                : _buildCalendar(now),
          ],
        ),
      ),
    );
  }

  // ─── INFO KART ────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    final typeLabel = switch (widget.amal.type) {
      AmalType.checkbox => 'Checkbox',
      AmalType.counter => 'Sayğac',
      AmalType.text => 'Mətnli',
    };

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
          // Növ badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              typeLabel,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Niyyət
          if (widget.amal.intention?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              'Niyyət',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.amal.intention!,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 12),
          Text(
            'Başlanğıc: ${widget.amal.createdAt.substring(0, 10)}',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── MÜDDƏT PROGRESSI ────────────────────────────────────────────────────

  Widget _buildDurationCard() {
    final days = widget.amal.durationDays!;
    final elapsed = widget.amal.daysSinceStart.clamp(0, days);
    final progress = elapsed / days;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proqram irəliləyişi',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$elapsed / $days gün',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.amal.isExpired
                ? 'Proqram tamamlandı 🎉'
                : '${widget.amal.remainingDays} gün qaldı',
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: widget.amal.isExpired
                  ? AppColors.accent
                  : AppColors.textSecondary,
              fontWeight: widget.amal.isExpired
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATİSTİKA ───────────────────────────────────────────────────────────

  Widget _buildStatsRow(int streak) {
    final days = widget.amal.daysSinceStart;
    final pct = days > 0 ? (_totalCompleted / days * 100).round() : 0;

    return Row(
      children: [
        Expanded(child: _statBox('🔥 Streak', '$streak gün')),
        const SizedBox(width: 8),
        Expanded(child: _statBox('✓ Tamamlandı', '$_totalCompleted gün')),
        const SizedBox(width: 8),
        Expanded(child: _statBox('% Davamlılıq', '$pct%')),
      ],
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TƏQVİM ───────────────────────────────────────────────────────────────

  Widget _buildCalendarNav(bool isNow) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          onPressed: _prevMonth,
        ),
        SizedBox(
          width: 160,
          child: Text(
            '${AppConstants.months[_calMonth - 1]} $_calYear',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: isNow ? AppColors.textHint : AppColors.textPrimary,
          ),
          onPressed: isNow ? null : _nextMonth,
        ),
      ],
    );
  }

  Widget _buildCalendar(DateTime now) {
    final first = DateTime(_calYear, _calMonth, 1);
    final leading = (first.weekday - 1) % 7;
    final days = DateTime(_calYear, _calMonth + 1, 0).day;
    final rows = ((leading + days) / 7).ceil();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Row(
          children: AppConstants.weekdaysShort
              .map(
                (h) => Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate(
          rows,
          (row) => Row(
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              final day = idx - leading + 1;

              if (idx < leading || day > days) {
                return const Expanded(child: SizedBox(height: 38));
              }

              final dateStr =
                  '${_calYear.toString().padLeft(4, '0')}-'
                  '${_calMonth.toString().padLeft(2, '0')}-'
                  '${day.toString().padLeft(2, '0')}';
              final isFuture = DateTime(
                _calYear,
                _calMonth,
                day,
              ).isAfter(DateTime(now.year, now.month, now.day));
              final isCompleted = _calData[dateStr] ?? false;
              final isToday = dateStr == todayStr;

              return Expanded(
                child: Container(
                  height: 38,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFuture
                        ? Colors.transparent
                        : isCompleted
                        ? AppColors.accent
                        : AppColors.bgElevated,
                    border: isToday
                        ? Border.all(color: AppColors.accentLight, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isFuture
                            ? AppColors.textHint
                            : isCompleted
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
