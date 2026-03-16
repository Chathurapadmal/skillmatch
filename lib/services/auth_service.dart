import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // ── Stream of auth state changes ──────────────────────────────────────────
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Current Firebase user ─────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;

  // ── Fetch full UserModel from Firestore ───────────────────────────────────
  static Future<UserModel?> fetchUserModel(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  // ── Stream of the current user's Firestore doc (live role updates) ────────
  static Stream<UserModel?> userModelStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap);
    });
  }

  // ── Register ──────────────────────────────────────────────────────────────
  static Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? companyName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    await cred.user!.updateDisplayName(displayName.trim());

    final model = UserModel(
      uid: cred.user!.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      role: role,
      companyName: role == UserRole.company ? companyName?.trim() : null,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(cred.user!.uid).set(model.toMap());
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── User-friendly Firebase error messages ────────────────────────────────
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
