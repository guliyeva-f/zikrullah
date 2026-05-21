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

  /// Sürükle-bırak sonrası bütün sort_order-ləri batch ilə yazar
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

  Future<List<AmalRecord>> getRecordsForMonth(int year, int month) async {
    final db = await _db;
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'amal_records',
      where: 'record_date LIKE ?',
      whereArgs: ['$prefix%'],
    );
    return maps.map(AmalRecord.fromMap).toList();
  }

  /// UPSERT — mövcuddursa replace edir, yoxdursa insert edir
  Future<void> upsertRecord(AmalRecord record) async {
    final db = await _db;
    await db.insert(
      'amal_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

    // 60 günlük bütün recordları bir sorğuda gətiririk
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
}
