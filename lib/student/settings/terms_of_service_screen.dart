import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const primary = Color(0xFF4052B6);
  static const deepViolet = Color(0xFF5000D2);
  static const electricPurple = Color(0xFF652FE7);

  static const textPrimary = Color(0xFF2C2F30);
  static const textSecondary = Color(0xFF595C5D);

  static const bgMain = Color(0xFFF5F6F7);
  static const cardBg = Colors.white;

  static const border = Color(0xFFDCE3F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgMain,
      appBar: AppBar(
        backgroundColor: cardBg,
        foregroundColor: textPrimary,
        elevation: 0,
        title: const Text(
          'Terms of Service',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermsSection({required this.title, required this.body});

  
  static const textPrimary = Color(0xFF2C2F30);
  static const textSecondary = Color(0xFF595C5D);
  static const cardBg = Colors.white;
  static const border = Color(0xFFDCE3F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
            TermsOfServiceScreencard(
              icon: Icons.smart_toy_outlined,
              title: 'AI Features',
              body:
                  'AI-generated suggestions are meant to assist you. Always review content before making decisions.',
            ),
            TermsOfServiceScreencard(
              icon: Icons.update_outlined,
              title: 'Changes',
              body:
                  'We may update these terms occasionally. Revisions will be reflected in-app, and continued use means you accept changes.',
            ),
            TermsOfServiceScreencard(
              icon: Icons.contact_mail_outlined,
              title: 'Contact',
              body: 'For support, contact us at support@skillmatch.pro.',
            ),
          ],
        ),
      ),
    );
  }
}
