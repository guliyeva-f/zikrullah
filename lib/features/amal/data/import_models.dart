import '../domain/amal.dart';
import '../domain/amal_record.dart';

class AmalConflict {
  final Amal existing;
  final Amal incoming;
  final int existingStreak;
  final int existingCompletedDays;
  bool useIncoming;

  AmalConflict({
    required this.existing,
    required this.incoming,
    required this.existingStreak,
    required this.existingCompletedDays,
    this.useIncoming = false,
  });
}

class ImportPreview {
  final List<Amal> newAmals;
  final List<AmalConflict> conflicts;
  final int identicalCount;
  final List<AmalRecord> records;

  const ImportPreview({
    required this.newAmals,
    required this.conflicts,
    required this.identicalCount,
    required this.records,
  });

  bool get isEmpty => newAmals.isEmpty && conflicts.isEmpty;
}

sealed class PreviewResult {}

class PreviewCancelled extends PreviewResult {}

class PreviewInvalid extends PreviewResult {}

class PreviewError extends PreviewResult {}

class PreviewReady extends PreviewResult {
  final ImportPreview preview;
  PreviewReady(this.preview);
}
