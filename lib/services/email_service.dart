import 'package:http/http.dart' as http;
import 'dart:convert';

/// Email Sending Service
/// Handles sending emails through the backend API
class EmailService {
  static const String _backendUrl =
      'http://localhost:5000'; // Update in production

  /// Send email via backend
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    required String htmlBody,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/send-email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'to': to,
              'subject': subject,
              'text': body,
              'html': htmlBody,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      print(
        'Email sending failed: ${response.statusCode} - ${response.body}',
      );
      return false;
    } catch (e) {
      print('Email sending error: $e');
      return false;
    }
  }

  /// Send OTP email
  static Future<bool> sendOtpEmail({
    required String to,
    required String otp,
    required String purpose, // 'password_reset' or 'email_verification'
  }) async {
    final subject = purpose == 'password_reset'
        ? 'Reset Your SkillMatch Password'
        : 'Verify Your SkillMatch Email';

    final body = '''
Your One-Time Password (OTP) is: $otp

This OTP will expire in 15 minutes.

If you did not request this, please ignore this email.

Best regards,
SkillMatch Team
''';

    final htmlBody = '''
<html>
  <body style="font-family: Arial, sans-serif; background-color: #f5f5f5; padding: 20px;">
    <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
      <h2 style="color: #1565C0; text-align: center;">SkillMatch</h2>
      <h3 style="color: #333;">$subject</h3>
      <p style="color: #666; font-size: 16px;">Your One-Time Password (OTP) is:</p>
      <div style="background-color: #f0f0f0; padding: 20px; border-radius: 4px; text-align: center; margin: 20px 0;">
        <p style="font-size: 32px; letter-spacing: 5px; color: #1565C0; font-weight: bold; margin: 0;">$otp</p>
      </div>
      <p style="color: #999; font-size: 14px;">This OTP will expire in 15 minutes.</p>
      <p style="color: #666;">If you did not request this, please ignore this email.</p>
      <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
      <p style="color: #999; font-size: 12px; text-align: center;">SkillMatch Team</p>
    </div>
  </body>
</html>
''';

    return sendEmail(
      to: to,
      subject: subject,
      body: body,
      htmlBody: htmlBody,
    );
  }

  /// Send email verification notification
  static Future<bool> sendEmailVerificationNotification({
    required String to,
    required String userName,
  }) async {
    const subject = 'Email Verified Successfully';
    final body = '''
Hello $userName,

Your email has been verified successfully. You can now apply for internships and edit your profile.

Best regards,
SkillMatch Team
''';

    final htmlBody = '''
<html>
  <body style="font-family: Arial, sans-serif; background-color: #f5f5f5; padding: 20px;">
    <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
      <h2 style="color: #1565C0; text-align: center;">SkillMatch</h2>
      <h3 style="color: #333;">$subject</h3>
      <p style="color: #666;">Hello $userName,</p>
      <p style="color: #666; margin-bottom: 20px;">Your email has been verified successfully. You can now apply for internships and edit your profile.</p>
      <p style="color: #999; font-size: 14px; margin-top: 20px;">Best regards,<br>SkillMatch Team</p>
    </div>
  </body>
</html>
''';

    return sendEmail(
      to: to,
      subject: subject,
      body: body,
      htmlBody: htmlBody,
    );
  }

  /// Send application confirmation email to applicant
  static Future<bool> sendApplicationConfirmationEmail({
    required String to,
    required String userName,
    required String internshipTitle,
    required String companyName,
  }) async {
    final subject = 'Application Confirmation - $internshipTitle';
    final body = '''
Hello $userName,

Your application for the $internshipTitle position at $companyName has been submitted successfully.

We will notify you as soon as the company reviews your application.

Best regards,
SkillMatch Team
''';

    final htmlBody = '''
<html>
  <body style="font-family: Arial, sans-serif; background-color: #f5f5f5; padding: 20px;">
    <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
      <h2 style="color: #1565C0; text-align: center;">SkillMatch</h2>
      <h3 style="color: #333;">$subject</h3>
      <p style="color: #666;">Hello $userName,</p>
      <p style="color: #666;">Your application for the <strong>$internshipTitle</strong> position at <strong>$companyName</strong> has been submitted successfully.</p>
      <p style="color: #666;">We will notify you as soon as the company reviews your application.</p>
      <p style="color: #999; font-size: 14px; margin-top: 20px;">Best regards,<br>SkillMatch Team</p>
    </div>
  </body>
</html>
''';

    return sendEmail(
      to: to,
      subject: subject,
      body: body,
      htmlBody: htmlBody,
    );
  }
}
