import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../domain/amal.dart';
import '../domain/amal_record.dart';
import 'import_models.dart';
import 'package:flutter/foundation.dart';
import '../domain/amal_cycle.dart';

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
    return db.transaction((txn) async {
      final id = await txn.insert('amals', amal.toMap());
      if (amal.durationDays != null) {
        await txn.insert('amal_cycles', {
          'amal_id': id,
          'started_at': amal.createdAt,
          'ended_at': null,
          'days_done': 0,
        });
      }
      return id;
    });
  }

  Future<void> updateAmal(Amal amal) async {
    final db = await _db;
    await db.update(
      'amals',
      amal.toMap(),
      where: 'id = ?',
      whereArgs: [amal.id],
    );
    if (amal.durationDays != null) {
      final existing = await db.query(
        'amal_cycles',
        where: 'amal_id = ? AND ended_at IS NULL',
        whereArgs: [amal.id],
      );
      if (existing.isEmpty) {
        await db.insert('amal_cycles', {
          'amal_id': amal.id,
          'started_at': amal.effectiveCycleStart,
          'ended_at': null,
          'days_done': 0,
        });
      }
    }
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

  Future<int> getNextSortOrder() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next FROM amals',
    );
    return (result.first['next'] as int?) ?? 0;
  }

  // ─── MÜDDƏTİ BİTMİŞ ƏMƏLLƏR ──────────────────────────────────────────────

  Future<List<Amal>> archiveCompletedAmals() async {
    final db = await _db;
    final maps = await db.query(
      'amals',
      where: 'is_active = 1 AND duration_days IS NOT NULL',
    );
    final archived = <Amal>[];
    for (final m in maps) {
      final amal = Amal.fromMap(m);
      final cycleStart = amal.effectiveCycleStart.substring(0, 10);
      final completed = await countCompletedDays(amal.id, fromDate: cycleStart);
      if (completed >= amal.durationDays!) {
        final archivedAtStr = '$_today 00:00:00';
        await db.update(
          'amals',
          {'is_active': 0, 'archived_at': archivedAtStr},
          where: 'id = ?',
          whereArgs: [amal.id],
        );
        await db.update(
          'amal_cycles',
          {'ended_at': archivedAtStr, 'days_done': completed},
          where: 'amal_id = ? AND ended_at IS NULL',
          whereArgs: [amal.id],
        );
        archived.add(amal.copyWith(isActive: false, archivedAt: archivedAtStr));
      }
    }
    return archived;
  }

  Future<List<Amal>> processStrictBreaks() async {
    final db = await _db;
    final today = _today;
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    final maps = await db.query(
      'amals',
      where: 'is_active = 1 AND duration_days IS NOT NULL AND allow_break = 0',
    );

    final broken = <Amal>[];

    for (final m in maps) {
      final amal = Amal.fromMap(m);
      final cycleStartStr = amal.effectiveCycleStart.substring(0, 10);

      if (cycleStartStr == today) continue;
      if (cycleStartStr.compareTo(yesterday) >= 0) continue;

      final yesterdayRecord = await db.query(
        'amal_records',
        where: 'amal_id = ? AND record_date = ? AND is_completed = 1',
        whereArgs: [amal.id, yesterday],
      );
      if (yesterdayRecord.isNotEmpty) continue;

      final completedInCycle = await countCompletedDays(
        amal.id,
        fromDate: cycleStartStr,
      );
      if (completedInCycle == 0) continue;

      final newCycleStart = '$today 00:00:00';
      await db.transaction((txn) async {
        await txn.update(
          'amal_cycles',
          {'ended_at': newCycleStart, 'days_done': completedInCycle},
          where: 'amal_id = ? AND ended_at IS NULL',
          whereArgs: [amal.id],
        );
        await txn.insert('amal_cycles', {
          'amal_id': amal.id,
          'started_at': newCycleStart,
          'ended_at': null,
          'days_done': 0,
        });
        await txn.update(
          'amals',
          {'cycle_started_at': newCycleStart},
          where: 'id = ?',
          whereArgs: [amal.id],
        );
      });

      broken.add(amal.copyWith(cycleStartedAt: newCycleStart));
      debugPrint('Ardıcıllıq qırıldı: ${amal.title} → $today');
    }

    return broken;
  }

  Future<List<Amal>> getArchivedAmals() async {
    final db = await _db;
    final maps = await db.query(
      'amals',
      where: 'is_active = 0',
      orderBy: 'archived_at DESC',
    );
    return maps.map(Amal.fromMap).toList();
  }

  Future<List<({Amal amal, int completedDays})>>
  getArchivedAmalsWithStats() async {
    final amals = await getArchivedAmals();
    final result = <({Amal amal, int completedDays})>[];
    for (final amal in amals) {
      final cycleStart = amal.effectiveCycleStart.substring(0, 10);
      final completed = await countCompletedDays(amal.id, fromDate: cycleStart);
      result.add((amal: amal, completedDays: completed));
    }
    return result;
  }

  Future<void> reactivateAmal(int id) async {
    final db = await _db;
    final newCycleStart = '$_today 00:00:00';
    await db.transaction((txn) async {
      await txn.update(
        'amals',
        {
          'is_active': 1,
          'archived_at': null,
          'cycle_started_at': newCycleStart,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.insert('amal_cycles', {
        'amal_id': id,
        'started_at': newCycleStart,
        'ended_at': null,
        'days_done': 0,
      });
    });
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
      'SELECT substr(created_at, 1, 10) AS created_date, '
      'substr(archived_at, 1, 10) AS archived_date '
      'FROM amals ORDER BY created_date ASC',
    );
    if (amalRows.isEmpty) return {};

    final createdDates = amalRows
        .map((r) => r['created_date'] as String)
        .toList();
    final archivedDates = amalRows
        .map((r) => r['archived_date'] as String?)
        .toList();

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

      int lo = 0, hi = createdDates.length;
      while (lo < hi) {
        final mid = (lo + hi) ~/ 2;
        if (createdDates[mid].compareTo(date) <= 0) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }

      int totalOnDate = 0;
      for (int i = 0; i < lo; i++) {
        final archivedDate = archivedDates[i];
        if (archivedDate == null || archivedDate.compareTo(date) > 0) {
          totalOnDate++;
        }
      }

      if (totalOnDate > 0) {
        result[date] = (cnt / totalOnDate).clamp(0.0, 1.0);
      }
    }
    return result;
  }

  Future<Map<String, int>> getAmalCountPerDay({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _db;
    final amalRows = await db.rawQuery(
      'SELECT substr(created_at, 1, 10) AS created_date, '
      'substr(archived_at, 1, 10) AS archived_date '
      'FROM amals ORDER BY created_date ASC',
    );
    if (amalRows.isEmpty) return {};

    final createdDates = amalRows
        .map((r) => r['created_date'] as String)
        .toList();
    final archivedDates = amalRows
        .map((r) => r['archived_date'] as String?)
        .toList();

    final result = <String, int>{};
    var cur = from;
    while (!cur.isAfter(to)) {
      final dateStr = _formatDate(cur);
      int lo = 0, hi = createdDates.length;
      while (lo < hi) {
        final mid = (lo + hi) ~/ 2;
        if (createdDates[mid].compareTo(dateStr) <= 0) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      int count = 0;
      for (int i = 0; i < lo; i++) {
        final archivedDate = archivedDates[i];
        if (archivedDate == null || archivedDate.compareTo(dateStr) > 0) {
          count++;
        }
      }
      if (count > 0) result[dateStr] = count;
      cur = cur.add(const Duration(days: 1));
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

  Future<int> calculateStreak(int amalId, {String? fromDate}) async {
    final db = await _db;
    final today = _today;
    final todayRecord = await getRecord(amalId, today);
    final completedToday = todayRecord?.isCompleted ?? false;

    final startDate = completedToday
        ? DateTime.now()
        : DateTime.now().subtract(const Duration(days: 1));

    final lowerBound = fromDate != null ? DateTime.parse(fromDate) : null;
    final rangeFrom = _formatDate(
      startDate.subtract(const Duration(days: 365)),
    );
    final toDate = _formatDate(startDate);

    final maps = await db.rawQuery(
      '''
      SELECT record_date FROM amal_records
      WHERE amal_id = ?
        AND record_date >= ?
        AND record_date <= ?
        AND is_completed = 1
      ORDER BY record_date DESC
      ''',
      [amalId, rangeFrom, toDate],
    );

    final recordSet = {for (final m in maps) m['record_date'] as String};

    int streak = 0;
    for (int i = 0; i < 366; i++) {
      final date = startDate.subtract(Duration(days: i));
      if (lowerBound != null && date.isBefore(lowerBound)) break;
      final ds = _formatDate(date);
      if (recordSet.contains(ds)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<int> countCompletedDays(int amalId, {String? fromDate}) async {
    final db = await _db;
    final query = fromDate != null
        ? '''
          SELECT COUNT(*) AS cnt FROM amal_records
          WHERE amal_id = ? AND record_date >= ? AND is_completed = 1
          '''
        : '''
          SELECT COUNT(*) AS cnt FROM amal_records
          WHERE amal_id = ? AND is_completed = 1
          ''';
    final args = fromDate != null ? [amalId, fromDate] : [amalId];
    final result = await db.rawQuery(query, args);
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ─── BÜTÜN RECORDS — TARİXÇƏ ÜÇÜN (detail screen) ───────────────────────

  Future<Map<String, bool>> getAmalAllRecords(int amalId) async {
    final db = await _db;
    final maps = await db.query(
      'amal_records',
      where: 'amal_id = ?',
      whereArgs: [amalId],
    );
    return {
      for (final m in maps)
        m['record_date'] as String: (m['is_completed'] as int) == 1,
    };
  }

  Future<int> getBestStreak(int amalId, {required String fromDate}) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT record_date FROM amal_records
      WHERE amal_id = ? AND record_date >= ? AND is_completed = 1
      ORDER BY record_date ASC
      ''',
      [amalId, fromDate],
    );
    if (maps.isEmpty) return 0;

    final dates = maps
        .map((m) => DateTime.parse(m['record_date'] as String))
        .toList();

    int best = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  Future<List<AmalCycle>> getCyclesForAmal(int amalId) async {
    final db = await _db;
    final maps = await db.query(
      'amal_cycles',
      where: 'amal_id = ?',
      whereArgs: [amalId],
      orderBy: 'started_at ASC',
    );
    return maps.map(AmalCycle.fromMap).toList();
  }

  // ─── "GERİ QAYT" BİLDİRİŞİ ÜÇÜN ──────────────────────────────────────────

  Future<List<Amal>> getStreakBrokenAmals() async {
    final now = DateTime.now();
    final yesterday = _formatDate(now.subtract(const Duration(days: 1)));
    final dayBeforeYesterday = _formatDate(
      now.subtract(const Duration(days: 2)),
    );
    final sevenDaysAgo = _formatDate(now.subtract(const Duration(days: 8)));

    final amals = await getActiveAmals();
    if (amals.isEmpty) return [];

    final ids = amals.map((a) => a.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final db = await _db;

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
      final hadRecentStreak =
          dates.contains(dayBeforeYesterday) ||
          dates.any(
            (d) =>
                d.compareTo(sevenDaysAgo) >= 0 &&
                d.compareTo(dayBeforeYesterday) <= 0,
          );
      if (yesterdayFailed && hadRecentStreak) {
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

  Future<({int imported, int updated, int skipped, List<String> errors})>
  applyImport({required ImportPreview preview}) async {
    final db = await _db;
    final idMap = <int, int>{};
    int imported = 0;
    int updated = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final amal in preview.newAmals) {
      final map = Map<String, dynamic>.from(amal.toJson())..remove('id');
      try {
        final newId = await db.insert('amals', map);
        idMap[amal.id] = newId;
        imported++;
        if (amal.durationDays != null) {
          await db.insert('amal_cycles', {
            'amal_id': newId,
            'started_at': amal.effectiveCycleStart,
            'ended_at': null,
            'days_done': 0,
          });
        }
      } catch (e) {
        debugPrint('Yeni amal insert xətası [${amal.title}]: $e');
        errors.add(amal.title);
      }
    }

    for (final conflict in preview.conflicts) {
      if (conflict.useIncoming) {
        try {
          await db.update(
            'amals',
            {
              'count_target': conflict.incoming.countTarget,
              'content': conflict.incoming.content,
              'intention': conflict.incoming.intention,
              'duration_days': conflict.incoming.durationDays,
              'is_active': conflict.incoming.isActive ? 1 : 0,
            },
            where: 'id = ?',
            whereArgs: [conflict.existing.id],
          );
          idMap[conflict.incoming.id] = conflict.existing.id;
          updated++;
        } catch (e) {
          debugPrint(
            'Conflict yeniləmə xətası [${conflict.existing.title}]: $e',
          );
          errors.add(conflict.existing.title);
        }
      } else {
        idMap[conflict.incoming.id] = conflict.existing.id;
        skipped++;
      }
    }

    if (preview.records.isNotEmpty) {
      final batch = db.batch();
      for (final rec in preview.records) {
        final actualId = idMap[rec.amalId];
        if (actualId == null) continue;

        final map = rec.toMap()
          ..['amal_id'] = actualId
          ..remove('id');

        batch.insert(
          'amal_records',
          map,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }

    return (
      imported: imported,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }
}
