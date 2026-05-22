import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'amal_app.db');

    return await openDatabase(
      path,
      version: 2, // v1 → v2
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ─── v1: ilk quruluş ──────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE amals (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        title         TEXT NOT NULL,
        type          TEXT NOT NULL,
        count_target  INTEGER,
        content       TEXT,
        sort_order    INTEGER DEFAULT 0,
        is_active     INTEGER DEFAULT 1,
        created_at    TEXT NOT NULL,
        intention     TEXT,
        duration_days INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE amal_records (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        amal_id      INTEGER NOT NULL,
        record_date  TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        count_done   INTEGER DEFAULT 0,
        completed_at TEXT,
        FOREIGN KEY (amal_id) REFERENCES amals (id) ON DELETE CASCADE,
        UNIQUE (amal_id, record_date)
      )
    ''');
  }

  // ─── v2: niyyət + müddət sütunları ────────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE amals ADD COLUMN intention TEXT');
      await db.execute('ALTER TABLE amals ADD COLUMN duration_days INTEGER');
      // Mövcud əməllər: intention = NULL, duration_days = NULL (daimi)
    }
  }
}
