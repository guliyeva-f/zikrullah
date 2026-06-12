import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/amal.dart';
import '../../data/amal_repository.dart';
import '../providers/amal_provider.dart';
import 'amal_form_screen.dart';

class AmalDetailScreen extends ConsumerStatefulWidget {
  final Amal amal;
  const AmalDetailScreen({super.key, required this.amal});

  @override
  ConsumerState<AmalDetailScreen> createState() => _AmalDetailScreenState();
}

class _AmalDetailScreenState extends ConsumerState<AmalDetailScreen> {
  late Amal _amal;
  Map<String, bool> _allRecords = {};
  int _bestStreak = 0;
  bool _loading = true;
  final _scrollController = ScrollController();

  static const double _rowH = 39.0;
  static const double _sepH = 30.0;
  static const double _headerH = 26.0;
  static const double _stickyH = 70.0;
  @override
  void initState() {
    super.initState();
    _amal = widget.amal;
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final repo = AmalRepository();
    final records = await repo.getAmalAllRecords(_amal.id);
    final best = await repo.getBestStreak(_amal.id);
    if (!mounted) return;
    setState(() {
      _allRecords = records;
      _bestStreak = best;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    final startDate = DateTime.parse(_amal.createdAt.substring(0, 10));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(startDate)) return;
    final gridStart = startDate.subtract(
      Duration(days: (startDate.weekday - 1) % 7),
    );
    final weeksToToday = today.difference(gridStart).inDays ~/ 7;
    int separatorCount = 0;
    int? lastMonth;
    for (int w = 0; w <= weeksToToday; w++) {
      final weekStart = gridStart.add(Duration(days: w * 7));
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (!day.isBefore(startDate)) {
          if (lastMonth != null && day.month != lastMonth) separatorCount++;
          lastMonth = day.month;
          break;
        }
      }
    }
    separatorCount += 1;
    final offset =
        _headerH + (separatorCount * _sepH) + (weeksToToday * _rowH) - 100;
    final target = offset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String get _todayStr => _dateStr(DateTime.now());

  Future<void> _showIntentionSheet() async {
    final ctrl = TextEditingController(text: _amal.intention ?? '');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sheet header ──────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Niyyətin',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Bu əməli nə üçün edirsən?',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 14),
            // ── Input ─────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 4,
                minLines: 3,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'Allah üçün, özüm üçün... niyyətini yaz 🤍',
                  hintStyle: GoogleFonts.nunito(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  counterStyle: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // ── Save button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final text = ctrl.text.trim().isEmpty
                      ? null
                      : ctrl.text.trim();
                  final updated = _amal.copyWith(intention: text);
                  final nav = Navigator.of(ctx);
                  await AmalRepository().updateAmal(updated);
                  if (!mounted) return;
                  setState(() => _amal = updated);
                  ref.read(amalProvider.notifier).refresh();
                  nav.pop();
                },
                child: Text(
                  'Saxla',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(amalProvider).value?.streaks[_amal.id] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── AppBar ────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.bgBase,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _amal.title,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Düzəliş et',
                onPressed: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AmalFormScreen(amal: _amal),
                      ),
                    ).then((_) async {
                      await ref.read(amalProvider.notifier).refresh();
                      final state = ref.read(amalProvider).value;
                      if (state != null && mounted) {
                        final updated = state.amals.firstWhere(
                          (a) => a.id == _amal.id,
                          orElse: () => _amal,
                        );
                        setState(() => _amal = updated);
                      }
                      _loadData();
                    }),
              ),
            ],
          ),

          // ── Niyyət (scroll ilə gedir) ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _buildIntentionSection(),
            ),
          ),

          // ── Sticky: yalnız streak ─────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTopDelegate(
              minHeight: _stickyH,
              maxHeight: _stickyH,
              child: Container(
                color: AppColors.bgBase,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _buildStreakSection(streak),
              ),
            ),
          ),

          // ── Təqvim ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
            sliver: SliverToBoxAdapter(
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  : _buildContinuousGrid(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── NİYYƏT ──────────────────────────────────────────────────────────────

  Widget _buildIntentionSection() {
    final hasIntention = _amal.intention?.isNotEmpty == true;

    return GestureDetector(
      onTap: _showIntentionSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hasIntention
              ? AppColors.accent.withValues(alpha: 0.06)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasIntention
                ? AppColors.accent.withValues(alpha: 0.25)
                : AppColors.border,
          ),
        ),
        child: hasIntention
            ? Row(
                children: [
                  Text('🤍', style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _amal.intention!,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              )
            : Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 15,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Niyyətin yoxdur — əlavə et',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── STREAK ───────────────────────────────────────────────────────────────

  Widget _buildStreakSection(int streak) {
    final completedCount = _allRecords.values.where((v) => v).length;
    // Sub-line: remaining / expired / best streak
    Widget? subLine;
    if (_amal.durationDays != null) {
      if (_amal.isExpired) {
        subLine = Text(
          'Əhdinə vəfalı oldun — Allah qəbul etsin 🤲',
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
        );
      } else {
        subLine = Text(
          '${_amal.remainingDaysFor(completedCount)} gün qaldı 🌙 (${_amal.durationDays} gün)',
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        );
      }
    } else if (_bestStreak > streak) {
      subLine = Text(
        'Rekord: $_bestStreak gün',
        style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    // Main streak label
    final String streakLabel;
    if (streak == 0) {
      streakLabel = 'Hələ başlanmayıb';
    } else if (_amal.isExpired) {
      streakLabel = 'Əhdinə vəfalı oldun — Allah qəbul etsin 🤲';
    } else {
      streakLabel = '$streak gün ardıcıl 🔥';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (streak > 0 && !_amal.isExpired)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text('🔥', style: TextStyle(fontSize: 22)),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                streakLabel,
                style: GoogleFonts.nunito(
                  fontSize: _amal.isExpired ? 14 : 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  height: 1.2,
                ),
              ),
              if (subLine != null) ...[const SizedBox(height: 3), subLine],
            ],
          ),
        ),
      ],
    );
  }

  // ─── TARİXÇƏ LÖVHƏSİ ────────────────────────────────────────────────────

  Widget _buildContinuousGrid() {
    final startDate = DateTime.parse(_amal.createdAt.substring(0, 10));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final DateTime gridEnd;
    if (_amal.durationDays != null) {
      gridEnd = startDate.add(Duration(days: _amal.durationDays! - 1));
    } else {
      final minEnd = startDate.add(const Duration(days: 39));
      gridEnd = today.isAfter(minEnd) ? today : minEnd;
    }

    final gridStart = startDate.subtract(
      Duration(days: (startDate.weekday - 1) % 7),
    );
    final totalWeeks = (gridEnd.difference(gridStart).inDays / 7).ceil() + 1;

    final rows = <Widget>[];

    rows.add(
      Row(
        children: AppConstants.weekdaysShort
            .map(
              (h) => Expanded(
                child: Center(
                  child: Text(
                    h,
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    rows.add(const SizedBox(height: 4));

    int? lastShownMonth;
    int? lastShownYear;

    for (int weekIdx = 0; weekIdx < totalWeeks; weekIdx++) {
      final weekStart = gridStart.add(Duration(days: weekIdx * 7));

      int? visibleMonth;
      int? visibleYear;
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (!day.isBefore(startDate) && !day.isAfter(gridEnd)) {
          visibleMonth = day.month;
          visibleYear = day.year;
          break;
        }
      }

      if (visibleMonth != null && visibleMonth != lastShownMonth) {
        if (weekIdx != 0) rows.add(const SizedBox(height: 8));
        final showYear = visibleYear != lastShownYear;
        rows.add(_buildMonthSeparator(visibleMonth, visibleYear!, showYear));
        rows.add(const SizedBox(height: 4));
        lastShownMonth = visibleMonth;
        lastShownYear = visibleYear;
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: List.generate(7, (dayIdx) {
              final day = weekStart.add(Duration(days: dayIdx));
              if (day.isBefore(startDate) || day.isAfter(gridEnd)) {
                return const Expanded(child: SizedBox(height: 36));
              }

              final isFuture = day.isAfter(today);
              final ds = _dateStr(day);
              final isToday = ds == _todayStr;
              final completed = _allRecords[ds] ?? false;

              return Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 36,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFuture
                            ? Colors.transparent
                            : completed
                            ? AppColors.accent
                            : AppColors.bgElevated,
                        border: isToday
                            ? Border.all(
                                color: AppColors.accentLight,
                                width: 1.5,
                              )
                            : isFuture
                            ? Border.all(color: AppColors.border, width: 1)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isFuture
                                ? AppColors.textHint.withValues(alpha: 0.35)
                                : completed
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _buildMonthSeparator(int month, int year, bool showYear) {
    return Row(
      children: [
        Text(
          showYear
              ? '${AppConstants.months[month - 1]} $year'
              : AppConstants.months[month - 1],
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(color: AppColors.separator, height: 1, thickness: 1),
        ),
      ],
    );
  }
}

// ─── STICKY HEADER DELEGATE ──────────────────────────────────────────────────

class _StickyTopDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _StickyTopDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_StickyTopDelegate old) =>
      old.minHeight != minHeight ||
      old.maxHeight != maxHeight ||
      old.child != child;
}
