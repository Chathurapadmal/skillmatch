import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          backgroundColor: _background,
          elevation: 0,
          title: const Text(
            'SkillMatch',
            style: TextStyle(
              color: _primary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: _navy),
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
                color: const Color(0xFFF8FBFF),
                surfaceTintColor: Colors.transparent,
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: _navy, size: 20),
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                        Text('My Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'help',
                    child: Row(
                      children: [
                        Icon(Icons.support_agent_outlined, color: _navy),
                        SizedBox(width: 8),
                        Text('Help & Support'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'privacy',
                    child: Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined, color: _navy),
                        SizedBox(width: 8),
                        Text('Privacy & Security'),
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
            const SizedBox(width: 8),
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
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,\n${user.displayName.split(' ').first}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'You\'ve got 3 new job matches\nwaiting for you today.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _StatCard(
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
                      const SizedBox(height: 16),
                      _StatCard(
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
                      const SizedBox(height: 32),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SecondaryActionCard(
                              icon: Icons.payments_outlined,
                              label: 'Salary\nTrends',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: _SecondaryFullWidthActionCard(
                          icon: Icons.auto_awesome,
                          label: 'Skill Match AI',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SkillVerificationScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recommended Jobs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _darkText,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Row(
                              children: [
                                Text(
                                  'See All',
                                  style: TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: _primary,
                                  size: 18,
                                ),
                              ],
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
                              padding: EdgeInsets.symmetric(vertical: 16),
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
                            return const Text(
                              'No active jobs found for your profile right now.',
                              style: TextStyle(color: _mutedText),
                            );
                          }

                          return Column(
                            children: mapped.take(5).map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFE6F7F8) : Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? _accent : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: TextStyle(
                        color: isPositive ? _accent : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                Text(
                  actionText,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: _primary, size: 16),
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
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primary, size: 24),
            ),
            Text(
              label,
              style: const TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
  final VoidCallback onTap;

  const _SecondaryFullWidthActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _softBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primary, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.business, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _softBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: _primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$matchRate% Match',
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _JobInfoPill(icon: Icons.location_on, text: location),
                    const SizedBox(width: 16),
                    _JobInfoPill(icon: Icons.access_time_filled, text: jobType),
                  ],
                ),
                const SizedBox(height: 8),
                _JobInfoPill(icon: Icons.payments, text: salary),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _mutedText, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: _mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}