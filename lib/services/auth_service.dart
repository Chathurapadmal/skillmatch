import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'otp_email_service.dart';
import '../models/user_model.dart';
import 'firestore_user_service.dart';
import 'totp_service.dart';

// ────────────────────────────────────────────────────────────────────────────
// AuthService
// ────────────────────────────────────────────────────────────────────────────

class AuthService {
  static final _auth = FirebaseAuth.instance;

  // Development-only switch to bypass authentication gates.
  // Enable by running with: `flutter run --dart-define=DEV_AUTH_BYPASS=true`
  // Keep this disabled in production builds.
  static const bool bypassAllAuthInDevelopment = bool.fromEnvironment(
    'DEV_AUTH_BYPASS',
    defaultValue: false,
  );

  static bool get isDevelopmentAuthBypassEnabled => kDebugMode && bypassAllAuthInDevelopment;

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

  // ── Dev helper: ensure there is at least an anonymous session ────────────
  static Future<User?> ensureDevSession() async {
    if (!isDevelopmentAuthBypassEnabled) {
      return _auth.currentUser;
    }

    final existing = _auth.currentUser;
    if (existing != null) return existing;

    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  // ── Forward UserModel stream ──────────────────────────────────────────────
  static Stream<UserModel?> userModelStream(String uid) =>
      FirestoreUserService.userStream(uid);

  // ── Forward single UserModel fetch ───────────────────────────────────────
  static Future<UserModel?> fetchUserModel(String uid) =>
      FirestoreUserService.getUser(uid);

  // ── Ensure a Firestore user profile exists for authenticated users ───────
  static Future<UserModel?> ensureUserModel(User firebaseUser) async {
    final uid = firebaseUser.uid;
    final existing = await fetchUserModel(uid);
    if (existing != null) return existing;

    final fallback = UserModel(
      uid: uid,
      email: firebaseUser.email ?? '',
      displayName: (firebaseUser.displayName ?? '').trim().isNotEmpty
          ? firebaseUser.displayName!.trim()
          : (firebaseUser.email?.split('@').first ?? 'User'),
      role: UserRole.applicant,
      emailVerified: firebaseUser.emailVerified,
      twoFactorEnabled: false,
      profileCompleted: false,
      createdAt: DateTime.now(),
    );

    await FirestoreUserService.createUser(fallback);
    return fetchUserModel(uid);
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
      emailVerified: true,
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
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Always require TOTP challenge on fresh login
    totpSessionVerified.value = false;
  }

  // ── Send/re-send email verification ──────────────────────────────────────
  static Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await OtpEmailService.sendOtpToEmail(
      email: user.email ?? '',
      purpose: 'email_verification',
    );
  }

  // ── Reload Firebase user and check emailVerified ──────────────────────────
  static Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final model = await fetchUserModel(user.uid);
    return model?.emailVerified ?? false;
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  static Future<void> sendPasswordResetEmail(String email) async {
    await OtpEmailService.sendOtpToEmail(
      email: email.trim(),
      purpose: 'password_reset',
    );
  }

  static Future<void> confirmPasswordReset({
    required String email,
    required String newPassword,
  }) async {
    await ApiService.postJson('/api/auth/reset-password', {
      'email': email.trim(),
      'newPassword': newPassword,
    });
  }

  static Future<void> confirmEmailVerification({
    required String email,
  }) async {
    await ApiService.postJson('/api/auth/verify-email', {
      'email': email.trim(),
    });

    final user = _auth.currentUser;
    if (user != null) {
      await FirestoreUserService.setEmailVerified(user.uid);
    }
  }

  // ── Mark email verified in Firestore without Firebase Auth email flow ─────
  static Future<void> markEmailVerifiedLocally([String? uid]) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return;
    await FirestoreUserService.setEmailVerified(userId);
  }

  // ── Check local Firestore email verified flag ─────────────────────────────
  static Future<bool> isEmailVerifiedLocally([String? uid]) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return false;
    final model = await fetchUserModel(userId);
    return model?.emailVerified ?? false;
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
