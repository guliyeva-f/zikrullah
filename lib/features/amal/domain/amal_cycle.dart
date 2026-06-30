class AmalCycle {
  final int id;
  final int amalId;
  final String startedAt;
  final String? endedAt;
  final int daysDone;
  const AmalCycle({
    required this.id,
    required this.amalId,
    required this.startedAt,
    this.endedAt,
    required this.daysDone,
  });
  bool get isOngoing => endedAt == null;
  factory AmalCycle.fromMap(Map<String, dynamic> map) => AmalCycle(
    id: map['id'] as int,
    amalId: map['amal_id'] as int,
    startedAt: map['started_at'] as String,
    endedAt: map['ended_at'] as String?,
    daysDone: map['days_done'] as int,
  );
  Map<String, dynamic> toMap() => {
    'amal_id': amalId,
    'started_at': startedAt,
    'ended_at': endedAt,
    'days_done': daysDone,
  };
}
