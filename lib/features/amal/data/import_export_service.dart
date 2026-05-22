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

enum ImportResult { success, cancelled, invalid, error }

class ImportExportService {
  ImportExportService._();
  static final ImportExportService instance = ImportExportService._();

  final _repo = AmalRepository();

  // ─── EXPORT ──────────────────────────────────────────────────────────────

  Future<bool> exportData() async {
    try {
      final amals = await _repo.getAllAmals();
      final records = await _repo.getAllRecords();

      final jsonStr = const JsonEncoder.withIndent('  ').convert({
        'version': 2,
        'exported_at': DateTime.now().toIso8601String(),
        'amals': amals.map((a) => a.toJson()).toList(),
        'records': records.map((r) => r.toMap()).toList(),
      });

      // path_provider olmadan — DB qovluğuna yazırıq
      final dbDir = await getDatabasesPath();
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filePath = p.join(dbDir, 'amal_yedeyi_$stamp.json');

      await File(filePath).writeAsString(jsonStr, flush: true);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/json')],
          subject: 'Əməl Yedəyi',
        ),
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('Export xətası: $e');
      return false;
    }
  }

  // ─── IMPORT ──────────────────────────────────────────────────────────────

  Future<ImportResult> importData() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (picked == null) return ImportResult.cancelled;

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
        return ImportResult.invalid;
      }

      final amals = (data['amals'] as List)
          .map((j) => Amal.fromJson(j as Map<String, dynamic>))
          .toList();

      final records = (data['records'] as List? ?? [])
          .map((j) => AmalRecord.fromMap(j as Map<String, dynamic>))
          .toList();

      await _repo.importData(amals: amals, records: records);
      return ImportResult.success;
    } on FormatException {
      return ImportResult.invalid;
    } catch (e) {
      debugPrint('Import xətası: $e');
      return ImportResult.error;
    }
  }
}
