import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';

import '../db/database_helper.dart';
import '../models/assessment.dart';

class SyncResult {
  final int uploaded;
  final int downloaded;
  final int skipped;
  final int total;

  const SyncResult({
    required this.uploaded,
    required this.downloaded,
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
  static const _collection = 'site_assessments';
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
    final localAssessments = await DatabaseHelper.instance.readAll();
    final localByFingerprint = <String, Assessment>{};
    var skipped = 0;

    for (final assessment in localAssessments) {
      final fingerprint = _fingerprint(_toSyncMap(assessment));
      if (localByFingerprint.containsKey(fingerprint)) {
        skipped++;
        continue;
      }
      localByFingerprint[fingerprint] = assessment;
    }

    final remoteSnapshot = await firestore.collection(_collection).get();
    final remoteByFingerprint = <String, Map<String, dynamic>>{};

    for (final doc in remoteSnapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final assessmentMap = _assessmentDataFromRemote(data);
      final fingerprint = _fingerprint(assessmentMap);
      if (remoteByFingerprint.containsKey(fingerprint)) {
        skipped++;
        continue;
      }
      remoteByFingerprint[fingerprint] = assessmentMap;
    }

    final batch = firestore.batch();
    var uploaded = 0;

    for (final entry in localByFingerprint.entries) {
      if (remoteByFingerprint.containsKey(entry.key)) continue;

      final doc = firestore.collection(_collection).doc(_documentId(entry.key));
      batch.set(doc, {
        ..._toSyncMap(entry.value),
        'schemaVersion': _schemaVersion,
        'syncedAt': FieldValue.serverTimestamp(),
      });
      uploaded++;
    }

    if (uploaded > 0) {
      await batch.commit();
    }

    var downloaded = 0;
    final seen = localByFingerprint.keys.toSet();

    for (final entry in remoteByFingerprint.entries) {
      if (seen.contains(entry.key)) {
        skipped++;
        continue;
      }

      await DatabaseHelper.instance.create(_fromSyncMap(entry.value));
      seen.add(entry.key);
      downloaded++;
    }

    final total = (await DatabaseHelper.instance.readAll()).length;
    return SyncResult(
      uploaded: uploaded,
      downloaded: downloaded,
      skipped: skipped,
      total: total,
    );
  }

  Map<String, dynamic> _toSyncMap(Assessment assessment) {
    final map = Map<String, dynamic>.from(assessment.toMap())..remove('id');
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

  String _documentId(String fingerprint) {
    const offsetBasis = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    var hash = offsetBasis;

    for (final unit in utf8.encode(fingerprint)) {
      hash ^= unit;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }

  Object? _normalize(Object? value) {
    if (value is Map) {
      final sortedKeys = value.keys.map((key) => key.toString()).toList()
        ..sort();
      return {
        for (final key in sortedKeys)
          if (key != 'id') key: _normalize(value[key]),
      };
    }
    if (value is List) {
      return value.map(_normalize).toList();
    }
    return value ?? '';
  }
}
