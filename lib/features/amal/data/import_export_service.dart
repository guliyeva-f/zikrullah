import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

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

  Future<bool> exportData() async {
    File? tempFile;
    try {
      final amals = await _repo.getAllAmals();
      final records = await _repo.getAllRecords();

      final jsonStr = const JsonEncoder.withIndent('  ').convert({
        'version': 2,
        'exported_at': DateTime.now().toIso8601String(),
        'amals': amals.map((a) => a.toJson()).toList(),
        'records': records.map((r) => r.toMap()).toList(),
      });

      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      String tempDirPath;
      try {
        tempDirPath = Directory.systemTemp.path;
      } catch (_) {
        tempDirPath = await getDatabasesPath();
      }

      final filePath = p.join(tempDirPath, 'amal_yedeyi_$stamp.json');
      tempFile = File(filePath);
      await tempFile.writeAsString(jsonStr, flush: true);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/json')],
          subject: 'Əməl Yedəyi',
        ),
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Export xətası: $e');
      return false;
    } finally {
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('Temp fayl silmə xətası: $e');
      }
    }
  }

  // ─── IMPORT PREVIEW ──────────────────────────────────────────────────────

  /// Faylı oxuyur, DB ilə müqayisə edir, PreviewResult qaytarır.
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

      // Sizin gücləndirilmiş validasiya
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

      // DB ilə müqayisə
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

  /// İki əməlin məzmun sahələrini müqayisə edir (id, sortOrder, createdAt istisna)
  bool _isIdentical(Amal a, Amal b) =>
      a.countTarget == b.countTarget &&
      a.content == b.content &&
      a.intention == b.intention &&
      a.durationDays == b.durationDays &&
      a.isActive == b.isActive;

  // ─── IMPORT APPLY ─────────────────────────────────────────────────────────

  /// İstifadəçi seçimlərini tətbiq edir
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
