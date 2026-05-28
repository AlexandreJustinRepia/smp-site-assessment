import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assessment.dart';

/// Handles all Cloud Firestore read/write operations for [Assessment] records.
///
/// Every assessment is stored as a document in the top-level `assessments`
/// collection. The document ID is preserved locally so edits update the same
/// remote record.
class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  final _col = FirebaseFirestore.instance.collection('assessments');

  String newId() => _col.doc().id;

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Pushes [assessment] to Firestore and returns the document ID.
  ///
  /// Throws a [FirebaseException] (or any other error) on failure; callers
  /// should handle this gracefully so the app keeps working offline.
  Future<String> upsert(Assessment assessment) async {
    final docId = assessment.firestoreId ?? newId();
    final data = _toFirestoreMap(assessment);
    await _col.doc(docId).set(data, SetOptions(merge: true));
    return docId;
  }

  /// Deletes the Firestore document for [firestoreId] if it exists.
  Future<void> delete(String firestoreId) async {
    await _col.doc(firestoreId).delete();
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns every assessment stored in Firestore, newest first.
  Future<List<Assessment>> fetchAll() async {
    final snap = await _col.orderBy('date', descending: true).get();
    return snap.docs.map((doc) => _fromFirestoreDoc(doc)).toList();
  }

  Future<Assessment?> read(String firestoreId) async {
    final doc = await _col.doc(firestoreId).get();
    if (!doc.exists) return null;
    return _fromFirestoreDoc(doc);
  }

  /// Streams all assessments in real-time (optional — wire up if you want
  /// live updates in the UI without manual refreshes).
  Stream<List<Assessment>> watchAll() {
    return _col.orderBy('date', descending: true).snapshots().map(
          (snap) => snap.docs.map(_fromFirestoreDoc).toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toFirestoreMap(Assessment assessment) {
    final map = assessment.toMap();
    map.remove('id');
    map.remove('firestoreId');
    // Replace the JSON-encoded inventory string with a proper Firestore list
    map.remove('inventoryJson');
    map['inventory'] =
        assessment.inventoryRows.map((r) => r.toMap()).toList();
    // Store a server-side timestamp for ordering/debugging
    map['syncedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  Assessment _fromFirestoreDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    // Convert Firestore list back to JSON string expected by Assessment.fromMap
    final inventory = data['inventory'];
    if (inventory is List) {
      data['inventoryJson'] =
          '[${inventory.map((e) => _encodeInventoryRow(e as Map)).join(',')}]';
    } else {
      data['inventoryJson'] ??= '[]';
    }
    final assessment = Assessment.fromMap(data);
    // Preserve the Firestore doc ID so we can reference it later
    assessment.firestoreId = doc.id;
    return assessment;
  }

  String _encodeInventoryRow(Map row) {
    final safe = {
      'species': row['species'] ?? '',
      'dbh': row['dbh'] ?? '',
      'mh': row['mh'] ?? '',
      'th': row['th'] ?? '',
      'remarks': row['remarks'] ?? '',
    };
    return '{"species":"${_esc(safe['species']!)}","dbh":"${_esc(safe['dbh']!)}",'
        '"mh":"${_esc(safe['mh']!)}","th":"${_esc(safe['th']!)}",'
        '"remarks":"${_esc(safe['remarks']!)}"}';
  }

  String _esc(String s) => s.replaceAll('"', r'\"');
}
