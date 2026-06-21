enum AmalType { checkbox, counter, text }

class Amal {
  final int id;
  final String title;
  final AmalType type;
  final int? countTarget;
  final String? content;
  final int sortOrder;
  final bool isActive;
  final String createdAt;
  final String? intention;
  final int? durationDays;

  const Amal({
    required this.id,
    required this.title,
    required this.type,
    this.countTarget,
    this.content,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    this.intention,
    this.durationDays,
  });

  // ─── COMPUTED ─────────────────────────────────────────────────────────────

  DateTime get _startDate => DateTime.parse(createdAt.substring(0, 10));
  
  DateTime? get endDate {
    if (durationDays == null) return null;
    return _startDate.add(Duration(days: durationDays! - 1));
  }

  bool get isExpired {
    if (endDate == null) return false;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    return todayNormalized.isAfter(endDate!);
  }

  int get daysSinceStart {
    final today = DateTime.now();
    return DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(_startDate).inDays;
  }

  int? get remainingDays {
    if (durationDays == null) return null;
    final r = durationDays! - daysSinceStart;
    return r < 0 ? 0 : r;
  }

  int remainingDaysFor(int completedCount) {
    if (durationDays == null) return 0;
    final r = durationDays! - completedCount;
    return r < 0 ? 0 : r;
  }

  // ─── SERIALIZATION ────────────────────────────────────────────────────────

  factory Amal.fromMap(Map<String, dynamic> map) => Amal(
    id: map['id'] as int,
    title: map['title'] as String,
    type: AmalType.values.firstWhere((e) => e.name == map['type']),
    countTarget: map['count_target'] as int?,
    content: map['content'] as String?,
    sortOrder: map['sort_order'] as int,
    isActive: (map['is_active'] as int) == 1,
    createdAt: map['created_at'] as String,
    intention: map['intention'] as String?,
    durationDays: map['duration_days'] as int?,
  );

  static const _unset = Object();

  Amal copyWith({
    int? id,
    String? title,
    AmalType? type,
    Object? countTarget = _unset,
    Object? content = _unset,
    int? sortOrder,
    bool? isActive,
    String? createdAt,
    Object? intention = _unset,
    Object? durationDays = _unset,
  }) => Amal(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    countTarget: identical(countTarget, _unset)
        ? this.countTarget
        : countTarget as int?,
    content: identical(content, _unset) ? this.content : content as String?,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    intention: identical(intention, _unset)
        ? this.intention
        : intention as String?,
    durationDays: identical(durationDays, _unset)
        ? this.durationDays
        : durationDays as int?,
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'type': type.name,
    'count_target': countTarget,
    'content': content,
    'sort_order': sortOrder,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt,
    'intention': intention,
    'duration_days': durationDays,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'count_target': countTarget,
    'content': content,
    'sort_order': sortOrder,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt,
    'intention': intention,
    'duration_days': durationDays,
  };

  factory Amal.fromJson(Map<String, dynamic> json) => Amal.fromMap(json);
}
