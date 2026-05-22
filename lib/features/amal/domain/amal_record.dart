class AmalRecord {
  final int? id;
  final int amalId;
  final String recordDate;
  final bool isCompleted;
  final int countDone;
  final String? completedAt;

  const AmalRecord({
    this.id,
    required this.amalId,
    required this.recordDate,
    this.isCompleted = false,
    this.countDone = 0,
    this.completedAt,
  });

  factory AmalRecord.fromMap(Map<String, dynamic> map) {
    return AmalRecord(
      id: map['id'] as int?,
      amalId: map['amal_id'] as int,
      recordDate: map['record_date'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      countDone: map['count_done'] as int,
      completedAt: map['completed_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'amal_id': amalId,
    'record_date': recordDate,
    'is_completed': isCompleted ? 1 : 0,
    'count_done': countDone,
    'completed_at': completedAt,
  };

  AmalRecord copyWith({
    int? id,
    int? amalId,
    String? recordDate,
    bool? isCompleted,
    int? countDone,
    String? completedAt,
  }) => AmalRecord(
    id: id ?? this.id,
    amalId: amalId ?? this.amalId,
    recordDate: recordDate ?? this.recordDate,
    isCompleted: isCompleted ?? this.isCompleted,
    countDone: countDone ?? this.countDone,
    completedAt: completedAt ?? this.completedAt,
  );
}
