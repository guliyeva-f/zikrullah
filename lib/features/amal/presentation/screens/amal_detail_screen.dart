import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/amal.dart';
import '../../data/amal_repository.dart';
import '../providers/amal_provider.dart';
import 'amal_form_screen.dart';
import '../../domain/amal_cycle.dart';

class AmalDetailScreen extends ConsumerStatefulWidget {
  final Amal amal;
  const AmalDetailScreen({super.key, required this.amal});

  @override
  ConsumerState<AmalDetailScreen> createState() => _AmalDetailScreenState();
}

class _AmalDetailScreenState extends ConsumerState<AmalDetailScreen> {
  late Amal _amal;
  Map<String, bool> _allRecords = {};
  int _cycleCompletedCount = 0;
  int _bestStreak = 0;
  List<AmalCycle> _cycles = [];
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
    final cycleStart = _amal.effectiveCycleStart.substring(0, 10);
    final cycleCompleted = await repo.countCompletedDays(
      _amal.id,
      fromDate: cycleStart,
    );
    final best = await repo.getBestStreak(
      _amal.id,
      fromDate: _amal.createdAt.substring(0, 10),
    );
    final cycles = _amal.durationDays != null
        ? await repo.getCyclesForAmal(_amal.id)
        : <AmalCycle>[];

    if (!mounted) return;
    setState(() {
      _allRecords = records;
      _cycleCompletedCount = cycleCompleted;
      _bestStreak = best;
      _cycles = cycles;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime historyStart = DateTime.parse(_amal.createdAt.substring(0, 10));
    if (_allRecords.isNotEmpty) {
      final sortedKeys = _allRecords.keys.toList()..sort();
      final earliest = DateTime.parse(sortedKeys.first);
      if (earliest.isBefore(historyStart)) historyStart = earliest;
    }

    if (today.isBefore(historyStart)) return;
    final gridStart = historyStart.subtract(
      Duration(days: (historyStart.weekday - 1) % 7),
    );
    final weeksToToday = today.difference(gridStart).inDays ~/ 7;
    int separatorCount = 0;
    int? lastMonth;
    for (int w = 0; w <= weeksToToday; w++) {
      final weekStart = gridStart.add(Duration(days: w * 7));
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (!day.isBefore(historyStart)) {
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
            Row(
              children: [
                const Text(
                  'Niyyətin',
                  style: TextStyle(
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
            const Text(
              'Bu əməli nə üçün edirsən?',
              style: TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
            const SizedBox(height: 14),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  hintText: 'Allah üçün, özüm üçün... niyyətini yaz 🤍',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                  counterStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(14, 14, 14, 4),
                ),
              ),
            ),
            const SizedBox(height: 14),
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
                child: const Text(
                  'Saxla',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
    final streak = _amal.isActive
        ? (ref.watch(amalProvider).value?.streaks[_amal.id] ?? 0)
        : 0;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              if (_amal.isActive)
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _buildIntentionSection(),
            ),
          ),

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

          SliverToBoxAdapter(child: _buildCycleHistory()),

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
                  const Text('🤍', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _amal.intention!,
                      style: const TextStyle(
                        fontSize: 14,
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
            : const Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 15,
                    color: AppColors.textHint,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Niyyətin yoxdur — əlavə et',
                    style: TextStyle(fontSize: 14, color: AppColors.textHint),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── STREAK ───────────────────────────────────────────────────────────────

  Widget _buildStreakSection(int streak) {
    final target = _amal.durationDays;
    final isProgramComplete = target != null && _cycleCompletedCount >= target;
    final isLoose = _amal.allowBreak;

    Widget? subLine;
    if (target != null && !isProgramComplete && !isLoose) {
      final remaining = _amal.remainingDaysFor(_cycleCompletedCount);
      subLine = Text(
        _cycleCompletedCount == 0
            ? 'Müddət: $target gün'
            : '$remaining gün qaldı 🌙 — cəmi $target gün',
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      );
    } else if (target == null && _bestStreak > streak) {
      subLine = Text(
        'Rekord: $_bestStreak gün',
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      );
    }

    final String streakLabel;
    if (isProgramComplete) {
      streakLabel = 'Əhdinə vəfalı oldun — Allah qəbul etsin 🤲';
    } else if (!_amal.isActive) {
      streakLabel = 'Yarımçıq qaldı';
    } else if (target != null && isLoose) {
      streakLabel = '$_cycleCompletedCount/$target gün';
    } else if (streak == 0) {
      streakLabel = 'Hələ başlanmayıb';
    } else {
      streakLabel = '$streak gün ardıcıl 🔥';
    }

    final showFireIcon =
        streak > 0 && !isProgramComplete && _amal.isActive && !isLoose;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showFireIcon)
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
                style: TextStyle(
                  fontSize: (isProgramComplete || !_amal.isActive) ? 14 : 20,
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

  // ─── TƏQVİM ──────────────────────────────────────────────────────────────

  Widget _buildContinuousGrid() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeCycleStart = DateTime.parse(
      _amal.effectiveCycleStart.substring(0, 10),
    );
    DateTime historyStart = activeCycleStart;
    if (_allRecords.isNotEmpty) {
      final sortedKeys = _allRecords.keys.toList()..sort();
      final earliest = DateTime.parse(sortedKeys.first);
      if (earliest.isBefore(historyStart)) historyStart = earliest;
    }

    final startDate = historyStart;

    final DateTime gridEnd;
    if (_amal.durationDays != null) {
      final cycleEnd = activeCycleStart.add(
        Duration(days: _amal.durationDays! - 1),
      );
      gridEnd = cycleEnd.isAfter(today) ? cycleEnd : today;
    } else {
      final minEnd = activeCycleStart.add(const Duration(days: 39));
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
                    style: const TextStyle(
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
              final isOldCycle = day.isBefore(activeCycleStart);

              return Expanded(
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFuture
                        ? Colors.transparent
                        : completed
                        ? isOldCycle
                              ? AppColors.accent.withValues(alpha: 0.8)
                              : AppColors.accent
                        : AppColors.bgElevated,
                    border: isToday
                        ? Border.all(color: AppColors.accentLight, width: 1.5)
                        : isFuture
                        ? Border.all(color: AppColors.border, width: 1)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isFuture
                            ? AppColors.textHint.withValues(alpha: 0.35)
                            : completed
                            ? Colors.white.withValues(
                                alpha: isOldCycle ? 0.7 : 1.0,
                              )
                            : isOldCycle
                            ? AppColors.textHint.withValues(alpha: 0.8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
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

  // ─── CƏHD TARİXÇƏSİ (yalnız ardıcıl rejim, 1-dən çox cəhd varsa) ───────────

  Widget _buildCycleHistory() {
    if (_amal.allowBreak || _amal.durationDays == null) {
      return const SizedBox.shrink();
    }
    final closed = _cycles.where((c) => !c.isOngoing).toList();
    if (closed.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keçmiş cəhdlər:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          for (final c in closed)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                _cycleLine(c),
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  String _cycleLine(AmalCycle c) {
    final target = _amal.durationDays ?? 0;
    final range = '${_shortDate(c.startedAt)} – ${_shortDate(c.endedAt!)}';
    if (c.daysDone >= target) {
      return '$range  ·  ✅ Tamamlandı';
    }
    return '$range  ·  ${c.daysDone} gün (yarımçıq qaldı)';
  }

  String _shortDate(String isoDate) {
    final d = DateTime.parse(isoDate.substring(0, 10));
    return '${d.day} ${AppConstants.monthsShort[d.month - 1]}';
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
