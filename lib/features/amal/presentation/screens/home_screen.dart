import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../calendar/presentation/providers/heatmap_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../domain/amal.dart';
import '../../domain/amal_record.dart';
import '../providers/amal_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/heatmap_widget.dart';
import 'amal_detail_screen.dart';
import 'amal_form_screen.dart';
import 'manage_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'text_screen.dart';
import 'counter_screen.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  String get _timeGreeting {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 12) return 'Yeni günə Bismillah ☀️';
    if (h >= 12 && h < 15) return 'Günün bərəkətli keçsin ⛅';
    if (h >= 15 && h < 18) return 'Əsr çağı — zikrə davam 📿';
    if (h >= 18 && h < 21) return 'Axşamın xeyirlə dolsun ✨';
    return 'Gecən xeyirli keçsin 🌙';
  }
  String _timeGreetingOrDone(AmalState state) {
    final total = state.totalCount;
    final done = state.completedCount;
    if (total > 0 && done == total) return 'Günün əhdinə vəfalı oldun!';
    return _timeGreeting;
  }
  String _progressTitle(AmalState state) {
    final total = state.totalCount;
    final done = state.completedCount;
    if (total == 0) return 'Günün əməlləri';
    if (done == total) return 'Bərəkallah! 🤲';
    final ratio = done / total;
    if (done == 0) return 'Günün əməlləri';
    if (ratio < 0.5) return 'Yolun yarısındasan';
    return 'Əhdinə vəfalı qal ✊';
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final asyncAmals = ref.watch(amalProvider);
    final asyncHeatmap = ref.watch(heatmapProvider);
    ref.listen<AsyncValue<AmalState>>(amalProvider, (prev, next) {
      next.whenData((state) {
        final prevCount = prev?.value?.completedCount ?? 0;
        if (state.completedCount != prevCount) {
          ref.read(heatmapProvider.notifier).refresh();
        }
        if (state.recentlyArchived.isNotEmpty) {
          final titles = state.recentlyArchived.map((a) => a.title).join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"$titles" əhdi tamamlandı və arxivləndi 🤲',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 5),
            ),
          );
          ref.read(amalProvider.notifier).clearArchived();
        }
        if (state.recentlyReset.isNotEmpty) {
          final titles = state.recentlyReset.map((a) => a.title).join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"$titles" üçün ardıcıllıq sıfırlandı — bu gündən yenidən sayılır 🔄',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.textSecondary,
              duration: const Duration(seconds: 5),
            ),
          );
          ref.read(amalProvider.notifier).clearReset();
        }
      });
    });
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: asyncAmals.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.textHint,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bir şey səhv getdi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(amalProvider),
                  child: const Text(
                    'Yenidən cəhd et',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
          data: (state) => Column(
            children: [
              _buildHeader(context, state),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () async {
                    await ref.read(amalProvider.notifier).refresh();
                    await ref.read(heatmapProvider.notifier).refresh();
                  },
                  child: state.amals.isEmpty
                      ? _buildEmptyState(context)
                      : Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: false,
                          thickness: 2.5,
                          radius: const Radius.circular(2),
                          child: ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            children: [
                              ...() {
                                final incomplete = state.amals
                                    .where(
                                      (a) =>
                                          !(state.records[a.id]?.isCompleted ??
                                              false),
                                    )
                                    .toList();
                                final completed = state.amals
                                    .where(
                                      (a) =>
                                          state.records[a.id]?.isCompleted ??
                                          false,
                                    )
                                    .toList();
                                final sorted = [...incomplete, ...completed];
                                return sorted.map((amal) {
                                  final isFirstCompleted =
                                      completed.isNotEmpty &&
                                      amal == completed.first;
                                  final record = state.records[amal.id];
                                  final streak = state.streaks[amal.id] ?? 0;
                                  final completedCount =
                                      state.completedCounts[amal.id] ?? 0;
                                  return Column(
                                    children: [
                                      if (isFirstCompleted)
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            16,
                                            4,
                                            16,
                                            8,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: AppColors.separator,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                ),
                                                child: Text(
                                                  'Bu gün tamamlandı ✓',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors.textHint,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: AppColors.separator,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          8,
                                        ),
                                        child: _AmalCard(
                                          key: ValueKey(
                                            '${amal.id}_${record?.isCompleted ?? false}',
                                          ),
                                          amal: amal,
                                          record: record,
                                          streak: streak,
                                          completedCount: completedCount,
                                          onCompleteTap: () => ref
                                              .read(amalProvider.notifier)
                                              .completeCheckbox(amal.id),
                                          onCounterTap: () => ref
                                              .read(amalProvider.notifier)
                                              .incrementCounter(amal.id),
                                          onCounterDecrement: () => ref
                                              .read(amalProvider.notifier)
                                              .decrementCounter(amal.id),
                                          onDetailTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AmalDetailScreen(amal: amal),
                                            ),
                                          ),
                                          onOpenScreen: () {
                                            if (amal.type == AmalType.text) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => TextScreen(
                                                    amal: amal,
                                                    record: record,
                                                  ),
                                                ),
                                              ).then(
                                                (_) => ref
                                                    .read(amalProvider.notifier)
                                                    .refresh(),
                                              );
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      CounterScreen(amal: amal),
                                                ),
                                              ).then(
                                                (_) => ref
                                                    .read(amalProvider.notifier)
                                                    .refresh(),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList();
                              }(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  16,
                                ),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () =>
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AmalFormScreen(),
                                          ),
                                        ).then((_) {
                                          ref
                                              .read(amalProvider.notifier)
                                              .refresh();
                                          ref
                                              .read(heatmapProvider.notifier)
                                              .refresh();
                                        }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgCard,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            color: AppColors.accent,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Əməl',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              _buildHeatmapSection(asyncHeatmap),
            ],
          ),
        ),
      ),
    );
  }
  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AmalState state) {
    final total = state.totalCount;
    final done = state.completedCount;
    final progress = total == 0 ? 0.0 : done / total;
    final hasAmals = state.amals.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timeGreetingOrDone(state),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _progressTitle(state),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasAmals)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(
                      Icons.edit_note_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    tooltip: 'Əməlləri idarə et',
                    onPressed: () {
                      final container = ProviderScope.containerOf(ctx);
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(builder: (_) => const ManageScreen()),
                      ).then((_) {
                        container.read(amalProvider.notifier).refresh();
                        container.read(heatmapProvider.notifier).refresh();
                      });
                    },
                  ),
                ),
              Builder(
                builder: (ctx) {
                  final declined =
                      ref.watch(notifDeclinedProvider).value ?? false;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        tooltip: 'Ayarlar',
                        onPressed: () {
                          final container = ProviderScope.containerOf(ctx);
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ).then((_) {
                            container.read(amalProvider.notifier).refresh();
                            container.read(heatmapProvider.notifier).refresh();
                            ref.invalidate(notifDeclinedProvider);
                          });
                        },
                      ),
                      if (declined)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFC107),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          if (hasAmals) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$done / $total tamamlandı',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress * 100),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, animPct, _) => Text(
                    '${animPct.round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, _) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: animValue,
                  backgroundColor: AppColors.bgElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accent,
                  ),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.05),
                        AppColors.accent.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 52,
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.4),
                        AppColors.accent.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            RichText(
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Scheherazade New',
                  fontSize: 28,
                  height: 2.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(text: 'أَلاَ بِ'),
                  TextSpan(
                    text: 'ذِكْرِ اللّهِ',
                    style: TextStyle(color: Color(0xFF6B8C5A)),
                  ),
                  TextSpan(text: ' تَطْمَئِنُّ الْقُلُوبُ'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 32,
              height: 0.5,
              color: AppColors.accentStreak.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bilin ki, qəlblər yalnız Allahı zikr etməklə\nrahatlıq tapar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌿', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                const Text(
                  'Ər-Rəd surəsi, 28',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 6),
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159),
                  child: const Text('🌿', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AmalFormScreen()),
              ).then((_) => ref.read(amalProvider.notifier).refresh()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 17,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'İlk əməlini əlavə et',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  // ─── HEATMAP ──────────────────────────────────────────────────────────────
  Widget _buildHeatmapSection(AsyncValue<HeatmapState> asyncHeatmap) {
    return Container(
      color: AppColors.bgBase,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(color: AppColors.separator, height: 1),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              final heatmap = ref.read(heatmapProvider);
              final heatmapData = heatmap.when(
                data: (s) => s.data,
                loading: () => <String, double>{},
                error: (_, _) => <String, double>{},
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CalendarScreen(
                    initialDate: DateTime.now(),
                    heatmapData: heatmapData,
                  ),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'İllik yolun. Təqvimə bax ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textPrimary,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          asyncHeatmap.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (hState) => HeatmapWidget(
              data: hState.data,
              onDayTap: (date) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CalendarScreen(
                    initialDate: date,
                    heatmapData: hState.data,
                  ),
                ),
              ),
              onMonthTap: (date) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CalendarScreen(
                    initialDate: date,
                    heatmapData: hState.data,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─── AMAL CARD ────────────────────────────────────────────────────────────────
class _AmalCard extends StatefulWidget {
  final Amal amal;
  final AmalRecord? record;
  final int streak;
  final int completedCount;
  final VoidCallback onCompleteTap;
  final VoidCallback onCounterTap;
  final VoidCallback onCounterDecrement;
  final VoidCallback onOpenScreen;
  final VoidCallback onDetailTap;
  const _AmalCard({
    super.key,
    required this.amal,
    required this.record,
    required this.streak,
    required this.completedCount,
    required this.onCompleteTap,
    required this.onCounterTap,
    required this.onCounterDecrement,
    required this.onOpenScreen,
    required this.onDetailTap,
  });
  @override
  State<_AmalCard> createState() => _AmalCardState();
}
class _AmalCardState extends State<_AmalCard>
    with SingleTickerProviderStateMixin {
  bool _hintVisible = false;
  bool _leaving = false;
  bool _hintAlreadyShown = false;
  late final AnimationController _leaveCtrl;
  late final Animation<double> _leaveOpacity;
  late final Animation<Offset> _leaveSlide;
  @override
  void initState() {
    super.initState();
    _leaveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _leaveOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _leaveCtrl, curve: Curves.easeIn));
    _leaveSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0.12),
    ).animate(CurvedAnimation(parent: _leaveCtrl, curve: Curves.easeIn));
  }
  @override
  void dispose() {
    _leaveCtrl.dispose();
    super.dispose();
  }
  bool get _done => widget.record?.isCompleted ?? false;
  bool get _hasChevron => widget.amal.type == AmalType.text;
  Future<void> _checkAndShowHint() async {
    if (_hintAlreadyShown) return;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('counter_hint_${widget.amal.id}') ?? false;
    if (!shown && mounted) {
      setState(() {
        _hintVisible = true;
        _hintAlreadyShown = true;
      });
      await markCounterHintShown(widget.amal.id);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _hintVisible = false);
    }
  }
  Future<void> _handleComplete() async {
    if (_done) {
      widget.onCompleteTap();
      return;
    }
    if (_leaving) return;
    setState(() => _leaving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _leaveCtrl.forward();
    if (!mounted) return;
    widget.onCompleteTap();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _leaveOpacity,
      child: SlideTransition(
        position: _leaveSlide,
        child: GestureDetector(
          onTap: widget.onDetailTap,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (_done || _leaving)
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 3,
                    decoration: BoxDecoration(
                      color: (_done || _leaving)
                          ? AppColors.accent
                          : Colors.transparent,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildLeading(context),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMiddle()),
                          if (_hasChevron)
                            GestureDetector(
                              onTap: widget.onOpenScreen,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.bgElevated,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildLeading(BuildContext context) {
    final isChecked = _done || _leaving;
    Widget circle(VoidCallback onTap) => SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isChecked ? AppColors.accent : Colors.transparent,
              border: Border.all(
                color: isChecked ? AppColors.accent : AppColors.textHint,
                width: 2,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, color: Colors.white, size: 15)
                : null,
          ),
        ),
      ),
    );
    switch (widget.amal.type) {
      case AmalType.checkbox:
      case AmalType.text:
        return circle(_handleComplete);
      case AmalType.counter:
        final cnt = widget.record?.countDone ?? 0;
        final target = widget.amal.countTarget ?? 1;
        final isSmall = target <= 10;
        return Center(
          child: GestureDetector(
            onTap: isSmall
                ? () {
                    if (_done) return;
                    widget.onCounterTap();
                    _checkAndShowHint();
                  }
                : _done
                ? null
                : widget.onOpenScreen,
            onLongPress: isSmall && cnt > 0
                ? () {
                    widget.onCounterDecrement();
                    if (_hintVisible) setState(() => _hintVisible = false);
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _done
                  ? const Icon(Icons.check, color: AppColors.accent, size: 18)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          color: AppColors.accent,
                          size: 14,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$cnt/$target',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
    }
  }
  Widget _buildMiddle() {
    final bool isProgramComplete =
        _done &&
        widget.amal.durationDays != null &&
        widget.completedCount >= widget.amal.durationDays!;
    String? milestoneText(int s) {
      if (s == 7) return 'bir həftə — MaşaAllah! 🔥';
      if (s == 21) return '21 gün — Əhsən sənə! 🌟';
      if (s == 40) return '40 gün — SubhanAllah! 🌿';
      return null;
    }
    final bool isLoose =
        widget.amal.durationDays != null && widget.amal.allowBreak;
    final int displayCount = isLoose ? widget.completedCount : widget.streak;
    final String? streakText;
    if (isProgramComplete) {
      streakText =
          '${widget.amal.durationDays} günlük əhdinə vəfalı oldun.\nAllah qəbul etsin 🤲';
    } else if (displayCount == 0) {
      streakText = null;
    } else if (isLoose) {
      streakText = '$displayCount / ${widget.amal.durationDays} gün';
    } else if (displayCount == 1) {
      streakText = 'ilk addım 🌱';
    } else if (displayCount <= 3) {
      streakText = '$displayCount gün davamlı ✨';
    } else {
      streakText =
          milestoneText(displayCount) ?? '$displayCount gün davamlı 🔥';
    }
    final bool isMilestone =
        !isProgramComplete && !isLoose && milestoneText(displayCount) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.amal.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: (_done || _leaving)
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
        if (streakText != null) ...[
          const SizedBox(height: 2),
          Text(
            streakText,
            style: TextStyle(
              fontSize: 14,
              color: isProgramComplete || isMilestone
                  ? AppColors.accent
                  : AppColors.accentStreak,
              fontWeight: isProgramComplete || isMilestone
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
        ],
        if (_hintVisible)
          AnimatedOpacity(
            opacity: _hintVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Text(
                'Azaltmaq üçün uzun bas',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
