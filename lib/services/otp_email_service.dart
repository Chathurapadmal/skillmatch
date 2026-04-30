import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;
import 'email_service.dart';

/// OTP Email Service
/// Handles generation, storage, and verification of one-time passwords (OTPs)
/// for password reset and email verification flows.
class OtpEmailService {
  static const int _otpLength = 6;
  static const int _expirationMinutes = 15;
  static final Map<String, _OtpRecord> _otpCache = <String, _OtpRecord>{};

  /// Generate a 6-digit OTP
  static String generateOtp() {
    final random = Random();
    return List.generate(
      _otpLength,
      (_) => random.nextInt(10).toString(),
    ).join();
  }

  /// Send OTP to user's email (stored locally in memory for development)
  static Future<void> sendOtpToEmail({
    required String email,
    required String purpose, // 'password_reset' or 'email_verification'
  }) async {
    final otp = generateOtp();
    final expiresAt = DateTime.now().add(
      Duration(minutes: _expirationMinutes),
    );

    _otpCache[email] = _OtpRecord(
      email: email,
      otp: otp,
      purpose: purpose,
      expiresAt: expiresAt,
    );

    // Send the OTP via the backend email endpoint (Nodemailer)
    try {
      final sent = await EmailService.sendOtpEmail(
        to: email,
        otp: otp,
        purpose: purpose,
      );

      developer.log(
        'OTP generated for $email (expires in $_expirationMinutes minutes). Email sent: $sent',
        name: 'OtpEmailService',
      );
    } catch (e) {
      developer.log('Failed to send OTP email: $e', name: 'OtpEmailService');
      rethrow;
    }
  }

  /// Verify OTP code
  static Future<bool> verifyOtp({
    required String email,
    required String code,
    required String purpose,
  }) async {
    try {
      final record = _otpCache[email];

      if (record == null) {
        throw Exception('OTP not found. Please request a new one.');
      }

      final attempts = record.attempts;

      // Check if expired
      if (DateTime.now().isAfter(record.expiresAt)) {
        _otpCache.remove(email);
        throw Exception('OTP has expired. Please request a new one.');
      }

      // Check attempts (max 5)
      if (attempts >= 5) {
        _otpCache.remove(email);
        throw Exception(
          'Too many failed attempts. Please request a new OTP.',
        );
      }

      // Check purpose
      if (record.purpose != purpose) {
        throw Exception('OTP purpose does not match.');
      }

      // Verify code
      if (record.otp != code.trim()) {
        _otpCache[email] = record.copyWith(attempts: attempts + 1);
        throw Exception('Invalid OTP. Please try again.');
      }

      // Mark as verified
      _otpCache.remove(email);

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Get OTP for debugging (development only)
  static Future<String?> getOtpDebug(String email) async {
    return _otpCache[email]?.otp;
  }

  /// Clean up expired OTPs
  static Future<void> cleanupExpiredOtps() async {
    final now = DateTime.now();
    final expiredKeys = _otpCache.entries
        .where((entry) => now.isAfter(entry.value.expiresAt))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _otpCache.remove(key);
    }
  }
}

class _OtpRecord {
  final String email;
  final String otp;
  final String purpose;
  final DateTime expiresAt;
  final int attempts;

  const _OtpRecord({
    required this.email,
    required this.otp,
    required this.purpose,
    required this.expiresAt,
    this.attempts = 0,
  });

  _OtpRecord copyWith({int? attempts}) {
    return _OtpRecord(
      email: email,
      otp: otp,
      purpose: purpose,
      expiresAt: expiresAt,
      attempts: attempts ?? this.attempts,
    );
  }
}
