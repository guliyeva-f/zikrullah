import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/amal.dart';
import '../domain/amal_record.dart';
import 'amal_repository.dart';
import 'import_models.dart';
export 'import_models.dart';
enum ImportResult { success, partial, cancelled, invalid, error }
class ImportExportService {
  ImportExportService._();
  static final ImportExportService instance = ImportExportService._();
  final _repo = AmalRepository();
  // ─── EXPORT ──────────────────────────────────────────────────────────────
  Future<({String path, bool saved})?> exportData() async {
    try {
      final amals = await _repo.getAllAmals();
      final records = await _repo.getAllRecords();
      final jsonStr = const JsonEncoder.withIndent('  ').convert({
        'version': 2,
        'exported_at': DateTime.now().toIso8601String(),
        'amals': amals.map((a) => a.toJson()).toList(),
        'records': records.map((r) => r.toMap()).toList(),
      });
      final fileName = _buildFileName();
      final file = await _saveToDownloads(fileName, jsonStr);
      if (file == null) return null;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/octet-stream')],
          subject: 'Zikrullah yedəyi',
        ),
      );
      return (path: file.path, saved: true);
    } catch (e) {
      debugPrint('Export xətası: $e');
      return null;
    }
  }
  String _buildFileName() {
    final now = DateTime.now();
    const az = [
      'yan',
      'fev',
      'mar',
      'apr',
      'may',
      'iyn',
      'iyl',
      'avq',
      'sen',
      'okt',
      'noy',
      'dek',
    ];
    final month = az[now.month - 1];
    return 'zikrullah_${now.day}$month${now.year}.json';
  }
  Future<File?> _saveToDownloads(String fileName, String content) async {
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      if (dir == null) return null;
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content, flush: true);
      return file;
    } catch (e) {
      debugPrint('Downloads yazma xətası: $e');
      return null;
    }
  }
  // ─── IMPORT PREVIEW ──────────────────────────────────────────────────────
  Future<PreviewResult> previewImport() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (picked == null) return PreviewCancelled();
      String jsonStr;
      final path = picked.files.single.path;
      if (path != null) {
        jsonStr = await File(path).readAsString();
      } else {
        final bytes = await picked.files.single.readAsBytes();
        jsonStr = utf8.decode(bytes);
      }
      final data = jsonDecode(jsonStr);
      if (data is! Map<String, dynamic> ||
          data['amals'] == null ||
          data['version'] == null) {
        return PreviewInvalid();
      }
      final rawAmals = data['amals'];
      if (rawAmals is! List) return PreviewInvalid();
      final incomingAmals = <Amal>[];
      for (final j in rawAmals) {
        if (j is! Map<String, dynamic>) return PreviewInvalid();
        if (j['title'] is! String ||
            j['type'] is! String ||
            j['created_at'] is! String) {
          return PreviewInvalid();
        }
        try {
          incomingAmals.add(Amal.fromJson(j));
        } catch (_) {
          return PreviewInvalid();
        }
      }
      final incomingRecords = <AmalRecord>[];
      for (final j in (data['records'] as List? ?? [])) {
        if (j is! Map<String, dynamic>) continue;
        try {
          incomingRecords.add(AmalRecord.fromMap(j));
        } catch (_) {
          continue;
        }
      }
      final existingAmals = await _repo.getAllAmals();
      final existingMap = {
        for (final a in existingAmals) '${a.title}__${a.type.name}': a,
      };
      final newAmals = <Amal>[];
      final conflicts = <AmalConflict>[];
      int identicalCount = 0;
      for (final incoming in incomingAmals) {
        final key = '${incoming.title}__${incoming.type.name}';
        final existing = existingMap[key];
        if (existing == null) {
          newAmals.add(incoming);
        } else if (_isIdentical(existing, incoming)) {
          identicalCount++;
        } else {
          final streak = await _repo.calculateStreak(existing.id);
          final completed = await _repo.countCompletedDays(existing.id);
          conflicts.add(
            AmalConflict(
              existing: existing,
              incoming: incoming,
              existingStreak: streak,
              existingCompletedDays: completed,
            ),
          );
        }
      }
      return PreviewReady(
        ImportPreview(
          newAmals: newAmals,
          conflicts: conflicts,
          identicalCount: identicalCount,
          records: incomingRecords,
        ),
      );
    } on FormatException {
      return PreviewInvalid();
    } catch (e) {
      debugPrint('Preview xətası: $e');
      return PreviewError();
    }
  }
  bool _isIdentical(Amal a, Amal b) =>
      a.countTarget == b.countTarget &&
      a.content == b.content &&
      a.intention == b.intention &&
      a.durationDays == b.durationDays &&
      a.isActive == b.isActive;
  // ─── IMPORT APPLY ─────────────────────────────────────────────────────────
  Future<ImportResult> applyImport(ImportPreview preview) async {
    try {
      final result = await _repo.applyImport(preview: preview);
      if (result.errors.isNotEmpty) {
        debugPrint(
          'Import qismən: ${result.imported} əlavə, '
          '${result.updated} yeniləndi, ${result.skipped} atlandı, '
          'xəta: ${result.errors}',
        );
        return result.imported > 0 || result.updated > 0
            ? ImportResult.partial
            : ImportResult.error;
      }
      return ImportResult.success;
    } catch (e) {
      debugPrint('Apply import xətası: $e');
      return ImportResult.error;
    }
  }
}
