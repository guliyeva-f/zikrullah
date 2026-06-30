import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/amal.dart';
import '../providers/amal_provider.dart';
class CounterScreen extends ConsumerStatefulWidget {
  final Amal amal;
  const CounterScreen({super.key, required this.amal});
  @override
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}
class _CounterScreenState extends ConsumerState<CounterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  bool _hintDismissed = false;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  void _onTap() {
    HapticFeedback.lightImpact();
    ref.read(amalProvider.notifier).incrementCounterBy(widget.amal.id, 1);
    if (!_hintDismissed) setState(() => _hintDismissed = true);
    _pulseController.forward(from: 0).then((_) => _pulseController.reverse());
  }
  void _onLongPress() {
    HapticFeedback.mediumImpact();
    ref.read(amalProvider.notifier).decrementCounterBy(widget.amal.id, 1);
    _pulseController.forward(from: 0).then((_) => _pulseController.reverse());
  }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(amalProvider).value;
    final record = state?.records[widget.amal.id];
    final count = record?.countDone ?? 0;
    final target = widget.amal.countTarget ?? 1;
    final done = record?.isCompleted ?? false;
    final overTarget = done && count > target;
    final progress = (count / target).clamp(0.0, 1.0);
    final showHint = !done && count == 0 && !_hintDismissed;
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
                  ref
                      .read(amalProvider.notifier)
                      .completeCheckbox(widget.amal.id);
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
                child: const Text(
                  'Bitirdim',
                  style: TextStyle(
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
        onTap: _onTap,
        onLongPress: count <= 0 ? null : _onLongPress,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Zikr başlığı ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    widget.amal.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                // ── Dairəvi progress + say ─────────────────────────────────
                ScaleTransition(
                  scale: _pulseAnim,
                  child: SizedBox(
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
                            progressColor: done
                                ? AppColors.success
                                : AppColors.accent,
                            strokeWidth: 11,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Əsas say ──────────────────────────────────
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 78,
                                fontWeight: FontWeight.w700,
                                color: done
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                                height: 1,
                              ),
                              child: Text('$count'),
                            ),
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: overTarget
                                  ? Text(
                                      'hədəfdən ${count - target} artıq etdin ✨',
                                      key: const ValueKey('over'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accentLight,
                                      ),
                                    )
                                  : done
                                  ? const Text(
                                      'اَلْحَمْدُ لِلّٰهِ',
                                      key: ValueKey('done'),
                                      style: TextStyle(
                                        fontFamily: 'Scheherazade New',
                                        fontSize: 24,
                                        color: AppColors.success,
                                        height: 1.4,
                                      ),
                                    )
                                  : Text(
                                      '/ $target dəfə',
                                      key: const ValueKey('progress'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // ── First-tap hint ─────────────────────────────────────────
                AnimatedOpacity(
                  opacity: showHint ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: const IgnorePointer(
                    child: Text(
                      '👆 hər tap bir zikr',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                // ── Long-press hint ────────────────────────────────────────
                AnimatedOpacity(
                  opacity: (!done && count > 0) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'uzun bas — geri al',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint.withValues(alpha: 0.6),
                          letterSpacing: 0.1,
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
