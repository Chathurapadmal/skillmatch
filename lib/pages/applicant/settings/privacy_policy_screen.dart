import 'package:flutter/material.dart';

import '../../../shared/applicant_notification_button.dart';

const Color _navy = Color(0xFF1E3A5F);
const Color _background = Color(0xFFF8FAFC);
const Color _cardBorder = Color(0xFFDCE3F0);
const Color _mutedText = Color(0xFF64748B);

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [ApplicantNotificationButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _PolicySection(
            title: '1. Data We Collect',
            body:
                'We collect profile details, skills, credentials, internship applications, and usage events required to operate SkillMatch Pro.',
          ),
          _PolicySection(
            title: '2. How We Use Data',
            body:
                'Your data is used for matching internships, application processing, analytics, and improving recommendations and support quality.',
          ),
          _PolicySection(
            title: '3. Sharing',
            body:
                'We only share required profile and application data with companies you apply to or interact with.',
          ),
          _PolicySection(
            title: '4. Security',
            body:
                'We use Firebase authentication, access control, and encrypted transport to protect your account and data in transit.',
          ),
          _PolicySection(
            title: '5. Controls',
            body:
                'You can adjust profile visibility, notification preferences, and request account deletion from settings.',
          ),
          _PolicySection(
            title: '6. Contact',
            body: 'For privacy concerns contact support@skillmatch.pro.',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}