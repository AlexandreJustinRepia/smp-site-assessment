import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/assessment.dart';
import '../services/firestore_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  final _changeController = StreamController<void>.broadcast();

  /// Reactive stream that emits whenever the local DB changes.
  Stream<void> watchChanges() => _changeController.stream;

  /// Trigger change notifications.
  void _notifyChange() {
    if (!_changeController.isClosed && _changeController.hasListener) {
      _changeController.add(null);
    }
  }

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
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
        updatedAt TEXT NOT NULL DEFAULT '',
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
        restorationRationale TEXT NOT NULL DEFAULT '',
        createdByUid TEXT NOT NULL DEFAULT '',
        createdByEmail TEXT NOT NULL DEFAULT ''
      )
    ''');
    await _createPendingDeletesTable(db);
    await _createCachedUserAccessTable(db);
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
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE assessments ADD COLUMN updatedAt TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 5) {
      await _createPendingDeletesTable(db);
    }
    if (oldVersion < 6) {
      await _createCachedUserAccessTable(db);
    }
    if (oldVersion >= 6 && oldVersion < 7) {
      await db.execute(
        'ALTER TABLE cached_user_access ADD COLUMN nameDirty INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE assessments ADD COLUMN createdByUid TEXT NOT NULL DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE assessments ADD COLUMN createdByEmail TEXT NOT NULL DEFAULT ""',
      );
    }
  }

  Future<void> _createPendingDeletesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_assessment_deletes (
        firestoreId TEXT PRIMARY KEY,
        deletedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createCachedUserAccessTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_user_access (
        uid TEXT PRIMARY KEY,
        name TEXT NOT NULL DEFAULT '',
        email TEXT NOT NULL DEFAULT '',
        role TEXT NOT NULL DEFAULT 'viewer',
        approved INTEGER NOT NULL DEFAULT 0,
        nameDirty INTEGER NOT NULL DEFAULT 0,
        cachedAt TEXT NOT NULL
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<int> create(Assessment assessment) async {
    final db = await database;
    final local = assessment.copyWith(
      firestoreId: assessment.firestoreId ?? _newLocalFirestoreId(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _clearPendingDelete(local.firestoreId);
    final id = await db.insert('assessments', local.toMap());
    // Push to Firestore in the background (won't block the UI)
    _syncToFirestore(local.copyWith(id: id));
    _notifyChange();
    return id;
  }

  Future<int> insertSynced(Assessment assessment) async {
    final db = await database;
    final id = await db.insert('assessments', assessment.toMap());
    _notifyChange();
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

  Future<List<Assessment>> readPage({
    required int limit,
    required int offset,
    String? search,
  }) async {
    final db = await database;
    if (search == null || search.trim().isEmpty) {
      final result = await db.query(
        'assessments',
        orderBy: 'id DESC',
        limit: limit,
        offset: offset,
      );
      return result.map((map) => Assessment.fromMap(map)).toList();
    }

    final queryStr = '%${search.trim().toLowerCase()}%';
    final result = await db.query(
      'assessments',
      where: '''
        gridNo LIKE ? OR
        centroidNo LIKE ? OR
        location LIKE ? OR
        coordsTarget LIKE ? OR
        coordsActual LIKE ? OR
        teamMembers LIKE ? OR
        landCover LIKE ? OR
        treeCrownCover LIKE ? OR
        forestCondition LIKE ? OR
        threats LIKE ? OR
        restorationApproach LIKE ? OR
        restorationRationale LIKE ?
      ''',
      whereArgs: List.filled(12, queryStr),
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => Assessment.fromMap(map)).toList();
  }

  Future<int> update(Assessment assessment) async {
    final db = await database;
    final local = assessment.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    final rows = await db.update(
      'assessments',
      local.toMap(),
      where: 'id = ?',
      whereArgs: [local.id],
    );
    _syncToFirestore(local);
    _notifyChange();
    return rows;
  }

  Future<int> applyRemoteUpdate(Assessment assessment) async {
    final db = await database;
    final rows = await db.update(
      'assessments',
      assessment.toMap(),
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
    _notifyChange();
    return rows;
  }

  Future<int> delete(int id) async {
    final db = await database;
    final assessment = await read(id);
    final firestoreId = assessment?.firestoreId;
    if (firestoreId != null && firestoreId.isNotEmpty) {
      await _queuePendingDelete(firestoreId);
      _deleteFromFirestore(firestoreId);
    }
    final rows = await db.delete(
      'assessments',
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyChange();
    return rows;
  }

  Future<List<String>> readPendingDeleteIds() async {
    final db = await database;
    final result = await db.query(
      'pending_assessment_deletes',
      orderBy: 'deletedAt ASC',
    );
    return result
        .map((row) => row['firestoreId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> clearPendingDelete(String firestoreId) async {
    await _clearPendingDelete(firestoreId);
  }

  Future<void> cacheUserAccess(Map<String, dynamic> access) async {
    final db = await database;
    await db.insert(
      'cached_user_access',
      {
        'uid': access['uid'],
        'name': access['name'] ?? '',
        'email': access['email'] ?? '',
        'role': access['role'] ?? 'viewer',
        'approved': access['approved'] == true ? 1 : 0,
        'nameDirty': access['nameDirty'] == true ? 1 : 0,
        'cachedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> readCachedUserAccess(String uid) async {
    final db = await database;
    final result = await db.query(
      'cached_user_access',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return {
      'uid': row['uid']?.toString() ?? '',
      'name': row['name']?.toString() ?? '',
      'email': row['email']?.toString() ?? '',
      'role': row['role']?.toString() ?? 'viewer',
      'approved': row['approved'] == 1,
      'nameDirty': row['nameDirty'] == 1,
    };
  }

  Future close() async {
    await _changeController.close();
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
      final localById = {for (final a in local) a.firestoreId: a};

      final db = await database;
      int imported = 0;

      // Batch all SQLite writes in a single transaction for speed.
      await db.transaction((txn) async {
        for (final remoteAssessment in remote) {
          final localAssessment = localById[remoteAssessment.firestoreId];
          if (localAssessment != null) {
            if (_isNewer(
              remoteAssessment.updatedAt,
              localAssessment.updatedAt,
            )) {
              await txn.update(
                'assessments',
                remoteAssessment.copyWith(id: localAssessment.id).toMap(),
                where: 'id = ?',
                whereArgs: [localAssessment.id],
              );
              imported++;
            }
            continue;
          }
          await txn.insert('assessments', remoteAssessment.toMap());
          imported++;
        }
      });

      if (imported > 0) _notifyChange();
      return imported;
    } catch (_) {
      return 0; // Silently fail — offline or Firestore unavailable
    }
  }

  /// Pushes local records to Firestore after the app comes back online.
  Future<void> syncUnsyncedToFirestore() async {
    if (!await _isOnline()) return;
    try {
      await _syncPendingDeletesToFirestore();
      final db = await database;
      // Only upload records that have never been pushed to Firestore.
      final unsynced = await db.query(
        'assessments',
        where: "firestoreId IS NULL OR firestoreId LIKE 'local_%'",
      );
      for (final map in unsynced) {
        final assessment = Assessment.fromMap(map);
        await _syncToFirestore(assessment);
      }
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> _syncPendingDeletesToFirestore() async {
    final pendingIds = await readPendingDeleteIds();
    for (final firestoreId in pendingIds) {
      if (await _deleteFromFirestore(firestoreId)) {
        await _clearPendingDelete(firestoreId);
      }
    }
  }

  /// Pushes a single [assessment] to Firestore and stores the resulting doc ID
  /// back into SQLite.  Fails silently when offline.
  Future<void> _syncToFirestore(Assessment assessment) async {
    if (!await _isOnline()) return;
    try {
      final firestoreId = assessment.firestoreId;
      if (firestoreId != null && firestoreId.isNotEmpty) {
        final remote = await FirestoreService.instance.read(firestoreId);
        if (remote != null && !_isNewer(assessment.updatedAt, remote.updatedAt)) {
          return;
        }
      }

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

  Future<bool> _deleteFromFirestore(String firestoreId) async {
    if (!await _isOnline()) return false;
    try {
      await FirestoreService.instance.delete(firestoreId);
      await _clearPendingDelete(firestoreId);
      return true;
    } catch (_) {
      // Silently fail
      return false;
    }
  }

  Future<void> _queuePendingDelete(String firestoreId) async {
    final db = await database;
    await db.insert(
      'pending_assessment_deletes',
      {
        'firestoreId': firestoreId,
        'deletedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _clearPendingDelete(String? firestoreId) async {
    if (firestoreId == null || firestoreId.isEmpty) return;
    final db = await database;
    await db.delete(
      'pending_assessment_deletes',
      where: 'firestoreId = ?',
      whereArgs: [firestoreId],
    );
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }

  bool _isNewer(String candidate, String current) {
    final candidateDate = DateTime.tryParse(candidate);
    final currentDate = DateTime.tryParse(current);
    if (candidateDate == null) return false;
    if (currentDate == null) return true;
    return candidateDate.isAfter(currentDate);
  }

  String _newLocalFirestoreId() {
    return 'local_${DateTime.now().microsecondsSinceEpoch}';
  }
}
