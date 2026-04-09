import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillmatch/student/advanced/roadmap_screen.dart';
import 'package:skillmatch/student/advanced/skill_verification_screen.dart';
import 'package:skillmatch/student/home/home_screen.dart';
import 'package:skillmatch/student/home/saved_jobs_screen.dart';
import 'package:skillmatch/student/profile/profile_views_screen.dart';
import 'package:skillmatch/student/profile/profilepage.dart';
import 'package:skillmatch/student/settings/help_support_screen.dart';
import 'package:skillmatch/student/settings/privacy_security_screen.dart';
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
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'SkillMatch',
            style: TextStyle(
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsCenterScreen(),
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1565C0),
                child: Icon(Icons.person, color: Colors.white, size: 18),
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
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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
              builder: (context, appSnapshot) {
                final appliedCount = appSnapshot.data?.docs.length ?? 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Welcome banner ─────────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${user.displayName.split(' ').first}! 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your career journey continues here.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Quick stats ────────────────────────────────────────────────
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.work_outline,
                            label: 'Applied',
                            value: '$appliedCount',
                            color: const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.bookmark_outline,
                            label: 'Saved',
                            value: '$savedCount',
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SavedJobsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.visibility_outlined,
                            label: 'Profile Views',
                            value: '$profileViews',
                            color: Colors.green,
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
                      const SizedBox(height: 24),

                      // ── Actions ────────────────────────────────────────────────────
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.map_outlined,
                                  label: 'Roadmap',
                                  color: const Color(0xFF1565C0),
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.trending_up,
                                  label: 'Trends',
                                  color: const Color(0xFF2B6CB0),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const IndustryForecastScreen(
                                          field: 'IT & Software',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _ActionCard(
                              icon: Icons.psychology_outlined,
                              label: 'Skill Match AI',
                              color: Colors.teal,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SkillVerificationScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Recommended jobs (real data only) ─────────────────────────
                      const Text(
                        'Recommended Jobs',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
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
                              'aboutRole':
                                  ((data['aboutRole'] as String?) ?? '').trim(),
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
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _JobCard(
                                  title: item['title'] as String,
                                  company: item['company'] as String,
                                  location: item['location'] as String,
                                  aboutRole: item['aboutRole'] as String,
                                  matchRate: item['match'] as int,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: card,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
  final String aboutRole;
  final int matchRate;

  const _JobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.aboutRole,
    required this.matchRate,
  });

  @override
  Widget build(BuildContext context) {
    final color = matchRate >= 80
        ? Colors.green
        : matchRate >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
            child: const Icon(Icons.business, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('$company · $location',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                if (aboutRole.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    aboutRole.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$matchRate%',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
