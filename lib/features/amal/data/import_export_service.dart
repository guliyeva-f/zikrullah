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

  /// BUG #15 DÜZƏLİŞİ:
  /// Əvvəlki kod faylı getDatabasesPath() qovluğuna yazırdı — bu
  /// /data/data/com.example.amal_app/databases/ daxili sistem qovluğudur.
  /// Fayl paylaşımdan sonra orada qalırdı, istifadəçi onu görə bilmirdi.
  ///
  /// Həll:
  /// 1. Directory.systemTemp — müvəqqəti qovluq istifadə edilir
  /// 2. SharePlus ilə paylaşımdan SONRA fayl silinir (cleanup)
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

      // FIX #15: getDatabasesPath() → Directory.systemTemp
      // Müvəqqəti qovluq — paylaşımdan sonra silinir
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      String tempDirPath;
      try {
        tempDirPath = Directory.systemTemp.path;
      } catch (_) {
        // Fallback: əgər systemTemp əlçatmazdırsa DB qovluğuna yaz
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

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('Export xətası: $e');
      return false;
    } finally {
      // FIX #15: paylaşımdan sonra müvəqqəti faylı sil
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('Temp fayl silmə xətası: $e');
      }
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
