import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillmatch/pages/applicant/advanced/industry_forecast_screen.dart';
import 'package:skillmatch/pages/applicant/advanced/roadmap_screen.dart';
import 'package:skillmatch/pages/applicant/advanced/skill_verification_screen.dart';
import 'package:skillmatch/pages/applicant/home/saved_jobs_screen.dart';
import 'package:skillmatch/pages/applicant/profile/profile_views_screen.dart';
import 'package:skillmatch/pages/applicant/profile/profilepage.dart';
import 'package:skillmatch/pages/applicant/settings/help_support_screen.dart';
import 'package:skillmatch/pages/applicant/settings/privacy_security_screen.dart';
import 'package:skillmatch/services/auth_service.dart';
import 'package:skillmatch/shared/notifications_center_screen.dart';
import '../../models/user_model.dart';
import '../../shared/chat_overlay.dart';

const Color _primary = Color(0xFF1565C0);
const Color _navy = Color(0xFF1E3A5F);
const Color _accent = Color(0xFF2E86AB);
const Color _background = Color(0xFFF8FAFC);
const Color _softBlue = Color(0xFFEAF3FA);
const Color _darkText = Color(0xFF1E3A5F);
const Color _mutedText = Color(0xFF64748B);
const Color _cardBorder = Color(0xFFDCE3F0);

const LinearGradient _mainGradient = LinearGradient(
  colors: [_navy, _primary, _accent],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class ApplicantDashboard extends StatelessWidget {
  final UserModel user;

  const ApplicantDashboard({super.key, required this.user});

  String _normalizeIndustry(String? value) =>
      (value ?? '').trim().toLowerCase();

  int _calculateMatch(
      List<String> internshipSkills, List<String> studentSkills) {
    if (internshipSkills.isEmpty || studentSkills.isEmpty) return 60;
    final studentSet = studentSkills.map((e) => e.toLowerCase()).toSet();
    final overlap = internshipSkills
        .where((skill) => studentSet.contains(skill.toLowerCase()))
        .length;
    final ratio = overlap / internshipSkills.length;
    return (60 + (ratio * 40)).round().clamp(60, 99);
  }

  @override
  Widget build(BuildContext context) {
    return ChatOverlay(
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 18,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: _mainGradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.work_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'SkillMatch',
                style: TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: _softBlue,
                foregroundColor: _navy,
              ),
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsCenterScreen(),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              child: PopupMenuButton<String>(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 8,
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _softBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: _cardBorder),
                  ),
                  child: const Icon(Icons.person, color: _navy, size: 20),
                ),
                onSelected: (value) async {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                    return;
                  }
                  if (value == 'help') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    );
                    return;
                  }
                  if (value == 'privacy') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacySecurityScreen(),
                      ),
                    );
                    return;
                  }
                  if (value == 'signout') {
                    await AuthService.signOut();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: _mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: _navy),
                        SizedBox(width: 8),
                        Text('My Profile', style: TextStyle(color: _navy)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'help',
                    child: Row(
                      children: [
                        Icon(Icons.support_agent_outlined, color: _navy),
                        SizedBox(width: 8),
                        Text('Help & Support', style: TextStyle(color: _navy)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'privacy',
                    child: Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined, color: _navy),
                        SizedBox(width: 8),
                        Text(
                          'Privacy & Security',
                          style: TextStyle(color: _navy),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            final profile =
                profileSnapshot.data?.data() ?? const <String, dynamic>{};
            final savedCount =
                ((profile['savedInternships'] as List?) ?? const []).length;
            final profileViews =
                (profile['profileViews'] as num?)?.toInt() ?? 0;
            final industry =
                ((profile['industry'] ?? profile['field']) as String?) ?? '';
            final studentSkills = ((profile['skills'] as List?) ?? const [])
                .map((e) => '$e')
                .toList();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .where('studentId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, _) {
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DashboardHero(
                        name: user.displayName,
                        industry:
                            industry.isEmpty ? 'Career Dashboard' : industry,
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'Profile Snapshot',
                        subtitle: 'Your saved roles and profile activity',
                        icon: Icons.insights_rounded,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'SAVED JOBS',
                              count: '$savedCount',
                              trendText: '+4 this week',
                              isPositive: true,
                              actionText: 'View list',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SavedJobsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'PROFILE VIEWS',
                              count: '$profileViews',
                              trendText: '+12% vs last month',
                              isPositive: true,
                              actionText: 'See who viewed',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileViewsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _SectionHeader(
                        title: 'Quick Actions',
                        subtitle: 'Jump into tools that improve your profile',
                        icon: Icons.bolt_rounded,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryActionCard(
                              icon: Icons.map,
                              label: 'Career\nRoadmap',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RoadmapScreen(
                                      field: 'IT & Software',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _SecondaryActionCard(
                              icon: Icons.payments_outlined,
                              label: 'Salary\nTrends',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IndustryForecastScreen(
                                      field: industry.trim().isEmpty
                                          ? 'IT & Software'
                                          : industry,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SecondaryFullWidthActionCard(
                        icon: Icons.auto_awesome,
                        label: 'Skill Match AI',
                        subtitle: 'Verify skills and improve your matches',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SkillVerificationScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: _SectionHeader(
                              title: 'Recommended Jobs',
                              subtitle: 'Best matches based on your profile',
                              icon: Icons.work_outline_rounded,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _softBlue,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'See All',
                                    style: TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: _primary,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('internships')
                            .where('active', isEqualTo: true)
                            .limit(50)
                            .snapshots(),
                        builder: (context, internshipSnapshot) {
                          if (internshipSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child:
                                    CircularProgressIndicator(color: _primary),
                              ),
                            );
                          }

                          final internships =
                              internshipSnapshot.data?.docs ?? const [];
                          final normalizedIndustry =
                              _normalizeIndustry(industry);
                          final mapped = internships.map((doc) {
                            final data = doc.data();
                            final tags = ((data['skills'] as List?) ?? const [])
                                .map((e) => '$e')
                                .toList();

                            return {
                              'title':
                                  (data['title'] as String?) ?? 'Internship',
                              'company':
                                  (data['company'] as String?) ?? 'Company',
                              'location': ((data['type'] as String?) ??
                                      (data['location'] as String?) ??
                                      'Remote')
                                  .trim(),
                              'jobType':
                                  (data['jobType'] as String?) ?? 'Full-time',
                              'salary': (data['salary'] as String?) ??
                                  '\$120k - \$150k',
                              'industry':
                                  ((data['industry'] as String?) ?? '').trim(),
                              'match': _calculateMatch(tags, studentSkills),
                            };
                          }).where((item) {
                            if (normalizedIndustry.isEmpty) return true;
                            final jobIndustry =
                                _normalizeIndustry(item['industry'] as String?);
                            return jobIndustry.isEmpty ||
                                jobIndustry == normalizedIndustry;
                          }).toList();

                          mapped.sort(
                            (a, b) => (b['match'] as int)
                                .compareTo(a['match'] as int),
                          );

                          if (mapped.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: const Text(
                                'No active jobs found for your profile right now.',
                                style: TextStyle(color: _mutedText),
                              ),
                            );
                          }

                          return Column(
                            children: mapped.take(5).map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _JobCard(
                                  title: item['title'] as String,
                                  company: item['company'] as String,
                                  location: item['location'] as String,
                                  jobType: item['jobType'] as String,
                                  salary: item['salary'] as String,
                                  matchRate: item['match'] as int,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String name;
  final String industry;

  const _DashboardHero({
    required this.name,
    required this.industry,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: _mainGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -28,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 32,
            bottom: -40,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      industry,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome back,\n$firstName!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You\'ve got 3 new job matches\nwaiting for you today.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool compact;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!compact) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primary, size: 20),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _mutedText,
                  fontSize: 12.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final String trendText;
  final bool isPositive;
  final String actionText;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.trendText,
    required this.isPositive,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 154),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              title.contains('SAVED')
                  ? Icons.bookmark_rounded
                  : Icons.visibility_rounded,
              color: _primary,
              size: 19,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              color: _darkText,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isPositive ? _softBlue : Colors.red[50],
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? _accent : Colors.red,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  trendText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPositive ? _accent : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionText,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: _primary, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 142,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: _mainGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withOpacity(0.20)),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 142,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _softBlue,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: _primary, size: 24),
            ),
            Text(
              label,
              style: const TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryFullWidthActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SecondaryFullWidthActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, _accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: _mutedText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String jobType;
  final String salary;
  final int matchRate;

  const _JobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    required this.salary,
    required this.matchRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, _accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Icon(Icons.business, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _darkText,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _softBlue,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: _primary,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$matchRate%',
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  company,
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _JobInfoPill(icon: Icons.location_on, text: location),
                    _JobInfoPill(icon: Icons.access_time_filled, text: jobType),
                    _JobInfoPill(icon: Icons.payments, text: salary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobInfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _JobInfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accent, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
