import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final reachedTarget = count >= target;

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
        actions: [
          if (!done)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(amalProvider.notifier).completeCheckbox(amal.id);
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Bitdi',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: done
            ? null
            : () {
                HapticFeedback.lightImpact();
                ref.read(amalProvider.notifier).incrementCounterBy(amal.id, 1);
              },
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Zikr başlığı ──────────────────────────────────────────
                Text(
                  amal.title,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Dairəvi progress + say ─────────────────────────────────
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(240, 240),
                        painter: _RingPainter(
                          progress: progress,
                          trackColor: AppColors.bgElevated,
                          progressColor: reachedTarget
                              ? AppColors.success
                              : AppColors.accent,
                          strokeWidth: 10,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.nunito(
                              fontSize: 78,
                              fontWeight: FontWeight.w700,
                              color: reachedTarget
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                              height: 1,
                            ),
                            child: Text('$count'),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'hədəf: $target',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    if (progress > 0) {
      paint.color = progressColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}
