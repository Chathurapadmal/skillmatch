import 'package:flutter/material.dart';

import 'package:skillmatch/widgets/policy/terms_of_service_card.dart';

const Color _primary = Color(0xFF1565C0);
const Color _background = Color(0xFFF8FAFC);

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            TermsOfServiceCard(
              icon: Icons.check_circle_outline,
              title: 'Acceptance',
              body:
                  'By using SkillMatch Pro, you agree to these terms and all applicable laws and policies. Please read carefully.',
            ),
            TermsOfServiceCard(
              icon: Icons.lock_outline,
              title: 'Account Responsibility',
              body:
                  'You are responsible for all activity on your account. Keep your login credentials secure and confidential.',
            ),
            TermsOfServiceCard(
              icon: Icons.build_outlined,
              title: 'Platform Use',
              body:
                  'Do not misuse the platform, submit false information, or attempt unauthorized access. Respect the community guidelines.',
            ),
            TermsOfServiceCard(
              icon: Icons.work_outline,
              title: 'Applications and Hiring',
              body:
                  'SkillMatch Pro provides tools for matching and communication but cannot guarantee employment or hiring outcomes.',
            ),
            TermsOfServiceCard(
              icon: Icons.smart_toy_outlined,
              title: 'AI Features',
              body:
                  'AI-generated suggestions are meant to assist you. Always review content before making decisions.',
            ),
            TermsOfServiceCard(
              icon: Icons.update_outlined,
              title: 'Changes',
              body:
                  'We may update these terms occasionally. Revisions will be reflected in-app, and continued use means you accept changes.',
            ),
            TermsOfServiceCard(
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