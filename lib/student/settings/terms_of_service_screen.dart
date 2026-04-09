import 'package:flutter/material.dart';
import 'package:skillmatch/widgets/termofservice_card.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Terms of Service',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            TermsOfServiceScreencard(
              icon: Icons.check_circle_outline,
              title: 'Acceptance',
              body:
                  'By using SkillMatch Pro, you agree to these terms and all applicable laws and policies. Please read carefully.',
            ),
            TermsOfServiceScreencard(
              icon: Icons.lock_outline,
              title: 'Account Responsibility',
              body:
                  'You are responsible for all activity on your account. Keep your login credentials secure and confidential.',
            ),
            TermsOfServiceScreencard(
              icon: Icons.build_outlined,
              title: 'Platform Use',
              body:
                  'Do not misuse the platform, submit false information, or attempt unauthorized access. Respect the community guidelines.',
            ),
            TermsOfServiceScreencard(
              icon: Icons.work_outline,
              title: 'Applications and Hiring',
              body:
                  'SkillMatch Pro provides tools for matching and communication but cannot guarantee employment or hiring outcomes.',
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
