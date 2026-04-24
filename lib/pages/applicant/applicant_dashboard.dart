import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillmatch/pages/applicant/advanced/roadmap_screen.dart';
import 'package:skillmatch/pages/applicant/advanced/skill_verification_screen.dart';
import 'package:skillmatch/pages/applicant/home/home_screen.dart';
import 'package:skillmatch/pages/applicant/home/saved_jobs_screen.dart';
import 'package:skillmatch/pages/applicant/profile/profile_views_screen.dart';
import 'package:skillmatch/pages/applicant/profile/profilepage.dart';
import 'package:skillmatch/pages/applicant/settings/help_support_screen.dart';
import 'package:skillmatch/pages/applicant/settings/privacy_security_screen.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../shared/chat_overlay.dart';
import '../../shared/notifications_center_screen.dart';

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
        backgroundColor: const Color(0xFFF5F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F8FA),
          elevation: 0,
          title: const Text(
            'SkillMatch',
            style: TextStyle(
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Color(0xFF4A5568)),
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
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE2E8F0),
                  child: Icon(Icons.person, color: Color(0xFF4A5568)),
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
                          builder: (_) => const HelpSupportScreen()),
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
                        Text(user.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(user.email,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(children: [
                      Icon(Icons.person_outline),
                      SizedBox(width: 8),
                      Text('My Profile'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'help',
                    child: Row(children: [
                      Icon(Icons.support_agent_outlined),
                      SizedBox(width: 8),
                      Text('Help & Support'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'privacy',
                    child: Row(children: [
                      Icon(Icons.privacy_tip_outlined),
                      SizedBox(width: 8),
                      Text('Privacy & Security'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'signout',
                    child: Row(children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ]),
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
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Welcome banner ─────────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D47A1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,\n${user.displayName.split(' ').first}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'You\'ve got 3 new job matches\nwaiting for you today.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Quick stats ────────────────────────────────────────────────
                      Column(
                        children: [
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
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Actions ────────────────────────────────────────────────────
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A202C)),
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
                              onTap: () {
                                // Updated to map correctly or placeholder as original imported ForecastScreen
                              },
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

                      // ── Recommended jobs ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recommended Jobs',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A202C)),
                          ),
                          GestureDetector(
                            onTap: () {}, // Handle "See All" logic if needed
                            child: const Row(
                              children: [
                                Text(
                                  'See All',
                                  style: TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                Icon(Icons.keyboard_arrow_down,
                                    color: Color(0xFF1565C0), size: 18),
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
                                child: CircularProgressIndicator(
                                    color: Color(0xFF1565C0)),
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
                              'jobType': (data['jobType'] as String?) ??
                                  'Full-time', // Extracted for UI
                              'salary': (data['salary'] as String?) ??
                                  '\$120k - \$150k', // Extracted for UI
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

                          mapped.sort((a, b) =>
                              (b['match'] as int).compareTo(a['match'] as int));

                          if (mapped.isEmpty) {
                            return const Text(
                              'No active jobs found for your profile right now.',
                              style: TextStyle(color: Colors.grey),
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
                      const SizedBox(height: 60), // Spacing
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

// ── Helpers & Components ────────────────────────────────────────────────────────

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
            color: Colors.black.withOpacity(0.02),
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
              color: Color(0xFF718096),
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
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFE6FFFA) : Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? const Color(0xFF38A169) : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: TextStyle(
                        color:
                            isPositive ? const Color(0xFF38A169) : Colors.red,
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
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward,
                    color: Color(0xFF1565C0), size: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2962FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2962FF).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 24),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1565C0), size: 24),
            ),
            const SizedBox(height: 24),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A202C),
                fontSize: 18,
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1565C0), size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A202C),
                fontSize: 18,
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.business, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company,
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on,
                        color: Color(0xFF1565C0), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$matchRate% Match',
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _JobInfoPill(icon: Icons.location_on_outlined, text: location),
              const SizedBox(width: 16),
              _JobInfoPill(icon: Icons.access_time_outlined, text: jobType),
            ],
          ),
          const SizedBox(height: 12),
          _JobInfoPill(icon: Icons.payments_outlined, text: salary),
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
        Icon(icon, color: const Color(0xFFA0AEC0), size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF718096),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
