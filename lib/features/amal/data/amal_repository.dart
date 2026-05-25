import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../domain/amal.dart';
import '../domain/amal_record.dart';
import 'package:flutter/foundation.dart';

class AmalRepository {
  final _dbHelper = DatabaseHelper();

  Future<Database> get _db async => _dbHelper.database;

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String get _today => _formatDate(DateTime.now());

  // ─── AMALS ────────────────────────────────────────────────────────────────

  Future<List<Amal>> getActiveAmals() async {
    final db = await _db;
    final maps = await db.query(
      'amals',
      where: 'is_active = 1',
      orderBy: 'sort_order ASC',
    );
    return maps.map(Amal.fromMap).toList();
  }

  Future<List<Amal>> getAllAmals() async {
    final db = await _db;
    final maps = await db.query('amals', orderBy: 'sort_order ASC');
    return maps.map(Amal.fromMap).toList();
  }

  Future<int> insertAmal(Amal amal) async {
    final db = await _db;
    return db.insert('amals', amal.toMap());
  }

  Future<void> updateAmal(Amal amal) async {
    final db = await _db;
    await db.update(
      'amals',
      amal.toMap(),
      where: 'id = ?',
      whereArgs: [amal.id],
    );
  }

  Future<void> deleteAmal(int id) async {
    final db = await _db;
    await db.delete('amals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSortOrders(List<Amal> amals) async {
    final db = await _db;
    final batch = db.batch();
    for (int i = 0; i < amals.length; i++) {
      batch.update(
        'amals',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [amals[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // ─── MÜDDƏTİ BITMIŞ ƏMƏLLƏR ──────────────────────────────────────────────

  Future<List<Amal>> archiveExpiredAmals() async {
    final db = await _db;
    final maps = await db.query(
      'amals',
      where: 'is_active = 1 AND duration_days IS NOT NULL',
    );
    final archived = <Amal>[];
    for (final m in maps) {
      final amal = Amal.fromMap(m);
      if (amal.isExpired) {
        await db.update(
          'amals',
          {'is_active': 0},
          where: 'id = ?',
          whereArgs: [amal.id],
        );
        archived.add(amal);
      }
    }
    return archived;
  }

  // ─── AMAL RECORDS ─────────────────────────────────────────────────────────

  Future<AmalRecord?> getRecord(int amalId, String date) async {
    final db = await _db;
    final maps = await db.query(
      'amal_records',
      where: 'amal_id = ? AND record_date = ?',
      whereArgs: [amalId, date],
    );
    return maps.isEmpty ? null : AmalRecord.fromMap(maps.first);
  }

  Future<List<AmalRecord>> getRecordsForDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'amal_records',
      where: 'record_date = ?',
      whereArgs: [date],
    );
    return maps.map(AmalRecord.fromMap).toList();
  }

  Future<void> upsertRecord(AmalRecord record) async {
    final db = await _db;
    await db.insert(
      'amal_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── HEATMAP ──────────────────────────────────────────────────────────────

  Future<Map<String, double>> getHeatmapData({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _db;
    final fromStr = _formatDate(from);
    final toStr = _formatDate(to);
    final amalRows = await db.rawQuery(
      'SELECT substr(created_at, 1, 10) AS created_date FROM amals',
    );
    final createdDates = amalRows
        .map((r) => r['created_date'] as String)
        .toList();

    if (createdDates.isEmpty) return {};
    final completedRows = await db.rawQuery(
      '''
      SELECT record_date, COUNT(*) AS cnt
      FROM amal_records
      WHERE record_date >= ? AND record_date <= ?
        AND is_completed = 1
      GROUP BY record_date
      ''',
      [fromStr, toStr],
    );

    final result = <String, double>{};
    for (final row in completedRows) {
      final date = row['record_date'] as String;
      final cnt = row['cnt'] as int;
      final totalOnDate = createdDates
          .where((d) => d.compareTo(date) <= 0)
          .length;

      if (totalOnDate > 0) {
        result[date] = (cnt / totalOnDate).clamp(0.0, 1.0);
      }
    }
    return result;
  }

  // ─── DETAIL SCREEN TƏQVİM ─────────────────────────────────────────────────

  Future<Map<String, bool>> getAmalCalendarMonth(
    int amalId,
    int year,
    int month,
  ) async {
    final db = await _db;
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'amal_records',
      where: 'amal_id = ? AND record_date LIKE ?',
      whereArgs: [amalId, '$prefix%'],
    );
    return {
      for (final m in maps)
        m['record_date'] as String: (m['is_completed'] as int) == 1,
    };
  }

  // ─── STREAK ───────────────────────────────────────────────────────────────
  Future<int> calculateStreak(int amalId) async {
    final db = await _db;
    final today = _today;
    final todayRecord = await getRecord(amalId, today);
    final completedToday = todayRecord?.isCompleted ?? false;

    final startDate = completedToday
        ? DateTime.now()
        : DateTime.now().subtract(const Duration(days: 1));

    final fromDate = _formatDate(startDate.subtract(const Duration(days: 364)));
    final toDate = _formatDate(startDate);

    final maps = await db.rawQuery(
      '''
    SELECT record_date, is_completed
    FROM amal_records
    WHERE amal_id = ?
      AND record_date >= ?
      AND record_date <= ?
      AND is_completed = 1
    ORDER BY record_date DESC
    ''',
      [amalId, fromDate, toDate],
    );

    final recordSet = {for (final m in maps) m['record_date'] as String};

    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final date = _formatDate(startDate.subtract(Duration(days: i)));
      if (recordSet.contains(date)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
  // ─── "GERİ QAYT" BİLDİRİŞİ ÜÇÜN ──────────────────────────────────────────

  Future<List<Amal>> getStreakBrokenAmals() async {
    final now = DateTime.now();
    final yesterday = _formatDate(now.subtract(const Duration(days: 1)));
    final sevenDaysAgo = _formatDate(now.subtract(const Duration(days: 8)));

    final amals = await getActiveAmals();
    if (amals.isEmpty) return [];

    final ids = amals.map((a) => a.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final db = await _db;

    // Dünən + son 7 gün (dünən daxil deyil) üçün tamamlanan recordları çək
    final maps = await db.rawQuery(
      '''
      SELECT amal_id, record_date
      FROM amal_records
      WHERE amal_id IN ($placeholders)
        AND record_date >= ? AND record_date <= ?
        AND is_completed = 1
      ''',
      [...ids, sevenDaysAgo, yesterday],
    );

    // hər əməl üçün tamamlanan günlər seti
    final completedDates = <int, Set<String>>{};
    for (final m in maps) {
      final amalId = m['amal_id'] as int;
      final date = m['record_date'] as String;
      completedDates.putIfAbsent(amalId, () => {}).add(date);
    }

    final broken = <Amal>[];
    for (final amal in amals) {
      final dates = completedDates[amal.id] ?? {};
      final yesterdayFailed = !dates.contains(yesterday);
      // Son 7 gün içində (dünən xaric) ən az bir gün tamamlanıbsa streak var idi
      final hadStreakRecently = dates.any((d) => d != yesterday);
      if (yesterdayFailed && hadStreakRecently) {
        broken.add(amal);
      }
    }
    return broken;
  }

  // ─── IMPORT / EXPORT ──────────────────────────────────────────────────────

  Future<List<AmalRecord>> getAllRecords() async {
    final db = await _db;
    final maps = await db.query(
      'amal_records',
      orderBy: 'amal_id ASC, record_date ASC',
    );
    return maps.map(AmalRecord.fromMap).toList();
  }

  Future<({int imported, int skipped, List<String> errors})> importData({
    required List<Amal> amals,
    required List<AmalRecord> records,
  }) async {
    final db = await _db;
    final idMap = <int, int>{}; // köhnə id → yeni DB id
    int imported = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final amal in amals) {
      final mapWithoutId = Map<String, dynamic>.from(amal.toJson())
        ..remove('id');

      try {
        final newId = await db.insert(
          'amals',
          mapWithoutId,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        idMap[amal.id] = newId;
        imported++;
      } catch (e) {
        debugPrint('Amal insert xətası [${amal.title}]: $e');
        // Eyni adlı əməl artıq varsa mövcud id-ni götür
        try {
          final existing = await db.query(
            'amals',
            columns: ['id'],
            where: 'title = ? AND type = ?',
            whereArgs: [amal.title, amal.type.name],
            limit: 1,
          );
          if (existing.isNotEmpty) {
            idMap[amal.id] = existing.first['id'] as int;
            skipped++;
          } else {
            errors.add(amal.title);
          }
        } catch (e2) {
          debugPrint('Mövcud əməl axtarış xətası [${amal.title}]: $e2');
          errors.add(amal.title);
        }
      }
    }

    if (records.isNotEmpty) {
      final batch = db.batch();
      for (final rec in records) {
        final actualAmalId = idMap[rec.amalId];
        if (actualAmalId == null) continue; // əməl import edilməyib

        final map = rec.toMap()
          ..['amal_id'] = actualAmalId
          ..remove('id'); // record ID konfliktini önlə

        batch.insert(
          'amal_records',
          map,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }

    return (imported: imported, skipped: skipped, errors: errors);
  }

  // ─── STATİSTİKA ───────────────────────────────────────────────────────────

  Future<int> countCompletedDays(int amalId) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt FROM amal_records
      WHERE amal_id = ? AND is_completed = 1
      ''',
      [amalId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }
}
