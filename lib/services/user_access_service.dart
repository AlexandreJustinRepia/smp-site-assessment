import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../db/database_helper.dart';

class AppUserAccess {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool approved;
  final bool nameDirty;

  const AppUserAccess({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.approved,
    this.nameDirty = false,
  });

  bool get isAdmin => approved && role == 'admin';
  bool get canEdit => approved && (role == 'admin' || role == 'editor');
  bool get canDelete => isAdmin;

  factory AppUserAccess.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUserAccess(
      uid: doc.id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      role: data['role']?.toString() ?? 'viewer',
      approved: data['approved'] == true,
      nameDirty: false,
    );
  }

  factory AppUserAccess.fromCache(Map<String, dynamic> map) {
    return AppUserAccess(
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'viewer',
      approved: map['approved'] == true,
      nameDirty: map['nameDirty'] == true,
    );
  }

  Map<String, dynamic> toCacheMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'approved': approved,
        'nameDirty': nameDirty,
      };
}

class UserAccessService {
  static final UserAccessService instance = UserAccessService._();

  UserAccessService._();

  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Stream<AppUserAccess?> watchCurrentAccess() {
    final user = currentUser;
    if (user == null) return Stream.value(null);
    return _users.doc(user.uid).snapshots().asyncMap((doc) async {
      await _syncPendingProfileName();
      final cached = await readCachedCurrentAccess();
      if (cached != null && cached.nameDirty) return cached;
      if (!doc.exists) return readCachedCurrentAccess();
      final access = AppUserAccess.fromDoc(doc);
      if (access.approved) {
        await DatabaseHelper.instance.cacheUserAccess(access.toCacheMap());
      }
      return access;
    });
  }

  Future<AppUserAccess?> readCachedCurrentAccess() async {
    final user = currentUser;
    if (user == null) return null;
    final cached = await DatabaseHelper.instance.readCachedUserAccess(user.uid);
    if (cached == null) return null;
    return AppUserAccess.fromCache(cached);
  }

  Stream<List<AppUserAccess>> watchUsers() {
    return _users.orderBy('email').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUserAccess.fromDoc(doc)).toList(),
        );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _cacheRemoteAccess(credential.user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await _users.doc(user.uid).set({
      'name': name.trim(),
      'email': user.email ?? email.trim(),
      'role': 'viewer',
      'approved': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUser({
    required String uid,
    required String role,
    required bool approved,
  }) async {
    await _users.doc(uid).set({
      'role': role,
      'approved': approved,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _cacheRemoteAccess(User? user) async {
    if (user == null) return;
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) return;
    final access = AppUserAccess.fromDoc(doc);
    if (!access.approved) return;
    await DatabaseHelper.instance.cacheUserAccess(access.toCacheMap());
  }

  Future<bool> updateProfileName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final trimmedName = name.trim();
    var cached = await readCachedCurrentAccess();
    if (cached == null) {
      try {
        final doc = await _users.doc(user.uid).get();
        if (doc.exists) cached = AppUserAccess.fromDoc(doc);
      } catch (_) {
        // Without a local or remote access record, do not create permissions.
      }
    }
    if (cached == null) return false;

    await DatabaseHelper.instance.cacheUserAccess(
      AppUserAccess(
        uid: cached.uid,
        name: trimmedName,
        email: cached.email,
        role: cached.role,
        approved: cached.approved,
        nameDirty: true,
      ).toCacheMap(),
    );
    return _syncPendingProfileName();
  }

  Future<bool> _syncPendingProfileName() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final cached = await readCachedCurrentAccess();
    if (cached == null || !cached.nameDirty) return true;

    try {
      await user.updateDisplayName(cached.name);
      await _users.doc(user.uid).set({
        'name': cached.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await DatabaseHelper.instance.cacheUserAccess(
        AppUserAccess(
          uid: cached.uid,
          name: cached.name,
          email: cached.email,
          role: cached.role,
          approved: cached.approved,
        ).toCacheMap(),
      );
      return true;
    } catch (_) {
      // Keep the local cached name and retry next time the profile is loaded.
      return false;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
