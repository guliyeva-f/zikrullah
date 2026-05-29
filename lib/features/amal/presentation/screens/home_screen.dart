import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../calendar/presentation/providers/heatmap_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
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

  String get _todayLabel {
    final now = DateTime.now();
    return '${now.day} ${AppConstants.months[now.month - 1]}, ${AppConstants.weekdays[now.weekday]}';
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
        if (state.recentlyArchived.isNotEmpty) {
          final names = state.recentlyArchived.map((a) => a.title).join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$names — proqram tamamlandı 🎉',
                style: GoogleFonts.nunito(color: Colors.white),
              ),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 4),
            ),
          );
          ref.read(amalProvider.notifier).clearArchived();
        }
        final prevCount = prev?.value?.completedCount ?? 0;
        if (state.completedCount > prevCount) {
          ref.read(heatmapProvider.notifier).refresh();
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
                  'Bir xəta baş verdi',
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
                    'Yenidən cəhd et',
                    style: GoogleFonts.nunito(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
          data: (state) => Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              _buildHeader(context, state),

              // ── Əməllər / Empty ───────────────────────────────────────
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
                                                  'tamamlandı',
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

                              // ── Əməl əlavə et ─────────────────────────────────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  16,
                                ),
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
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add,
                                          color: AppColors.accent,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Əməl əlavə et',
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
                            ],
                          ),
                        ),
                ),
              ),

              // ── İllik aktivlik — həmişə aşağıda sabit ─────────────────
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
                      _todayLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Günün əməlləri',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AmalFormScreen()),
            ).then((_) => ref.read(amalProvider.notifier).refresh()),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgCard,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.add, color: AppColors.accent, size: 32),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'əməl əlavə et',
            style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ─── HEATMAP — aşağıda sabit ──────────────────────────────────────────────

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
          Text(
            'İllik aktivlik',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
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
            // data varsa da yoxdursa da eyni widget göstərilir
            // boş olduqda kvadratlar görünür, aktivlik olmayan günlər solğun
            data: (hState) => HeatmapWidget(data: hState.data),
          ),
        ],
      ),
    );
  }
}

// ─── AMAL CARD ────────────────────────────────────────────────────────────────

class _AmalCard extends StatelessWidget {
  final Amal amal;
  final AmalRecord? record;
  final int streak;
  final VoidCallback onCompleteTap;
  final VoidCallback onCounterTap;
  final VoidCallback onCounterDecrement;
  final VoidCallback onOpenScreen;
  final VoidCallback onDetailTap;

  const _AmalCard({
    required this.amal,
    required this.record,
    required this.streak,
    required this.onCompleteTap,
    required this.onCounterTap,
    required this.onCounterDecrement,
    required this.onOpenScreen,
    required this.onDetailTap,
  });

  bool get _done => record?.isCompleted ?? false;
  bool get _hasChevron => amal.type == AmalType.text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetailTap,
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
                        onTap: onOpenScreen,
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
    switch (amal.type) {
      case AmalType.checkbox:
      case AmalType.text:
        return GestureDetector(
          onTap: onCompleteTap,
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
        final cnt = record?.countDone ?? 0;
        final target = amal.countTarget ?? 1;
        final isSmall = target <= 10;

        return GestureDetector(
          onTap: _done
              ? null
              : isSmall
              ? onCounterTap
              : onOpenScreen,
          onLongPress: isSmall && cnt > 0
              ? () {
                  onCounterDecrement();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${amal.title}: ${cnt - 1}/$target',
                        style: GoogleFonts.nunito(color: Colors.white),
                      ),
                      backgroundColor: AppColors.accent,
                      duration: const Duration(seconds: 2),
                    ),
                  );
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
    final streakText = streak == 0
        ? null
        : streak == 1
        ? 'ilk gün 🔥'
        : '$streak gün ardıcıl 🔥';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          amal.title,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _done ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        if (streakText != null) ...[
          const SizedBox(height: 2),
          Text(
            streakText,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.accentLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (amal.durationDays != null) ...[
          const SizedBox(height: 2),
          Text(
            amal.durationLabel,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: amal.isExpired ? AppColors.accent : AppColors.textHint,
            ),
          ),
        ],
      ],
    );
  }
}
