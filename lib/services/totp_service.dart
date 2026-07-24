import 'dart:math';

import 'package:base32/base32.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:otp/otp.dart';

// ────────────────────────────────────────────────────────────────────────────
// TotpService
// ────────────────────────────────────────────────────────────────────────────
//
// Handles TOTP secret generation and 6-digit code verification.
//
// ⚠ PRODUCTION NOTES:
//   - Secret generation should happen on a trusted backend.
//   - Code verification should also happen on the backend so the secret
//     is never exposed to the client after setup.
//   - This implementation is intentionally self-contained for demo / project
//     use. Clearly marked TODO comments show what to move server-side.
//
// TODO (production): Move generateSecret() to backend API endpoint.
// TODO (production): Move verifyCode() to backend – accept only the code &
//   email, verify server-side, return signed token on success.

class TotpService {
  // ── Secure storage key for the TOTP secret ─────────────────────────────────
  static const _secretKey = 'skillmatch_totp_secret';
  static const _storage = FlutterSecureStorage(
    // Recommended options for Android to use EncryptedSharedPreferences
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static void _logStorageUnavailable(Object error) {
    debugPrint(
      'TotpService: secure storage unavailable, falling back to Firestore-only '
      'TOTP secret handling. Error: $error',
    );
  }

  // ── Generate a random 20-byte BASE32 secret ───────────────────────────────
  //
  // 20 bytes → 160-bit secret → encodes to a 32-character BASE32 string.
  // Compatible with Google Authenticator, Authy, and Microsoft Authenticator.
  //
  // TODO (production): Call a backend endpoint instead of generating locally.
  static String generateSecret() {
    final rng = Random.secure();
    final bytes = Uint8List(20);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    // Base32-encode (no padding) for compatibility with authenticator apps
    return base32.encode(bytes).replaceAll('=', '');
  }

  // ── Build otpauth URI for QR code ─────────────────────────────────────────
  //
  // Format:  otpauth://totp/<issuer>:<account>?secret=<BASE32>&issuer=<issuer>
  // Standard defined by Google Authenticator.
  static String buildOtpauthUrl({
    required String email,
    required String secret,
    String issuer = 'SkillMatch',
  }) {
    final label = Uri.encodeComponent('$issuer:$email');
    return 'otpauth://totp/$label'
        '?secret=$secret'
        '&issuer=${Uri.encodeComponent(issuer)}'
        '&algorithm=SHA1'
        '&digits=6'
        '&period=30';
  }

  // ── Verify a 6-digit TOTP code ────────────────────────────────────────────
  //
  // Checks the current window ±1 interval (± 30 s) to account for clock skew.
  //
  // TODO (production): Replace with a backend API call that performs the
  //   verification and never exposes the secret.
  static bool verifyCode(String secret, String inputCode) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanCode = inputCode.trim().replaceAll(' ', '');

    // Check current 30-second window and the adjacent windows for clock drift
    for (final offset in [-1, 0, 1]) {
      final ts = now + offset * 30 * 1000;
      final expected = OTP.generateTOTPCodeString(
        secret,
        ts,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (expected == cleanCode) return true;
    }
    return false;
  }

  // ── Persist secret securely on-device ────────────────────────────────────
  //
  // The secret is written to Flutter Secure Storage (Keychain / Keystore).
  // This is acceptable for a demo/project. In production the secret lives
  // only on the backend and is never sent to the device after setup.
  static Future<void> saveSecretLocally(String secret) async {
    try {
      await _storage.write(key: _secretKey, value: secret);
    } on MissingPluginException catch (e) {
      _logStorageUnavailable(e);
    } on PlatformException catch (e) {
      _logStorageUnavailable(e);
    } on UnsupportedError catch (e) {
      _logStorageUnavailable(e);
    }
  }

  // ── Read secret from secure storage ──────────────────────────────────────
  static Future<String?> readSecretLocally() async {
    try {
      return await _storage.read(key: _secretKey);
    } on MissingPluginException catch (e) {
      _logStorageUnavailable(e);
      return null;
    } on PlatformException catch (e) {
      _logStorageUnavailable(e);
      return null;
    } on UnsupportedError catch (e) {
      _logStorageUnavailable(e);
      return null;
    }
  }

  // ── Delete secret from secure storage (e.g. on sign-out) ─────────────────
  static Future<void> deleteSecretLocally() async {
    try {
      await _storage.delete(key: _secretKey);
    } on MissingPluginException catch (e) {
      _logStorageUnavailable(e);
    } on PlatformException catch (e) {
      _logStorageUnavailable(e);
    } on UnsupportedError catch (e) {
      _logStorageUnavailable(e);
    }
  }
}
