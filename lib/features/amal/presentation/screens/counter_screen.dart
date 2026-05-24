import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/amal.dart';
import '../providers/amal_provider.dart';

class CounterScreen extends ConsumerWidget {
  final Amal amal;
  const CounterScreen({super.key, required this.amal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(amalProvider).value;
    final record = state?.records[amal.id];
    final count = record?.countDone ?? 0;
    final target = amal.countTarget ?? 1;
    final done = record?.isCompleted ?? false;
    final progress = (count / target).clamp(0.0, 1.0);

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
          amal.title,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Böyük say ───────────────────────────────────────────────
              Text(
                '$count',
                style: GoogleFonts.nunito(
                  fontSize: 88,
                  fontWeight: FontWeight.w700,
                  color: done ? AppColors.accent : AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'hədəf: $target',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // ── Progress ─────────────────────────────────────────────────
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
              const SizedBox(height: 40),
              // ── + düymələr ───────────────────────────────────────────────
              Row(
                children: [
                  _CounterBtn(
                    label: '+1',
                    onTap: done
                        ? null
                        : () => ref
                              .read(amalProvider.notifier)
                              .incrementCounterBy(amal.id, 1),
                  ),
                  const SizedBox(width: 10),
                  _CounterBtn(
                    label: '+10',
                    onTap: done
                        ? null
                        : () => ref
                              .read(amalProvider.notifier)
                              .incrementCounterBy(amal.id, 10),
                  ),
                  const SizedBox(width: 10),
                  _CounterBtn(
                    label: '+100',
                    onTap: done
                        ? null
                        : () => ref
                              .read(amalProvider.notifier)
                              .incrementCounterBy(amal.id, 100),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── − düymələr ───────────────────────────────────────────────
              Row(
                children: [
                  _CounterBtn(
                    label: '−1',
                    muted: true,
                    onTap: count > 0
                        ? () => ref
                              .read(amalProvider.notifier)
                              .decrementCounterBy(amal.id, 1)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  _CounterBtn(
                    label: '−10',
                    muted: true,
                    onTap: count >= 10
                        ? () => ref
                              .read(amalProvider.notifier)
                              .decrementCounterBy(amal.id, 10)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const Spacer(),
              // ── Tamamla / Geri al ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: done
                        ? AppColors.bgElevated
                        : AppColors.accent,
                    foregroundColor: done
                        ? AppColors.textSecondary
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      ref.read(amalProvider.notifier).completeCheckbox(amal.id),
                  child: Text(
                    done ? 'Geri al' : 'Tamamla',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool muted;

  const _CounterBtn({required this.label, this.onTap, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: onTap == null
                  ? AppColors.textHint
                  : muted
                  ? AppColors.textSecondary
                  : AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}
