import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUserAccess {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool approved;

  const AppUserAccess({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.approved,
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
    );
  }
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
    return _users.doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUserAccess.fromDoc(doc);
    });
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
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
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

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
