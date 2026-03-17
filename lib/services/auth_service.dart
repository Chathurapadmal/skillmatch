import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'firestore_user_service.dart';
import 'totp_service.dart';

// ────────────────────────────────────────────────────────────────────────────
// AuthService
// ────────────────────────────────────────────────────────────────────────────

class AuthService {
  static final _auth = FirebaseAuth.instance;

  // ── TOTP session flag ─────────────────────────────────────────────────────
  //
  // ValueNotifier so AuthWrapper can rebuild reactively when TOTP is verified
  // without an extra Firestore round-trip.
  // Set to true after the user successfully enters their TOTP code.
  // Reset to false on sign-out (requires re-verification next login).
  static final totpSessionVerified = ValueNotifier<bool>(false);

  // ── Auth state stream ─────────────────────────────────────────────────────
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Current Firebase user ─────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;

  // ── Forward UserModel stream ──────────────────────────────────────────────
  static Stream<UserModel?> userModelStream(String uid) =>
      FirestoreUserService.userStream(uid);

  // ── Forward single UserModel fetch ───────────────────────────────────────
  static Future<UserModel?> fetchUserModel(String uid) =>
      FirestoreUserService.getUser(uid);

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
    await cred.user!.sendEmailVerification();

    final model = UserModel(
      uid: cred.user!.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      role: role,
      companyName: role == UserRole.company ? companyName?.trim() : null,
      emailVerified: false,
      twoFactorEnabled: false,
      profileCompleted: false,
      createdAt: DateTime.now(),
    );
    await FirestoreUserService.createUser(model);
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  //
  // Signs in, syncs emailVerified to Firestore if newly verified, and resets
  // the TOTP session flag — the AuthWrapper stream then routes automatically.
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Reload to get latest emailVerified status
    await cred.user!.reload();

    // Sync Firebase emailVerified → Firestore if newly verified
    if (_auth.currentUser!.emailVerified) {
      final model = await FirestoreUserService.getUser(cred.user!.uid);
      if (model != null && !model.emailVerified) {
        await FirestoreUserService.setEmailVerified(cred.user!.uid);
      }
    }

    // Always require TOTP challenge on fresh login
    totpSessionVerified.value = false;
  }

  // ── Send/re-send email verification ──────────────────────────────────────
  static Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // ── Reload Firebase user and check emailVerified ──────────────────────────
  static Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    if (_auth.currentUser!.emailVerified) {
      await FirestoreUserService.setEmailVerified(user.uid);
      return true;
    }
    return false;
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    totpSessionVerified.value = false;
    await TotpService.deleteSecretLocally();
    await _auth.signOut();
  }

  // ── Friendly error messages ───────────────────────────────────────────────
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
