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
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        // CASCADE işləməsi üçün hər açılışda aktiv edilməlidir
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE amals (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        title        TEXT NOT NULL,
        type         TEXT NOT NULL,
        count_target INTEGER,
        content      TEXT,
        sort_order   INTEGER DEFAULT 0,
        is_active    INTEGER DEFAULT 1,
        created_at   TEXT NOT NULL
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
}