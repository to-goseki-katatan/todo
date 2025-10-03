import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class DBHelper {
  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS entries (
        id TEXT PRIMARY KEY,
        type TEXT CHECK(type IN ('header','item')) NOT NULL,
        title TEXT,
        completed INTEGER DEFAULT 0,
        position INTEGER NOT NULL
      )
    ''');
  }
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final directory = await getApplicationSupportDirectory();
    final dbPath = p.join(directory.path, 'todo.db');
    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: DBHelper._onUpgrade,
      ),
    );
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS entries (
        id TEXT PRIMARY KEY,
        type TEXT CHECK(type IN ('header','item')) NOT NULL,
        title TEXT,
        completed INTEGER DEFAULT 0,
        position INTEGER NOT NULL
      )
    ''');
  }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        type TEXT CHECK(type IN ('header','item')) NOT NULL,
        title TEXT,
        completed INTEGER DEFAULT 0,
        position INTEGER NOT NULL
      )
    ''');
    // 初期カテゴリheader追加
    final headers = [
    //   {'id': 'header_urgent', 'type': 'header', 'title': '緊急', 'completed': 0, 'position': 0},
      {'id': 'header_important', 'type': 'header', 'title': '重要', 'completed': 0, 'position': 0},
      {'id': 'header_normal', 'type': 'header', 'title': '通常', 'completed': 0, 'position': 1},
    ];
    for (final h in headers) {
      await db.insert('entries', h);
    }
  }

  Future<int> insertEntry(Map<String, dynamic> entry) async {
    final database = await db;
    return await database.insert('entries', entry);
  }

  Future<List<Map<String, dynamic>>> getEntries() async {
    final database = await db;
    return await database.query('entries', orderBy: 'position ASC');
  }

  Future<int> updateEntry(String id, Map<String, dynamic> entry) async {
    final database = await db;
    return await database.update('entries', entry, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEntry(String id) async {
    final database = await db;
    return await database.delete('entries', where: 'id = ?', whereArgs: [id]);
  }
}
