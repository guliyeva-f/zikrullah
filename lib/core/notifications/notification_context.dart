enum NotifSlot { morning, noon, evening, night }
class AmalSnapshot {
  final String title;
  final String? intention;
  final int currentStreak;
  final int? remainingDurationDays;
  const AmalSnapshot({
    required this.title,
    this.intention,
    required this.currentStreak,
    this.remainingDurationDays,
  });
  Map<String, dynamic> toJson() => {
    'title': title,
    'intention': intention,
    'currentStreak': currentStreak,
    'remainingDurationDays': remainingDurationDays,
  };
  factory AmalSnapshot.fromJson(Map<String, dynamic> json) => AmalSnapshot(
    title: json['title'] as String,
    intention: json['intention'] as String?,
    currentStreak: json['currentStreak'] as int? ?? 0,
    remainingDurationDays: json['remainingDurationDays'] as int?,
  );
}
enum NotifCategory {
  allCompleted,
  singleAmal,
  intention,
  streak,
  duration,
  multipleAmals,
  spiritual,
  verseHadith,
  returnReminder,
}
class NotifPick {
  final NotifCategory category;
  final AmalSnapshot? amal;
  final int?
  streakValue; 
  final int? remainingDays; 
  final int remainingCount;
  final List<String> remainingTitles;
  const NotifPick({
    required this.category,
    this.amal,
    this.streakValue,
    this.remainingDays,
    this.remainingCount = 0,
    this.remainingTitles = const [],
  });
}
class NotificationContext {
  final NotifSlot slot;
  final List<AmalSnapshot> remaining;
  final int totalCount;
  final int inactiveDays;
  const NotificationContext({
    required this.slot,
    required this.remaining,
    required this.totalCount,
    this.inactiveDays = 0,
  });
  int get remainingCount => remaining.length;
  bool get allCompleted => totalCount > 0 && remaining.isEmpty;
  List<String> get remainingTitles => remaining.map((a) => a.title).toList();
}
