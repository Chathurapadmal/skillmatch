import 'dart:math';

import 'package:crypto/crypto.dart';
import 'dart:convert';

// ────────────────────────────────────────────────────────────────────────────
// BackupCodeService
// ────────────────────────────────────────────────────────────────────────────
//
// Generates one-time backup/recovery codes that a user can use instead of
// their TOTP authenticator if they lose access to it.
//
// ⚠ PRODUCTION NOTES:
//   - In production, code generation AND verification should happen on a
//     trusted backend.
//   - Only the SHA-256 hashes of the codes are stored (never plain text).
//   - After a backup code is used it must be invalidated in Firestore.

class BackupCodeService {
  static const _codeCount = 8; // how many backup codes to generate
  static const _codeLength = 10; // characters per code (before formatting)
  static const _chars =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  // ↑ Excludes visually confusing chars: I, O, l, 0, 1

  // ── Generate plain-text backup codes ─────────────────────────────────────
  //
  // Returns codes formatted as XXXXX-XXXXX for readability.
  // Show these ONCE to the user and never store them in plain text.
  //
  // TODO (production): Generate on backend and return only to the client
  //   once, never store plain text server-side either.
  static List<String> generateCodes() {
    final rng = Random.secure();
    return List.generate(_codeCount, (_) {
      final raw = List.generate(
        _codeLength,
        (_) => _chars[rng.nextInt(_chars.length)],
      ).join();
      // Format: XXXXX-XXXXX
      return '${raw.substring(0, 5)}-${raw.substring(5)}';
    });
  }

  // ── Hash codes for safe storage ───────────────────────────────────────────
  //
  // Each code is SHA-256 hashed before being written to Firestore so that even
  // if the database is compromised the plain-text codes are not exposed.
  static List<String> hashCodes(List<String> plainCodes) {
    return plainCodes.map((code) => _hashOne(code)).toList();
  }

  // ── Verify a backup code ──────────────────────────────────────────────────
  //
  // Returns the index of the matched code in [hashedCodes], or -1 if not found.
  // The caller is responsible for removing the used code from Firestore.
  //
  // TODO (production): Perform this verification on the backend.
  static int verifyCode(String inputCode, List<String> hashedCodes) {
    final normalised = inputCode.trim().toUpperCase().replaceAll(' ', '');
    // Accept both raw (XXXXXXXXXX) and formatted (XXXXX-XXXXX) input
    final withDash = normalised.length == 10
        ? '${normalised.substring(0, 5)}-${normalised.substring(5)}'
        : normalised;

    final inputHash = _hashOne(withDash);
    return hashedCodes.indexOf(inputHash);
  }

  // ── Internal SHA-256 helper ───────────────────────────────────────────────
  static String _hashOne(String code) {
    final bytes = utf8.encode(code.toUpperCase());
    return sha256.convert(bytes).toString();
  }
}
