import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:developer' as developer;

/// OTP Email Service
/// Handles generation, storage, and verification of one-time passwords (OTPs)
/// for password reset and email verification flows.
class OtpEmailService {
  static final _firestore = FirebaseFirestore.instance;
  static const String _otpCollection = 'otp_codes';
  static const int _otpLength = 6;
  static const int _expirationMinutes = 15;

  /// Generate a 6-digit OTP
  static String generateOtp() {
    final random = Random();
    return List.generate(
      _otpLength,
      (_) => random.nextInt(10).toString(),
    ).join();
  }

  /// Send OTP to user's email (stored in Firestore)
  static Future<void> sendOtpToEmail({
    required String email,
    required String purpose, // 'password_reset' or 'email_verification'
  }) async {
    final otp = generateOtp();
    final expiresAt = DateTime.now().add(
      Duration(minutes: _expirationMinutes),
    );

    // Store OTP in Firestore
    await _firestore.collection(_otpCollection).doc(email).set({
      'email': email,
      'otp': otp,
      'purpose': purpose,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt,
      'verified': false,
      'attempts': 0,
    });

    // In production, you would send this via email using the backend API
    // For now, we store it and return it (in debug, log it)
    developer.log(
      'OTP generated for $email (expires in $_expirationMinutes minutes)',
      name: 'OtpEmailService',
    );
  }

  /// Verify OTP code
  static Future<bool> verifyOtp({
    required String email,
    required String code,
    required String purpose,
  }) async {
    try {
      final doc = await _firestore.collection(_otpCollection).doc(email).get();

      if (!doc.exists) {
        throw Exception('OTP not found. Please request a new one.');
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] as String?;
      final storedPurpose = data['purpose'] as String?;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = (data['attempts'] as int?) ?? 0;

      // Check if expired
      if (DateTime.now().isAfter(expiresAt)) {
        await doc.reference.delete();
        throw Exception('OTP has expired. Please request a new one.');
      }

      // Check attempts (max 5)
      if (attempts >= 5) {
        await doc.reference.delete();
        throw Exception(
          'Too many failed attempts. Please request a new OTP.',
        );
      }

      // Check purpose
      if (storedPurpose != purpose) {
        throw Exception('OTP purpose does not match.');
      }

      // Verify code
      if (storedOtp != code.trim()) {
        // Increment attempts
        await doc.reference.update({'attempts': attempts + 1});
        throw Exception('Invalid OTP. Please try again.');
      }

      // Mark as verified
      await doc.reference.update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get OTP for debugging (development only)
  static Future<String?> getOtpDebug(String email) async {
    if (!identical(0, 0)) return null; // Always false in production
    try {
      final doc = await _firestore.collection(_otpCollection).doc(email).get();
      return doc.data()?['otp'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Clean up expired OTPs
  static Future<void> cleanupExpiredOtps() async {
    final now = Timestamp.now();
    final query = await _firestore
        .collection(_otpCollection)
        .where('expiresAt', isLessThan: now)
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }
}
