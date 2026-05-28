import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';

import '../db/database_helper.dart';
import '../models/assessment.dart';

class SyncResult {
  final int uploaded;
  final int downloaded;
  final int deleted;
  final int skipped;
  final int total;

  const SyncResult({
    required this.uploaded,
    required this.downloaded,
    required this.deleted,
    required this.skipped,
    required this.total,
  });
}

class SyncNotConfiguredException implements Exception {
  const SyncNotConfiguredException();

  @override
  String toString() => 'Firebase is not configured for this app yet.';
}

class SyncNoInternetException implements Exception {
  const SyncNoInternetException();

  @override
  String toString() => 'No internet connection.';
}

class SyncService {
  static const _collection = 'assessments';
  static const _schemaVersion = 1;

  Future<SyncResult?> syncAssessments() async {
    // 1. Check internet connectivity first
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.contains(ConnectivityResult.mobile) ||
        connectivity.contains(ConnectivityResult.wifi) ||
        connectivity.contains(ConnectivityResult.ethernet);
    if (!isOnline) throw const SyncNoInternetException();

    // 2. Check Firebase is initialized
    if (Firebase.apps.isEmpty) {
      throw const SyncNotConfiguredException();
    }

    final firestore = FirebaseFirestore.instance;
    final pendingDeleteIds = await DatabaseHelper.instance.readPendingDeleteIds();
    var deleted = 0;

    if (pendingDeleteIds.isNotEmpty) {
      final deleteBatch = firestore.batch();
      for (final firestoreId in pendingDeleteIds) {
        deleteBatch.delete(firestore.collection(_collection).doc(firestoreId));
      }
      await deleteBatch.commit();
      deleted = pendingDeleteIds.length;
      for (final firestoreId in pendingDeleteIds) {
        await DatabaseHelper.instance.clearPendingDelete(firestoreId);
      }
    }

    final localAssessments = await DatabaseHelper.instance.readAll();
    final localByFirestoreId = <String, Assessment>{};
    final localByFingerprint = <String, Assessment>{};
    var skipped = 0;

    for (final assessment in localAssessments) {
      final firestoreId = assessment.firestoreId;
      if (firestoreId != null && firestoreId.isNotEmpty) {
        localByFirestoreId[firestoreId] = assessment;
      }

      final fingerprint = _fingerprint(_toSyncMap(assessment));
      if (localByFingerprint.containsKey(fingerprint)) {
        skipped++;
        continue;
      }
      localByFingerprint[fingerprint] = assessment;
    }

    final remoteSnapshot = await firestore.collection(_collection).get();
    final remoteById = <String, Map<String, dynamic>>{};
    final remoteByFingerprint = <String, Map<String, dynamic>>{};

    for (final doc in remoteSnapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final assessmentMap = _assessmentDataFromRemote(data);
      assessmentMap['firestoreId'] = doc.id;
      remoteById[doc.id] = assessmentMap;
      final fingerprint = _fingerprint(assessmentMap);
      if (remoteByFingerprint.containsKey(fingerprint)) {
        skipped++;
        continue;
      }
      remoteByFingerprint[fingerprint] = assessmentMap;
    }

    final batch = firestore.batch();
    final firestoreIdAssignments = <Assessment, String>{};
    var uploaded = 0;

    for (final assessment in localByFingerprint.values) {
      var firestoreId = assessment.firestoreId;
      final fingerprint = _fingerprint(_toSyncMap(assessment));
      final matchingRemote = remoteByFingerprint[fingerprint];

      firestoreId ??= matchingRemote?['firestoreId'] as String?;
      firestoreId ??= firestore.collection(_collection).doc().id;
      if (assessment.firestoreId == null || assessment.firestoreId!.isEmpty) {
        firestoreIdAssignments[assessment] = firestoreId;
      }

      final remote = remoteById[firestoreId];
      if (remote != null && !_isNewer(assessment.updatedAt, remote['updatedAt'])) {
        skipped++;
        continue;
      }

      final doc = firestore.collection(_collection).doc(firestoreId);
      batch.set(doc, {
        ..._toSyncMap(assessment),
        'schemaVersion': _schemaVersion,
        'syncedAt': FieldValue.serverTimestamp(),
      });
      uploaded++;
    }

    if (uploaded > 0) {
      await batch.commit();
    }

    for (final entry in firestoreIdAssignments.entries) {
      await DatabaseHelper.instance.applyRemoteUpdate(
        entry.key.copyWith(firestoreId: entry.value),
      );
    }

    var downloaded = 0;

    for (final entry in remoteById.entries) {
      final local = localByFirestoreId[entry.key];
      if (local != null) {
        if (_isNewer(entry.value['updatedAt'], local.updatedAt)) {
          await DatabaseHelper.instance.applyRemoteUpdate(
            _fromSyncMap(entry.value).copyWith(id: local.id),
          );
          downloaded++;
        } else {
          skipped++;
        }
        continue;
      }

      final fingerprint = _fingerprint(entry.value);
      if (localByFingerprint.containsKey(fingerprint)) {
        skipped++;
        continue;
      }

      await DatabaseHelper.instance.insertSynced(_fromSyncMap(entry.value));
      downloaded++;
    }

    final total = (await DatabaseHelper.instance.readAll()).length;
    return SyncResult(
      uploaded: uploaded,
      downloaded: downloaded,
      deleted: deleted,
      skipped: skipped,
      total: total,
    );
  }

  Map<String, dynamic> _toSyncMap(Assessment assessment) {
    final map = Map<String, dynamic>.from(assessment.toMap())..remove('id');
    map.remove('firestoreId');
    map['inventory'] = assessment.inventoryRows
        .map((row) => row.toMap())
        .toList();
    map.remove('inventoryJson');
    return map;
  }

  Map<String, dynamic> _assessmentDataFromRemote(Map<String, dynamic> data) {
    final map = Map<String, dynamic>.from(data)
      ..remove('schemaVersion')
      ..remove('syncedAt');
    return map;
  }

  Assessment _fromSyncMap(Map<String, dynamic> map) {
    final assessment = Assessment.fromMap({
      'gridNo': map['gridNo'] ?? '',
      'centroidNo': map['centroidNo'] ?? '',
      'elevation': map['elevation'] ?? '',
      'date': map['date'] ?? '',
      'location': map['location'] ?? '',
      'coordsTarget': map['coordsTarget'] ?? '',
      'coordsActual': map['coordsActual'] ?? '',
      'teamMembers': map['teamMembers'] ?? '',
      'landCover': map['landCover'] ?? '',
      'treeCrownCover': map['treeCrownCover'] ?? '',
      'forestCondition': map['forestCondition'] ?? '',
      'forestConditionNotes': map['forestConditionNotes'] ?? '',
      'forestLitterGroundCover': map['forestLitterGroundCover'] ?? '',
      'forestLitterAvgDepth': map['forestLitterAvgDepth'] ?? '',
      'threats': map['threats'] ?? '',
      'inventoryJson': map['inventoryJson'] ?? '[]',
      'restorationApproach': map['restorationApproach'] ?? '',
      'restorationRationale': map['restorationRationale'] ?? '',
      'firestoreId': map['firestoreId'],
      'updatedAt': map['updatedAt'] ?? DateTime.now().toIso8601String(),
    });

    final inventory = map['inventory'];
    if (inventory is List) {
      assessment.setInventoryRows(
        inventory
            .whereType<Map>()
            .map((row) => InventoryRow.fromMap(Map<String, dynamic>.from(row)))
            .toList(),
      );
    }

    return assessment;
  }

  String _fingerprint(Map<String, dynamic> map) {
    return jsonEncode(_normalize(map));
  }

  bool _isNewer(Object? candidate, Object? current) {
    final candidateDate = DateTime.tryParse(candidate?.toString() ?? '');
    final currentDate = DateTime.tryParse(current?.toString() ?? '');
    if (candidateDate == null) return false;
    if (currentDate == null) return true;
    return candidateDate.isAfter(currentDate);
  }

  Object? _normalize(Object? value) {
    if (value is Map) {
      final sortedKeys = value.keys.map((key) => key.toString()).toList()
        ..sort();
      return {
        for (final key in sortedKeys)
          if (!_ignoredSyncKeys.contains(key)) key: _normalize(value[key]),
      };
    }
    if (value is List) {
      return value.map(_normalize).toList();
    }
    return value ?? '';
  }

  static const _ignoredSyncKeys = {
    'id',
    'firestoreId',
    'schemaVersion',
    'syncedAt',
    'updatedAt',
  };
}
