import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _db;

  static String? _overridePath;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final String path;
    if (_overridePath != null) {
      path = _overridePath!;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'amal_app.db');
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

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

    // ← bu sətri əlavə et
    await db.execute(
      'CREATE INDEX idx_records_amal_date ON amal_records (amal_id, record_date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE amals ADD COLUMN intention TEXT');
      await db.execute('ALTER TABLE amals ADD COLUMN duration_days INTEGER');
    }
    // ← version 3 əlavə et
    if (oldVersion < 3) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_records_amal_date ON amal_records (amal_id, record_date)',
      );
    }
  }

  // ─── TEST KÖMƏKÇI METODLAR ────────────────────────────────────────────────

  static void useInMemoryForTesting() {
    _overridePath = inMemoryDatabasePath;
  }

  Future<void> resetForTesting() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
    _db = null;
  }
}
