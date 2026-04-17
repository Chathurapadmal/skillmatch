import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import 'live_chat_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _openFaq;

  // 🎨 New Color System
  static const primary = Color(0xFF4052B6);
  static const deepViolet = Color(0xFF5000D2);
  static const electricPurple = Color(0xFF652FE7);

  static const textPrimary = Color(0xFF2C2F30);
  static const textSecondary = Color(0xFF595C5D);
  static const textMuted = Color(0xFF595C5D);

  static const bgMain = Color(0xFFF5F6F7);
  static const cardBg = Colors.white;

  static const border = Color(0xFFDCE3F0);

  static const info = Color(0xFF4CB9FF);
  static const link = Color(0xFF00618F);
  static const error = Colors.red;

  static const gradient = LinearGradient(
    colors: [Color(0xFF4052B6), Color(0xFF652FE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Future<void> _openSupportEmail() async {
    final gmailUri = Uri.parse(
      'googlegmail://co?to=support@skillmatch.pro&subject=SkillMatch%20Support%20Request',
    );
    final mailtoUri = Uri.parse(
      'mailto:support@skillmatch.pro?subject=SkillMatch%20Support%20Request',
    );

    bool opened = false;
    if (await canLaunchUrl(gmailUri)) {
      opened = await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
    }
    if (!opened) {
      opened = await launchUrl(mailtoUri);
    }

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to open email app right now.'),
        backgroundColor: error,
      ));
    }
  }

  void _openLiveChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LiveChatScreen()),
    );
  }

  static const _faqs = [
    (
      q: 'How does skill matching work?',
      a: 'SkillMatch Pro analyzes your verified skills, credentials, and GitHub activity to calculate a compatibility percentage with each internship role. The higher the percentage, the better the fit.'
    ),
    (
      q: 'How do I verify a skill?',
      a: 'Go to Profile > Verify Skills and take a short quiz for the skill you want to verify. Passing with 70% or above adds a verified badge to that skill on your profile.'
    ),
    (
      q: 'What are blockchain credentials?',
      a: 'Credentials (certificates, degrees, awards) are stored with a verification hash on Firestore and can be shared via QR code. Companies can scan the QR to verify authenticity instantly.'
    ),
    (
      q: 'How does GitHub integration work?',
      a: 'Enter your GitHub username and SkillMatch Pro will analyze your public repos, detect programming languages, and auto-suggest skills to add to your profile.'
    ),
    (
      q: 'Can I use the AI Learning Roadmap feature offline?',
      a: 'No, the AI roadmap requires a connection to our backend service. Make sure you are connected to the internet and that the backend server is running.'
    ),
    (
      q: 'How do I apply for an internship?',
      a: 'Tap the Apply button on any internship card in your Dashboard or the Explore tab. You will be redirected to the company\'s application form.'
    ),
    (
      q: 'How do I delete my account?',
      a: 'Go to Profile > Privacy & Security and scroll to the Danger Zone section. Tap Delete Account. This action is irreversible.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgMain,
      appBar: AppBar(
          title: const Text('Help & Support'),
          backgroundColor: cardBg,
          foregroundColor: textPrimary,
          elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.support_agent, color: Colors.white, size: 36),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How can we help?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Browse FAQs or reach out directly.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ).animate().fade(),
          const SizedBox(height: 24),

          // Quick actions
          _sectionTitle('Quick Actions'),
          Row(children: [
            Expanded(
                child: _actionCard(Icons.email_outlined, 'Email Us',
                    'support@skillmatch.pro', primary,
                    onTap: _openSupportEmail)),
            const SizedBox(width: 12),
            Expanded(
                child: _actionCard(Icons.chat_outlined, 'Live Chat',
                    'AI Support Assistant', info,
                    onTap: _openLiveChat)),
          ]).animate().fade(delay: 60.ms),
          const SizedBox(height: 24),

          // FAQs
          _sectionTitle('Frequently Asked Questions'),
          ..._faqs.asMap().entries.map((entry) {
            final i = entry.key;
            final faq = entry.value;
            final isOpen = _openFaq == i;
            return GestureDetector(
              onTap: () => setState(() => _openFaq = isOpen ? null : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isOpen
                      ? primary.withOpacity(0.08)
                      : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOpen
                        ? primary.withOpacity(0.3)
                        : border,
                  ),
                ),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Expanded(
                        child: Text(faq.q,
                            style: TextStyle(
                                color: isOpen
                                    ? deepViolet
                                    : textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      Icon(isOpen ? Icons.expand_less : Icons.expand_more,
                          color: textMuted, size: 20),
                    ]),
                  ),
                  if (isOpen)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 14),
                      child: Text(faq.a,
                          style: const TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              height: 1.6)),
                    ),
                ]),
              ).animate().fade(delay: Duration(milliseconds: i * 40)),
            );
          }),

          const SizedBox(height: 24),
          _sectionTitle('Legal'),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Column(children: [
              _resourceTile(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                'Read how your data is handled',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
              Divider(height: 1, color: border),
              _resourceTile(
                Icons.description_outlined,
                'Terms of Service',
                'Read usage terms and conditions',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TermsOfServiceScreen(),
                  ),
                ),
              ),
            ]),
          ).animate().fade(delay: 200.ms),

          const SizedBox(height: 24),
          Center(
            child: Text('SkillMatch Pro v1.0.0  •  © 2025 SkillMatch',
                style:
                    const TextStyle(color: textMuted, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );

  Widget _actionCard(IconData icon, String title, String sub, Color color,
      {required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(color: textMuted, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _resourceTile(IconData icon, String title, String sub,
      {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: deepViolet, size: 20),
      title: Text(title,
          style: const TextStyle(color: textPrimary, fontSize: 13)),
      subtitle: Text(sub,
          style: const TextStyle(color: textMuted, fontSize: 11)),
      trailing:
          const Icon(Icons.chevron_right, color: textMuted, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
