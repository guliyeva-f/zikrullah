import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../domain/amal.dart';
import '../domain/amal_record.dart';

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

  /// Müddəti bitmiş əməlləri arxivləşdirir.
  /// Qaytarır: arxivlənmiş əməllərin siyahısı (bildiriş üçün).
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

  /// Heatmap üçün: hər tarix → tamamlanma nisbəti (0.0 – 1.0)
  /// [from] – [to] aralığında bütün tamamlanmış günlər.
  Future<Map<String, double>> getHeatmapData({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _db;

    // Cari aktiv əməllərin sayı (məxrəc)
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM amals WHERE is_active = 1',
    );
    final total = (totalResult.first['cnt'] as int?) ?? 0;
    if (total == 0) return {};

    final fromStr = _formatDate(from);
    final toStr = _formatDate(to);

    // Hər tarix üçün tamamlanan əməllərin sayı
    final rows = await db.rawQuery(
      '''
      SELECT record_date, COUNT(*) AS cnt
      FROM amal_records
      WHERE record_date >= ? AND record_date <= ?
        AND is_completed = 1
      GROUP BY record_date
    ''',
      [fromStr, toStr],
    );

    return {
      for (final r in rows)
        r['record_date'] as String: ((r['cnt'] as int) / total).clamp(0.0, 1.0),
    };
  }

  // ─── DETAIL SCREEN TƏQVİM ─────────────────────────────────────────────────

  /// Bir əməlin konkret ay üzrə tamamlama map-i: date → isCompleted
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

    final dates = List.generate(
      60,
      (i) => _formatDate(startDate.subtract(Duration(days: i))),
    );

    final placeholders = List.filled(60, '?').join(',');
    final maps = await db.query(
      'amal_records',
      where: 'amal_id = ? AND record_date IN ($placeholders)',
      whereArgs: [amalId, ...dates],
    );

    final recordMap = {for (final m in maps) m['record_date'] as String: m};

    int streak = 0;
    for (int i = 0; i < 60; i++) {
      final date = _formatDate(startDate.subtract(Duration(days: i)));
      final rec = recordMap[date];
      if (rec != null && (rec['is_completed'] as int) == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── "GERİ QAYT" BİLDİRİŞİ ÜÇÜN ──────────────────────────────────────────

  /// Dünən streak qırılan əməlləri qaytarır.
  Future<List<Amal>> getStreakBrokenAmals() async {
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final dayBefore = _formatDate(
      DateTime.now().subtract(const Duration(days: 2)),
    );

    final amals = await getActiveAmals();
    final broken = <Amal>[];

    for (final amal in amals) {
      final yesterdayRec = await getRecord(amal.id, yesterday);
      final dayBeforeRec = await getRecord(amal.id, dayBefore);

      // Dünən tamamlanmayıb + əvvəlki gün tamamlanmışdı = streak qırıldı
      final yesterdayFailed = !(yesterdayRec?.isCompleted ?? false);
      final dayBeforeDone = dayBeforeRec?.isCompleted ?? false;

      if (yesterdayFailed && dayBeforeDone) {
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

  /// Import: mövcud məlumatları silmədən əlavə edir (id conflict-i skip edir)
  Future<void> importData({
    required List<Amal> amals,
    required List<AmalRecord> records,
  }) async {
    final db = await _db;
    final batch = db.batch();

    for (final amal in amals) {
      batch.insert(
        'amals',
        amal.toJson(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    for (final rec in records) {
      batch.insert(
        'amal_records',
        rec.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  // amal_repository.dart-ın sonuna əlavə et:
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
