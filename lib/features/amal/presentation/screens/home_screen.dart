import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/amal.dart';
import '../../domain/amal_record.dart';
import '../providers/amal_provider.dart';
import 'text_screen.dart';
import 'manage_screen.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  static const _months = [
    'Yanvar',
    'Fevral',
    'Mart',
    'Aprel',
    'May',
    'İyun',
    'İyul',
    'Avqust',
    'Sentyabr',
    'Oktyabr',
    'Noyabr',
    'Dekabr',
  ];
  static const _weekdays = [
    '',
    'Bazar ertəsi',
    'Çərşənbə axşamı',
    'Çərşənbə',
    'Cümə axşamı',
    'Cümə',
    'Şənbə',
    'Bazar',
  ];

  String get _todayLabel {
    final now = DateTime.now();
    return '${now.day} ${_months[now.month - 1]}, ${_weekdays[now.weekday]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: _tabIndex == 0
          ? _HomeBody(todayLabel: _todayLabel)
          : const CalendarScreen(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _tabIndex,
      onTap: (i) => setState(() => _tabIndex = i),
      backgroundColor: AppColors.bgCard,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12),
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.wb_sunny_outlined),
          activeIcon: Icon(Icons.wb_sunny),
          label: 'Bu gün',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month),
          label: 'Tarixçə',
        ),
      ],
    );
  }
}

// ─── HOME BODY ────────────────────────────────────────────────────────────────

class _HomeBody extends ConsumerWidget {
  final String todayLabel;
  const _HomeBody({required this.todayLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(amalProvider);

    return SafeArea(
      child: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(child: Text('Xəta: $e')),
        data: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(state: state, todayLabel: todayLabel),
            Expanded(child: _AmalList(state: state)),
          ],
        ),
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AmalState state;
  final String todayLabel;
  const _Header({required this.state, required this.todayLabel});

  @override
  Widget build(BuildContext context) {
    final total = state.totalCount;
    final done = state.completedCount;
    final progress = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
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
                      todayLabel,
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
                builder: (ctx) {
                  return IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () {
                      final container = ProviderScope.containerOf(ctx);
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(builder: (_) => const ManageScreen()),
                      ).then(
                        (_) => container.read(amalProvider.notifier).refresh(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── AMAL LIST ────────────────────────────────────────────────────────────────

class _AmalList extends ConsumerWidget {
  final AmalState state;
  const _AmalList({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.amals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 52,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 14),
            Text(
              'Hələ əməl yoxdur.\nSağ üstdəki ⚙️ ilə əlavə et.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: AppColors.textHint,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: state.amals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final amal = state.amals[i];
        final record = state.records[amal.id];
        final streak = state.streaks[amal.id] ?? 0;

        return _AmalCard(
          amal: amal,
          record: record,
          streak: streak,
          onCheckboxTap: () =>
              ref.read(amalProvider.notifier).completeCheckbox(amal.id),
          onCounterTap: () =>
              ref.read(amalProvider.notifier).incrementCounter(amal.id),
          onTextTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TextScreen(amal: amal, record: record),
            ),
          ).then((_) => ref.read(amalProvider.notifier).refresh()),
        );
      },
    );
  }
}

// ─── AMAL CARD ────────────────────────────────────────────────────────────────

class _AmalCard extends StatelessWidget {
  final Amal amal;
  final AmalRecord? record;
  final int streak;
  final VoidCallback onCheckboxTap;
  final VoidCallback onCounterTap;
  final VoidCallback onTextTap;

  const _AmalCard({
    required this.amal,
    required this.record,
    required this.streak,
    required this.onCheckboxTap,
    required this.onCounterTap,
    required this.onTextTap,
  });

  bool get _done => record?.isCompleted ?? false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: amal.type == AmalType.text ? onTextTap : null,
      child: AnimatedOpacity(
        opacity: _done ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _buildLeading(),
              const SizedBox(width: 12),
              Expanded(child: _buildMiddle()),
              if (amal.type == AmalType.text)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LEADING ──────────────────────────────────────────────────────────────

  Widget _buildLeading() {
    switch (amal.type) {
      case AmalType.checkbox:
        return GestureDetector(
          onTap: _done ? null : onCheckboxTap,
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
        final done = record?.countDone ?? 0;
        final target = amal.countTarget ?? 1;

        return GestureDetector(
          onTap: _done ? null : onCounterTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _done
                ? const Icon(Icons.check, color: AppColors.accent, size: 18)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: AppColors.accent, size: 15),
                      const SizedBox(width: 2),
                      Text(
                        '$done/$target',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
          ),
        );

      case AmalType.text:
        return Icon(
          _done ? Icons.menu_book : Icons.menu_book_outlined,
          color: _done ? AppColors.accent : AppColors.textSecondary,
          size: 24,
        );
    }
  }

  // ─── MIDDLE ───────────────────────────────────────────────────────────────

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
      ],
    );
  }
}
