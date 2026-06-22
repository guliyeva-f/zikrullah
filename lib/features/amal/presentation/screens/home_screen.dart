import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../calendar/presentation/providers/heatmap_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../domain/amal.dart';
import '../../domain/amal_record.dart';
import '../providers/amal_provider.dart';
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
    if (h >= 18 && h < 21) return 'Axşamın xeyirlə dolsun 🌙';
    return 'Gecən xeyirli keçsin ✨';
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
    final hintShown = ref.watch(counterHintProvider).value ?? true;

    ref.listen<AsyncValue<AmalState>>(amalProvider, (prev, next) {
      next.whenData((state) {
        final prevCount = prev?.value?.completedCount ?? 0;
        if (state.completedCount > prevCount) {
          ref.read(heatmapProvider.notifier).refresh();
        }
        if (state.recentlyArchived.isNotEmpty) {
          final titles = state.recentlyArchived.map((a) => a.title).join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"$titles" əhdi tamamlandı və arxivləndi 🤲',
                style: GoogleFonts.nunito(color: Colors.white),
              ),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 5),
            ),
          );
          ref.read(amalProvider.notifier).clearArchived();
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
                Text(
                  'Bir şey səhv getdi',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(amalProvider),
                  child: Text(
                    'Yenidən yüklə',
                    style: GoogleFonts.nunito(color: AppColors.accent),
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
                                    key: ValueKey(amal.id),
                                    children: [
                                      if (isFirstCompleted)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            4,
                                            16,
                                            8,
                                          ),
                                          child: Row(
                                            children: [
                                              const Expanded(
                                                child: Divider(
                                                  color: AppColors.separator,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                child: Text(
                                                  'bu gün əda olundu ✓',
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 11,
                                                    color: AppColors.textHint,
                                                  ),
                                                ),
                                              ),
                                              const Expanded(
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
                                          amal: amal,
                                          record: record,
                                          streak: streak,
                                          completedCount: completedCount,
                                          showCounterHint:
                                              !hintShown &&
                                              amal.type == AmalType.counter &&
                                              (amal.countTarget ?? 0) <= 10,
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
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.add,
                                            color: AppColors.accent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Yeni əməl əlavə et',
                                            style: GoogleFonts.nunito(
                                              fontSize: 13,
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
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _progressTitle(state),
                      style: GoogleFonts.nunito(
                        fontSize: 20,
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
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.bgElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
                minHeight: 6,
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
              text: TextSpan(
                style: GoogleFonts.scheherazadeNew(
                  fontSize: 28,
                  height: 2.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                children: const [
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
              color: AppColors.accentLight.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Bilin ki, qəlblər yalnız Allahı zikr etməklə\nrahatlıq tapar',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.7,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🌿', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 6),
                Text(
                  'Ər-Rəd surəsi, 28',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.textHint,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 6),
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159),
                  child: Text('🌿', style: TextStyle(fontSize: 11)),
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
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'İlk əməlini əlavə et',
                  style: GoogleFonts.nunito(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'İllik yolun',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
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
  final bool showCounterHint;
  final VoidCallback onCompleteTap;
  final VoidCallback onCounterTap;
  final VoidCallback onCounterDecrement;
  final VoidCallback onOpenScreen;
  final VoidCallback onDetailTap;

  const _AmalCard({
    required this.amal,
    required this.record,
    required this.streak,
    required this.completedCount,
    required this.showCounterHint,
    required this.onCompleteTap,
    required this.onCounterTap,
    required this.onCounterDecrement,
    required this.onOpenScreen,
    required this.onDetailTap,
  });

  @override
  State<_AmalCard> createState() => _AmalCardState();
}

class _AmalCardState extends State<_AmalCard> {
  bool _hintVisible = false;

  bool get _done => widget.record?.isCompleted ?? false;
  bool get _hasChevron => widget.amal.type == AmalType.text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDetailTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _done
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 3,
              height: 56,
              decoration: BoxDecoration(
                color: _done ? AppColors.accent : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 12, 14, 12),
                child: Row(
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
    );
  }

  Widget _buildLeading(BuildContext context) {
    switch (widget.amal.type) {
      case AmalType.checkbox:
      case AmalType.text:
        return GestureDetector(
          onTap: widget.onCompleteTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _done ? AppColors.accent : Colors.transparent,
              border: Border.all(
                color: _done ? AppColors.accent : AppColors.textHint,
                width: 2,
              ),
            ),
            child: _done
                ? const Icon(Icons.check, color: Colors.white, size: 15)
                : null,
          ),
        );

      case AmalType.counter:
        final cnt = widget.record?.countDone ?? 0;
        final target = widget.amal.countTarget ?? 1;
        final isSmall = target <= 10;

        return GestureDetector(
          onTap: _done
              ? null
              : isSmall
              ? () {
                  widget.onCounterTap();
                  if (widget.showCounterHint && cnt == 0 && !_hintVisible) {
                    setState(() => _hintVisible = true);
                    markCounterHintShown();
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) setState(() => _hintVisible = false);
                    });
                  }
                }
              : widget.onOpenScreen,
          onLongPress: isSmall && cnt > 0
              ? () {
                  widget.onCounterDecrement();
                  if (_hintVisible) setState(() => _hintVisible = false);
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _done
                ? const Icon(Icons.check, color: AppColors.accent, size: 18)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: AppColors.accent, size: 15),
                      const SizedBox(height: 2),
                      Text(
                        '$cnt/$target',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
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

    final String? streakText;
    if (isProgramComplete) {
      streakText =
          '${widget.amal.durationDays} günlük əhdinə vəfalı oldun.\nAllah qəbul etsin 🤲';
    } else if (widget.streak == 0) {
      streakText = null;
    } else if (widget.streak == 1) {
      streakText = 'ilk addım 🌱';
    } else if (widget.streak <= 3) {
      streakText = '${widget.streak} gün davamlı ✨';
    } else {
      streakText =
          milestoneText(widget.streak) ?? '${widget.streak} gün davamlı 🔥';
    }

    final bool isMilestone =
        !isProgramComplete && milestoneText(widget.streak) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.amal.title,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _done ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        if (streakText != null && widget.amal.durationDays == null) ...[
          const SizedBox(height: 2),
          Text(
            streakText,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: isProgramComplete || isMilestone
                  ? AppColors.accent
                  : AppColors.accentLight,
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
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                'azaltmaq üçün uzun bas',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (widget.amal.durationDays != null && !isProgramComplete) ...[
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              children: [
                if (_done && streakText != null) ...[
                  TextSpan(
                    text: streakText,
                    style: TextStyle(
                      color: isMilestone
                          ? AppColors.accent
                          : AppColors.accentLight,
                      fontWeight: isMilestone
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '  ·  ',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ],
                TextSpan(
                  text:
                      '${widget.amal.remainingDaysFor(widget.completedCount).clamp(0, 999)} gün qaldı',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
