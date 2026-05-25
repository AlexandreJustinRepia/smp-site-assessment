import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/assessment.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('site_assessments.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gridNo TEXT NOT NULL DEFAULT '',
        centroidNo TEXT NOT NULL DEFAULT '',
        elevation TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL DEFAULT '',
        location TEXT NOT NULL DEFAULT '',
        coordsTarget TEXT NOT NULL DEFAULT '',
        coordsActual TEXT NOT NULL DEFAULT '',
        teamMembers TEXT NOT NULL DEFAULT '',
        landCover TEXT NOT NULL DEFAULT '',
        treeCrownCover TEXT NOT NULL DEFAULT '',
        forestCondition TEXT NOT NULL DEFAULT '',
        forestConditionNotes TEXT NOT NULL DEFAULT '',
        forestLitterGroundCover TEXT NOT NULL DEFAULT '',
        forestLitterAvgDepth TEXT NOT NULL DEFAULT '',
        threats TEXT NOT NULL DEFAULT '',
        inventoryJson TEXT NOT NULL DEFAULT '[]',
        restorationApproach TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<int> create(Assessment assessment) async {
    final db = await database;
    return await db.insert('assessments', assessment.toMap());
  }

  Future<Assessment?> read(int id) async {
    final db = await database;
    final maps = await db.query(
      'assessments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Assessment.fromMap(maps.first);
  }

  Future<List<Assessment>> readAll() async {
    final db = await database;
    final result = await db.query('assessments', orderBy: 'id DESC');
    return result.map((map) => Assessment.fromMap(map)).toList();
  }

  Future<int> update(Assessment assessment) async {
    final db = await database;
    return await db.update(
      'assessments',
      assessment.toMap(),
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      'assessments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
