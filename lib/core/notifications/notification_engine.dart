import 'dart:math';
import 'notification_context.dart';
class NotificationEngine {
  NotificationEngine._();
  static const milestones = [7, 40, 100, 365];
  static const _verseChanceDay = 12;
  static const _verseChanceNight = 25;
  static const _spiritualChanceDay = 15;
  static const _spiritualChanceNight = 35;
  static final Random _random = Random();
  static NotifPick decide(NotificationContext ctx) {
    if (ctx.allCompleted) {
      return const NotifPick(category: NotifCategory.allCompleted);
    }
    if (ctx.remaining.isEmpty) {
      return const NotifPick(category: NotifCategory.spiritual);
    }
    if (ctx.remainingCount == 1) {
      return NotifPick(
        category: NotifCategory.singleAmal,
        amal: ctx.remaining.first,
      );
    }
    for (final a in ctx.remaining) {
      final next = a.currentStreak + 1;
      if (a.currentStreak > 0 && milestones.contains(next)) {
        return NotifPick(
          category: NotifCategory.streak,
          amal: a,
          streakValue: next,
        );
      }
    }
    for (final a in ctx.remaining) {
      final r = a.remainingDurationDays;
      if (r != null && r > 0 && r <= 7) {
        return NotifPick(
          category: NotifCategory.duration,
          amal: a,
          remainingDays: r,
        );
      }
    }
    final withIntention = ctx.remaining
        .where((a) => (a.intention ?? '').trim().isNotEmpty)
        .toList();
    if (withIntention.isNotEmpty) {
      final chosen = withIntention[_random.nextInt(withIntention.length)];
      return NotifPick(category: NotifCategory.intention, amal: chosen);
    }
    return _fallback(ctx);
  }
  static NotifPick _fallback(NotificationContext ctx) {
    final roll = _random.nextInt(100);
    final isNight = ctx.slot == NotifSlot.night;
    final spiritualChance = isNight
        ? _spiritualChanceNight
        : _spiritualChanceDay;
    final verseChance = isNight ? _verseChanceNight : _verseChanceDay;
    if (roll < spiritualChance) {
      return const NotifPick(category: NotifCategory.spiritual);
    }
    if (roll < spiritualChance + verseChance) {
      return const NotifPick(category: NotifCategory.verseHadith);
    }
    return NotifPick(
      category: NotifCategory.multipleAmals,
      remainingCount: ctx.remainingCount,
      remainingTitles: ctx.remainingTitles,
    );
  }
}
