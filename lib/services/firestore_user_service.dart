import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

// ────────────────────────────────────────────────────────────────────────────
// FirestoreUserService
// ────────────────────────────────────────────────────────────────────────────
//
// All reads and writes for the  users/{uid}  Firestore collection.
// Keeps AuthService thin and focused on authentication only.

class FirestoreUserService {
  static final _db = FirebaseFirestore.instance;

  // ── Fetch a UserModel once ────────────────────────────────────────────────
  static Future<UserModel?> getUser(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap);
    } catch (_) {
      return null;
    }
  }

  // ── Live stream of the user document ─────────────────────────────────────
  static Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap);
    });
  }

  // ── Create user document after registration ───────────────────────────────
  static Future<void> createUser(UserModel model) async {
    await _db.collection('users').doc(model.uid).set(model.toMap());
  }

  // ── Mark email as verified ────────────────────────────────────────────────
  static Future<void> setEmailVerified(String uid) async {
    await _db.collection('users').doc(uid).update({
      'emailVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Enable 2FA after TOTP setup ───────────────────────────────────────────
  //
  // ⚠ totpSecret is written to Firestore here only for demo purposes.
  // TODO (production): Do NOT store the TOTP secret in Firestore.
  //   Generate and store it exclusively on the backend.
  static Future<void> enableTwoFactor({
    required String uid,

    /// BASE32 secret – demo only; should never reach the client in production.
    // TODO (production): remove totpSecret parameter entirely.
    required String totpSecret,
    required List<String> backupCodesHash,
  }) async {
    await _db.collection('users').doc(uid).update({
      'twoFactorEnabled': true,
      'totpSecret': totpSecret, // TODO (production): remove this field
      'backupCodesHash': backupCodesHash,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Remove a used backup code ─────────────────────────────────────────────
  //
  // Removes the hash at [index] from backupCodesHash so it cannot be reused.
  static Future<void> consumeBackupCode(String uid, int index) async {
    final snap = await _db.collection('users').doc(uid).get();
    final codes = ((snap.data()?['backupCodesHash'] as List?) ?? [])
        .cast<String>()
        .toList();
    if (index >= 0 && index < codes.length) {
      codes.removeAt(index);
    }
    await _db.collection('users').doc(uid).update({
      'backupCodesHash': codes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Mark profile as completed ─────────────────────────────────────────────
  static Future<void> setProfileCompleted(String uid) async {
    await _db.collection('users').doc(uid).update({
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
