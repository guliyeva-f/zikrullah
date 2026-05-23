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

  /// BUG #3 DÜZƏLİŞİ:
  /// Əvvəlki kod məxrəc kimi "bugünkü aktiv əməllərin sayı"nı götürürdü.
  /// Bu yanlışdır: bir əməli arxivlədikdə bütün keçmiş tarixi data
  /// yenidən hesablanır və tamamlanma nisbəti artıq düzgün deyildi.
  ///
  /// Həll: hər tarix üçün məxrəc o günə qədər yaradılmış əməllərin sayıdır.
  /// created_at <= həmin tarix olan bütün əməllər (aktiv və arxiv) sayılır.
  /// Bu 2 sorğu ilə həll edilir — əvvəlki 1 sorğudan daha dürüstdür.
  Future<Map<String, double>> getHeatmapData({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _db;
    final fromStr = _formatDate(from);
    final toStr = _formatDate(to);

    // Bütün əməllərin yaradılma tarixləri (aktiv + arxiv)
    // Bu siyahı sayımı Dart tərəfindən ediləcək
    final amalRows = await db.rawQuery(
      'SELECT substr(created_at, 1, 10) AS created_date FROM amals',
    );
    final createdDates = amalRows
        .map((r) => r['created_date'] as String)
        .toList();

    if (createdDates.isEmpty) return {};

    // Hər tarix üçün tamamlanan əməllərin sayı
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

      // O günə qədər mövcud olan əməllərin sayı (məxrəc)
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

  /// BUG #4 DÜZƏLİŞİ:
  /// Əvvəlki kod yalnız 60 günə baxırdı.
  /// 60+ günlük streak olan istifadəçilər üçün nəticə həmişə 60 göstərirdi.
  /// Həll: 365 günə uzadıldı — ildə bir dəfəlik streak üçün kifayətdir.
  Future<int> calculateStreak(int amalId) async {
    final db = await _db;
    final today = _today;
    final todayRecord = await getRecord(amalId, today);
    final completedToday = todayRecord?.isCompleted ?? false;

    final startDate = completedToday
        ? DateTime.now()
        : DateTime.now().subtract(const Duration(days: 1));

    // FIX #4: 60 → 365
    const lookbackDays = 365;
    final dates = List.generate(
      lookbackDays,
      (i) => _formatDate(startDate.subtract(Duration(days: i))),
    );

    final placeholders = List.filled(lookbackDays, '?').join(',');
    final maps = await db.query(
      'amal_records',
      where: 'amal_id = ? AND record_date IN ($placeholders)',
      whereArgs: [amalId, ...dates],
    );

    final recordMap = {for (final m in maps) m['record_date'] as String: m};

    int streak = 0;
    for (int i = 0; i < lookbackDays; i++) {
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

  /// BUG #7 DÜZƏLİŞİ:
  /// Əvvəlki kod hər əməl üçün ayrı-ayrı 2 DB sorğusu edirdi (N əməl = 2N sorğu).
  /// Həll: bütün əməllər üçün lazımlı tarixlərdəki recordları TEK sorğu ilə
  /// alırıq, sonra Dart-da filtrasiya edirik. Bu 2N→2 sorğuya endirmək deməkdir.
  Future<List<Amal>> getStreakBrokenAmals() async {
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final dayBefore = _formatDate(
      DateTime.now().subtract(const Duration(days: 2)),
    );

    final amals = await getActiveAmals();
    if (amals.isEmpty) return [];

    final ids = amals.map((a) => a.id).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final db = await _db;

    // FIX #7: bütün amal_id-lər üçün 2 tarix = TEK sorğu
    final maps = await db.rawQuery(
      '''
      SELECT amal_id, record_date, is_completed
      FROM amal_records
      WHERE amal_id IN ($placeholders)
        AND record_date IN (?, ?)
      ''',
      [...ids, yesterday, dayBefore],
    );

    // amal_id → {tarix → tamamlandı?}
    final lookup = <int, Map<String, bool>>{};
    for (final m in maps) {
      final amalId = m['amal_id'] as int;
      final date = m['record_date'] as String;
      final completed = (m['is_completed'] as int) == 1;
      lookup.putIfAbsent(amalId, () => {})[date] = completed;
    }

    final broken = <Amal>[];
    for (final amal in amals) {
      final dates = lookup[amal.id] ?? {};
      final yesterdayFailed = !(dates[yesterday] ?? false);
      final dayBeforeDone = dates[dayBefore] ?? false;
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

  /// BUG #14 DÜZƏLİŞİ:
  /// Əvvəlki kod import edilən əmməlin öz ID-si ilə yazırdı.
  /// Əgər mövcud DB-də eyni ID varsa, ConflictAlgorithm.ignore ilə
  /// əməl skip edilirdi, amma onun record-ları (amal_records) hər halda
  /// yazılırdı → başqa əməlin ID-sinə bağlanırdı (data qarışıqlığı).
  ///
  /// Həll:
  /// 1. Hər əməl ID-siz insert edilir (DB yeni ID verir)
  /// 2. Köhnə ID → yeni ID mapping (idMap) saxlanılır
  /// 3. Record-lar yeni amal_id ilə insert edilir
  /// 4. Eyni title+type əməl varsa onu tapıb ID-ni götürürük (duplicate olmur)
  Future<void> importData({
    required List<Amal> amals,
    required List<AmalRecord> records,
  }) async {
    final db = await _db;
    final idMap = <int, int>{}; // köhnə id → yeni DB id

    for (final amal in amals) {
      // ID-siz insert et — DB avtomatik yeni ID verir
      final mapWithoutId = Map<String, dynamic>.from(amal.toJson())
        ..remove('id');

      final newId = await db
          .insert(
            'amals',
            mapWithoutId,
            conflictAlgorithm: ConflictAlgorithm.abort,
          )
          .catchError((_) => 0);

      if (newId > 0) {
        idMap[amal.id] = newId;
      } else {
        // Insert uğursuz oldu (məs. UNIQUE constraint) →
        // eyni title+type əməl mövcuddurmu yoxla
        final existing = await db.query(
          'amals',
          columns: ['id'],
          where: 'title = ? AND type = ?',
          whereArgs: [amal.title, amal.type.name],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          idMap[amal.id] = existing.first['id'] as int;
        }
        // tapılmadısa bu əməlin record-ları skip edilir
      }
    }

    // Record-ları yeni amal_id ilə batch insert
    if (records.isEmpty) return;

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
