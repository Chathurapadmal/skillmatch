import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Terms of Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _TermsSection(
            title: '1. Acceptance',
            body:
                'By using SkillMatch Pro, you agree to these terms and applicable laws and policies.',
          ),
          _TermsSection(
            title: '2. Account Responsibility',
            body:
                'You are responsible for account activity and keeping your login credentials secure.',
          ),
          _TermsSection(
            title: '3. Platform Use',
            body:
                'Do not misuse the platform, submit false information, or attempt unauthorized access.',
          ),
          _TermsSection(
            title: '4. Applications and Hiring',
            body:
                'SkillMatch Pro provides matching and communication tools but does not guarantee hiring outcomes.',
          ),
          _TermsSection(
            title: '5. AI Features',
            body:
                'AI-generated responses and suggestions are assistive and should be reviewed before final decisions.',
          ),
          _TermsSection(
            title: '6. Changes',
            body:
                'We may update these terms and will reflect revisions inside the app.',
          ),
          _TermsSection(
            title: '7. Contact',
            body: 'For support contact support@skillmatch.pro.',
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE3F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
