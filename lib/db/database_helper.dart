import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/assessment.dart';
import '../services/firestore_service.dart';

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
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
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
        restorationApproach TEXT NOT NULL DEFAULT '',
        restorationRationale TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE assessments ADD COLUMN restorationRationale TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 3) {
      // Add column to track which records have been pushed to Firestore
      await db.execute(
        'ALTER TABLE assessments ADD COLUMN firestoreId TEXT',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<int> create(Assessment assessment) async {
    final db = await database;
    final id = await db.insert('assessments', assessment.toMap());
    // Push to Firestore in the background (won't block the UI)
    _syncToFirestore(assessment.copyWith(id: id));
    return id;
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
    final rows = await db.update(
      'assessments',
      assessment.toMap(),
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
    _syncToFirestore(assessment);
    return rows;
  }

  Future<int> delete(int id) async {
    final db = await database;
    // Best-effort delete from Firestore before removing locally
    final assessment = await read(id);
    if (assessment?.firestoreId != null) {
      _deleteFromFirestore(assessment!.firestoreId!);
    }
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

  // ---------------------------------------------------------------------------
  // Firestore sync helpers
  // ---------------------------------------------------------------------------

  /// Called on app start: fetches remote records and inserts any that are
  /// missing from the local SQLite database.
  Future<int> syncFromFirestore() async {
    if (!await _isOnline()) return 0;
    try {
      final remote = await FirestoreService.instance.fetchAll();
      final local = await readAll();
      final localFirestoreIds =
          local.map((a) => a.firestoreId).whereType<String>().toSet();

      int imported = 0;
      for (final remoteAssessment in remote) {
        if (remoteAssessment.firestoreId != null &&
            localFirestoreIds.contains(remoteAssessment.firestoreId)) {
          continue; // Already have this record
        }
        final db = await database;
        await db.insert('assessments', remoteAssessment.toMap());
        imported++;
      }
      return imported;
    } catch (_) {
      return 0; // Silently fail — offline or Firestore unavailable
    }
  }

  /// Pushes all un-synced local records to Firestore.
  Future<void> syncUnsyncedToFirestore() async {
    if (!await _isOnline()) return;
    try {
      final db = await database;
      final unsynced = await db.query(
        'assessments',
        where: 'firestoreId IS NULL',
      );
      for (final map in unsynced) {
        final assessment = Assessment.fromMap(map);
        await _syncToFirestore(assessment);
      }
    } catch (_) {
      // Silently fail
    }
  }

  /// Pushes a single [assessment] to Firestore and stores the resulting doc ID
  /// back into SQLite.  Fails silently when offline.
  Future<void> _syncToFirestore(Assessment assessment) async {
    if (!await _isOnline()) return;
    try {
      final docId = await FirestoreService.instance.upsert(assessment);
      // Persist the Firestore doc ID locally so we can do targeted updates
      final db = await database;
      await db.update(
        'assessments',
        {'firestoreId': docId},
        where: 'id = ?',
        whereArgs: [assessment.id],
      );
    } catch (_) {
      // Silently fail — the record stays unsynced and will be pushed next time
    }
  }

  Future<void> _deleteFromFirestore(String firestoreId) async {
    if (!await _isOnline()) return;
    try {
      await FirestoreService.instance.delete(firestoreId);
    } catch (_) {
      // Silently fail
    }
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }
}
