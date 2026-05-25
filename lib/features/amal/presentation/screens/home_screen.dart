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
import 'text_screen.dart';
import 'counter_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String get _todayLabel {
    final now = DateTime.now();
    return '${now.day} ${AppConstants.months[now.month - 1]}, ${AppConstants.weekdays[now.weekday]}';
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
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.bgCard,
          onRefresh: () async {
            await ref.read(amalProvider.notifier).refresh();
            await ref.read(heatmapProvider.notifier).refresh();
          },
          child: asyncAmals.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (e, _) => Center(child: Text('Xəta: $e')),
            data: (state) => ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(state),
                if (state.amals.isEmpty)
                  _buildEmptyState(context)
                else
                  ...state.amals.map((amal) {
                    final record = state.records[amal.id];
                    final streak = state.streaks[amal.id] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                            builder: (_) => AmalDetailScreen(amal: amal),
                          ),
                        ),
                        onOpenScreen: () {
                          if (amal.type == AmalType.text) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TextScreen(amal: amal, record: record),
                              ),
                            ).then(
                              (_) => ref.read(amalProvider.notifier).refresh(),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CounterScreen(amal: amal),
                              ),
                            ).then(
                              (_) => ref.read(amalProvider.notifier).refresh(),
                            );
                          }
                        },
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                _buildHeatmapSection(asyncHeatmap),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader(AmalState state) {
    final total = state.totalCount;
    final done = state.completedCount;
    final progress = total == 0 ? 0.0 : done / total;

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
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(
                    Icons.edit_note_outlined,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  tooltip: total == 0
                      ? 'İlk əməlini əlavə et'
                      : 'Əməlləri idarə et',
                  onPressed: () {
                    final container = ProviderScope.containerOf(ctx);
                    if (total == 0) {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => const AmalFormScreen(),
                        ),
                      ).then((_) {
                        container.read(amalProvider.notifier).refresh();
                        container.read(heatmapProvider.notifier).refresh();
                      });
                    } else {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(builder: (_) => const ManageScreen()),
                      ).then((_) {
                        container.read(amalProvider.notifier).refresh();
                        container.read(heatmapProvider.notifier).refresh();
                      });
                    }
                  },
                ),
              ),
              Builder(
                builder: (ctx) => IconButton(
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
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ).then((_) {
                      container.read(amalProvider.notifier).refresh();
                      container.read(heatmapProvider.notifier).refresh();
                    });
                  },
                ),
              ),
            ],
          ),
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
              if (total > 0)
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌱', style: GoogleFonts.nunito(fontSize: 48)),
          const SizedBox(height: 20),
          Text(
            'Hər gün bir addım.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İzləmək istədiyin ilk əməlini əlavə et.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AmalFormScreen()),
            ).then((_) => ref.read(amalProvider.notifier).refresh()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'İlk əməli əlavə et',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEATMAP SECTION ──────────────────────────────────────────────────────

  Widget _buildHeatmapSection(AsyncValue<HeatmapState> asyncHeatmap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.separator, height: 1),
          const SizedBox(height: 16),
          Text(
            'İllik aktivlik',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
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
            data: (hState) => hState.data.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Hələ aktivlik yoxdur.',
                      style: GoogleFonts.nunito(
                        color: AppColors.textHint,
                        fontSize: 13,
                      ),
                    ),
                  )
                : HeatmapWidget(data: hState.data),
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
    return AnimatedOpacity(
      opacity: _done ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: onDetailTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                _buildLeading(context),
                const SizedBox(width: 12),
                Expanded(child: _buildMiddle()),
                if (_hasChevron)
                  GestureDetector(
                    onTap: onOpenScreen,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.chevron_right,
                        color: AppColors.textHint,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    switch (amal.type) {
      case AmalType.checkbox:
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
          // ≤10: tap artırır  |  >10: CounterScreen açır
          onTap: _done
              ? null
              : isSmall
              ? onCounterTap
              : onOpenScreen,
          // ≤10: longPress azaldır
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
            decoration: _done ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textSecondary,
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
  