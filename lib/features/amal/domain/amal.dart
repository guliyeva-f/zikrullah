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

  const Amal({
    required this.id,
    required this.title,
    required this.type,
    this.countTarget,
    this.content,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
  });

  factory Amal.fromMap(Map<String, dynamic> map) {
    return Amal(
      id:          map['id'] as int,
      title:       map['title'] as String,
      type:        AmalType.values.firstWhere((e) => e.name == map['type']),
      countTarget: map['count_target'] as int?,
      content:     map['content'] as String?,
      sortOrder:   map['sort_order'] as int,
      isActive:    (map['is_active'] as int) == 1,
      createdAt:   map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'title':        title,
        'type':         type.name,
        'count_target': countTarget,
        'content':      content,
        'sort_order':   sortOrder,
        'is_active':    isActive ? 1 : 0,
        'created_at':   createdAt,
      };

  Amal copyWith({
    int? id,
    String? title,
    AmalType? type,
    int? countTarget,
    String? content,
    int? sortOrder,
    bool? isActive,
    String? createdAt,
  }) =>
      Amal(
        id:          id ?? this.id,
        title:       title ?? this.title,
        type:        type ?? this.type,
        countTarget: countTarget ?? this.countTarget,
        content:     content ?? this.content,
        sortOrder:   sortOrder ?? this.sortOrder,
        isActive:    isActive ?? this.isActive,
        createdAt:   createdAt ?? this.createdAt,
      );
}