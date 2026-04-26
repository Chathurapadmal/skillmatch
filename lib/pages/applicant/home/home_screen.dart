import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/firestore_service.dart';
import '../../../services/ai_service.dart';
import '../../../services/notification_service.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/applicant_notification_button.dart';
import '../../../shared/notifications_center_screen.dart';
import '../../../shared/chat_overlay.dart';
import '../jobs/browse_jobs_page.dart';
import '../advanced/roadmap_screen.dart';
import '../profile/profilepage.dart';
import 'saved_jobs_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const BrowseJobsPage(),
      const _MyCvTab(),
      const _AppliedTab(),
      const ProfilePage(),
    ];

    return ChatOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: IndexedStack(index: _selectedIndex, children: tabs),
        bottomNavigationBar: (_selectedIndex == 0 || _selectedIndex == 2)
            ? null
            : Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                ),
                child: NavigationBar(
                  height: 74,
                  selectedIndex: _selectedIndex,
                  backgroundColor: Colors.transparent,
                  indicatorColor: const Color(0xFF1565C0).withOpacity(0.12),
                  onDestinationSelected: (value) =>
                      setState(() => _selectedIndex = value),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon:
                          Icon(Icons.search, color: Color(0xFF1565C0)),
                      label: 'Browse Jobs',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.upload_file_outlined),
                      selectedIcon: Icon(Icons.upload_file_rounded,
                          color: Color(0xFF1565C0)),
                      label: 'My CV',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon:
                          Icon(Icons.assignment, color: Color(0xFF1565C0)),
                      label: 'Applications',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon:
                          Icon(Icons.person, color: Color(0xFF1565C0)),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StudentHomeTab extends StatefulWidget {
  const _StudentHomeTab();

  @override
  State<_StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<_StudentHomeTab> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _internships = [];
  bool _loading = true;
  final Set<String> _savedInternshipIds = {};
  final Set<String> _savingInternshipIds = {};

  String _normalizeIndustry(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

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

  Future<void> _notifyCompanyOnApplication(
    Map<String, dynamic> internship,
  ) async {
    final companyId = (internship['companyId'] as String? ?? '').trim();
    final studentUid = FirebaseAuth.instance.currentUser?.uid;
    if (companyId.isEmpty || studentUid == null) return;

    final companyDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();
    final companyData = companyDoc.data() ?? <String, dynamic>{};
    if (companyData['notifyNewApplications'] == false) {
      return;
    }

    final studentName =
        (_profile?['name'] as String?)?.trim().isNotEmpty == true
            ? (_profile?['name'] as String)
            : (FirebaseAuth.instance.currentUser?.displayName ?? 'A student');
    final title = (internship['title'] as String?)?.trim().isNotEmpty == true
        ? internship['title'] as String
        : 'your internship';

    await NotificationService.instance.createInAppNotification(
      recipientId: companyId,
      senderId: studentUid,
      type: 'application_submitted',
      title: 'New internship application',
      body: '$studentName applied for $title.',
      data: {
        'internshipId': internship['id'] ?? '',
        'companyId': companyId,
        'studentId': studentUid,
      },
    );
  }

  Future<void> _notifyApplicantOnApplication(
    Map<String, dynamic> internship,
  ) async {
    final studentUid = FirebaseAuth.instance.currentUser?.uid;
    if (studentUid == null) return;

    final title = (internship['title'] as String?)?.trim().isNotEmpty == true
        ? internship['title'] as String
        : 'this internship';
    final company =
        (internship['company'] as String?)?.trim().isNotEmpty == true
            ? internship['company'] as String
            : 'the company';

    await NotificationService.instance.createInAppNotification(
      recipientId: studentUid,
      senderId: internship['companyId'] as String?,
      type: 'application_confirmation',
      title: 'Application submitted',
      body: 'You applied for $title at $company.',
      data: {
        'internshipId': internship['id'] ?? '',
        'companyId': internship['companyId'] ?? '',
      },
    );
  }

  Future<void> _applyForInternship(Map<String, dynamic> internship) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final internshipId = internship['id'] as String?;
    if (internshipId == null || internshipId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to apply for this internship right now.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    final existing = await FirebaseFirestore.instance
        .collection('applications')
        .where('studentId', isEqualTo: uid)
        .where('internshipId', isEqualTo: internshipId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have already applied for this internship.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    await FirebaseFirestore.instance.collection('applications').add({
      'studentId': uid,
      'studentName': _profile?['name'] ??
          FirebaseAuth.instance.currentUser?.displayName ??
          '',
      'studentEmail':
          _profile?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '',
      'internshipId': internshipId,
      'companyId': internship['companyId'],
      'title': internship['title'],
      'company': internship['company'],
      'industry': internship['industry'],
      'status': 'applied',
      'appliedAt': FieldValue.serverTimestamp(),
    });

    await _notifyApplicantOnApplication(internship);
    await _notifyCompanyOnApplication(internship);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Application submitted successfully.'),
      backgroundColor: AppTheme.success,
    ));
  }

  // ignore: unused_element
  Future<void> _toggleSavedInternship(Map<String, dynamic> internship) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final internshipId = internship['id'] as String?;
    if (uid == null || internshipId == null || internshipId.isEmpty) return;
    if (_savingInternshipIds.contains(internshipId)) return;

    final shouldSave = !_savedInternshipIds.contains(internshipId);

    setState(() {
      _savingInternshipIds.add(internshipId);
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'savedInternships': shouldSave
            ? FieldValue.arrayUnion([internshipId])
            : FieldValue.arrayRemove([internshipId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        if (shouldSave) {
          _savedInternshipIds.add(internshipId);
        } else {
          _savedInternshipIds.remove(internshipId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shouldSave
                ? 'Job saved to your list.'
                : 'Job removed from saved list.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update saved jobs: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingInternshipIds.remove(internshipId);
        });
      }
    }
  }

  Future<void> _openInternshipDetails(Map<String, dynamic> internship) async {
    final tags =
        ((internship['tags'] as List?) ?? []).map((e) => '$e').toList();
    final aboutRole = (internship['aboutRole'] as String? ?? '').trim();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                internship['title'] as String? ?? 'Internship',
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${internship['company'] ?? ''} • ${internship['mode'] ?? ''}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                'Salary: ${internship['salary'] ?? 'Negotiable'}',
                style: const TextStyle(
                    color: AppTheme.success, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                (internship['description'] as String?)?.trim().isNotEmpty ==
                        true
                    ? internship['description'] as String
                    : 'No additional description provided.',
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              if (aboutRole.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('About the Role',
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  aboutRole,
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
              const SizedBox(height: 14),
              const Text('Required Skills',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (tags.isEmpty)
                const Text('No skills listed yet.',
                    style: TextStyle(color: Colors.black45))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(tag,
                              style: const TextStyle(
                                  color: Color(0xFF1565C0), fontSize: 12)),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _applyForInternship(internship);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Apply Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchInternshipsForIndustry(
    String studentIndustry,
    List<String> studentSkills,
  ) async {
    final query = await FirebaseFirestore.instance
        .collection('internships')
        .where('active', isEqualTo: true)
        .limit(60)
        .get();

    final normalizedStudentIndustry = _normalizeIndustry(studentIndustry);
    final mapped = query.docs.map((doc) {
      final data = doc.data();
      final company = (data['company'] as String?) ?? 'Company';
      final title = (data['title'] as String?) ?? 'Internship';
      final mode = (data['type'] as String?) ??
          (data['location'] as String?) ??
          'Remote';
      final salary = (data['salary'] as String?) ??
          (data['stipend'] as String?) ??
          'Negotiable';
      final tags = ((data['skills'] as List?) ?? []).map((e) => '$e').toList();
      return {
        'id': doc.id,
        'company': company,
        'companyId': (data['companyId'] as String?) ?? '',
        'logo': company.isEmpty ? 'C' : company.substring(0, 1).toUpperCase(),
        'title': title,
        'mode': mode,
        'salary': salary,
        'description': (data['description'] as String?) ?? '',
        'aboutRole': (data['aboutRole'] as String?) ?? '',
        'tags': tags,
        'industry': (data['industry'] as String?) ?? '',
        'match': _calculateMatch(tags, studentSkills),
      };
    }).toList();

    final matching = mapped.where((item) {
      if (normalizedStudentIndustry.isEmpty) return true;
      final internshipIndustry =
          _normalizeIndustry(item['industry'] as String?);
      return internshipIndustry.isEmpty ||
          internshipIndustry == normalizedStudentIndustry;
    }).toList();

    matching.sort((a, b) => (b['match'] as int).compareTo(a['match'] as int));
    return matching;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _internships = [];
        });
      }
      return;
    }

    final data = await FirestoreService.getUserProfile(uid);
    final studentIndustry =
        (data?['industry'] as String?) ?? (data?['field'] as String?) ?? '';
    final studentSkills =
        ((data?['skills'] as List?) ?? []).map((e) => '$e').toList();
    final savedInternships = ((data?['savedInternships'] as List?) ?? const [])
        .map((e) => '$e')
        .where((item) => item.trim().isNotEmpty)
        .toSet();
    final internships =
        await _fetchInternshipsForIndustry(studentIndustry, studentSkills);

    if (!mounted) return;
    setState(() {
      _profile = data;
      _savedInternshipIds
        ..clear()
        ..addAll(savedInternships);
      _internships = internships;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)));
    }

    final name = (_profile?['name'] as String?) ??
        (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'User');
    final field = ((_profile?['industry'] ?? _profile?['field']) as String?) ??
        'IT & Software';
    final topMatch = _internships.isNotEmpty ? _internships.first : null;

    return RefreshIndicator(
      color: const Color(0xFF1565C0),
      onRefresh: _loadProfile,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 18, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF5F7FA), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$field ',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                      const Spacer(),
                      _iconBtn(
                        Icons.person_outline_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('recipientId',
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser?.uid ??
                                        '')
                            .limit(200)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final unread =
                              (snapshot.data?.docs ?? []).where((doc) {
                            final data = doc.data();
                            return data['read'] != true;
                          }).length;
                          return _iconBtn(
                            Icons.notifications_none_rounded,
                            badgeCount: unread,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationsCenterScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 48 / 2,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: topMatch == null
                        ? const Text(
                            'No internships found for your selected industry yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('TOP MATCH',
                                        style: TextStyle(
                                            color: AppTheme.primaryLight,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2)),
                                    const SizedBox(height: 12),
                                    Text(topMatch['title'] as String,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20 / 2 * 1.8,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    Text(topMatch['company'] as String,
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 18)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${topMatch['mode']}  ${topMatch['salary']}',
                                      style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () =>
                                          _openInternshipDetails(topMatch),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1565C0),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Text('View Details',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CircularPercentIndicator(
                                radius: 100 / 2,
                                lineWidth: 8,
                                percent: ((topMatch['match'] as int) / 100)
                                    .clamp(0.0, 1.0),
                                progressColor: AppTheme.success,
                                backgroundColor: Colors.white12,
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${topMatch['match']}%',
                                        style: const TextStyle(
                                            color: AppTheme.success,
                                            fontSize: 48 / 2,
                                            fontWeight: FontWeight.w700)),
                                    const Text('Match',
                                        style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ).animate().fade(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 44 / 2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon: Icons.map_outlined,
                          title: 'Roadmap',
                          subtitle: 'Career path',
                          border: const Color(0xFF402E8F),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RoadmapScreen(field: field),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionCard(
                          icon: Icons.trending_up,
                          title: 'Trends',
                          subtitle: 'Industry data',
                          border: const Color(0xFF275CBB),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  IndustryForecastScreen(field: field),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Text('Open Internships',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 44 / 2,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${_internships.length} found',
                          style: const TextStyle(
                              color: AppTheme.primaryLight, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 260,
              child: _internships.isEmpty
                  ? const Center(
                      child: Text(
                        'No internships for your industry yet',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) => _internshipCard(_internships[i]),
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemCount: _internships.length,
                    ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _iconBtn(
    IconData icon, {
    VoidCallback? onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A42),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF333369)),
            ),
            child: Icon(icon, color: AppTheme.textSecondary),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF121230)),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 166,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF17173B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border.withOpacity(0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryLight, size: 24),
            const SizedBox(height: 16),
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _internshipCard(Map<String, dynamic> item) {
    final tags = (item['tags'] as List<dynamic>).cast<String>();
    final aboutRole = (item['aboutRole'] as String? ?? '').trim();
    return GestureDetector(
      onTap: () => _openInternshipDetails(item),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A42),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF313173)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(item['logo'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['company'],
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 16)),
                    Text(item['mode'],
                        style: const TextStyle(
                            color: AppTheme.primaryLight, fontSize: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(item['title'],
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 35 / 2)),
            if (aboutRole.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                aboutRole,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
            const Spacer(),
            Text(item['salary'],
                style: const TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 20 / 2 * 1.8)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF23235A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 13)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InternshipsTab extends StatefulWidget {
  const _InternshipsTab();

  @override
  State<_InternshipsTab> createState() => _InternshipsTabState();
}

class _InternshipsTabState extends State<_InternshipsTab> {
  Map<String, dynamic>? _profile;
  bool _loadingProfile = true;
  int _selectedFilterIndex = 0;
  final Set<String> _savedInternshipIds = {};
  final Set<String> _savingInternshipIds = {};

  String _normalizeIndustry(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  String _normalizeMode(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw.contains('remote')) return 'remote';
    if (raw.contains('on-site') || raw.contains('onsite')) return 'onsite';
    if (raw.contains('hybrid')) return 'hybrid';
    return raw;
  }

  Future<void> _notifyCompanyOnApplication(
    Map<String, dynamic> internship,
  ) async {
    final companyId = (internship['companyId'] as String? ?? '').trim();
    final studentUid = FirebaseAuth.instance.currentUser?.uid;
    if (companyId.isEmpty || studentUid == null) return;

    final companyDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();
    final companyData = companyDoc.data() ?? <String, dynamic>{};
    if (companyData['notifyNewApplications'] == false) {
      return;
    }

    final studentName =
        (_profile?['name'] as String?)?.trim().isNotEmpty == true
            ? (_profile?['name'] as String)
            : (FirebaseAuth.instance.currentUser?.displayName ?? 'A student');
    final title = (internship['title'] as String?)?.trim().isNotEmpty == true
        ? internship['title'] as String
        : 'your internship';

    await NotificationService.instance.createInAppNotification(
      recipientId: companyId,
      senderId: studentUid,
      type: 'application_submitted',
      title: 'New internship application',
      body: '$studentName applied for $title.',
      data: {
        'internshipId': internship['id'] ?? '',
        'companyId': companyId,
        'studentId': studentUid,
      },
    );
  }

  Future<void> _notifyApplicantOnApplication(
    Map<String, dynamic> internship,
  ) async {
    final studentUid = FirebaseAuth.instance.currentUser?.uid;
    if (studentUid == null) return;

    final title = (internship['title'] as String?)?.trim().isNotEmpty == true
        ? internship['title'] as String
        : 'this internship';
    final company =
        (internship['company'] as String?)?.trim().isNotEmpty == true
            ? internship['company'] as String
            : 'the company';

    await NotificationService.instance.createInAppNotification(
      recipientId: studentUid,
      senderId: internship['companyId'] as String?,
      type: 'application_confirmation',
      title: 'Application submitted',
      body: 'You applied for $title at $company.',
      data: {
        'internshipId': internship['id'] ?? '',
        'companyId': internship['companyId'] ?? '',
      },
    );
  }

  Future<void> _applyForInternship(Map<String, dynamic> internship) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final internshipId = internship['id'] as String?;
    if (internshipId == null || internshipId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to apply for this internship right now.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    final existing = await FirebaseFirestore.instance
        .collection('applications')
        .where('studentId', isEqualTo: uid)
        .where('internshipId', isEqualTo: internshipId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have already applied for this internship.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    await FirebaseFirestore.instance.collection('applications').add({
      'studentId': uid,
      'studentName': _profile?['name'] ??
          FirebaseAuth.instance.currentUser?.displayName ??
          '',
      'studentEmail':
          _profile?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '',
      'internshipId': internshipId,
      'companyId': internship['companyId'],
      'title': internship['title'],
      'company': internship['company'],
      'industry': internship['industry'],
      'status': 'applied',
      'appliedAt': FieldValue.serverTimestamp(),
    });

    await _notifyApplicantOnApplication(internship);
    await _notifyCompanyOnApplication(internship);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Application submitted successfully.'),
      backgroundColor: AppTheme.success,
    ));
  }

  Future<void> _toggleSavedInternship(Map<String, dynamic> internship) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final internshipId = internship['id'] as String?;
    if (uid == null || internshipId == null || internshipId.isEmpty) return;
    if (_savingInternshipIds.contains(internshipId)) return;

    final shouldSave = !_savedInternshipIds.contains(internshipId);

    setState(() {
      _savingInternshipIds.add(internshipId);
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'savedInternships': shouldSave
            ? FieldValue.arrayUnion([internshipId])
            : FieldValue.arrayRemove([internshipId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        if (shouldSave) {
          _savedInternshipIds.add(internshipId);
        } else {
          _savedInternshipIds.remove(internshipId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shouldSave
                ? 'Job saved to your list.'
                : 'Job removed from saved list.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update saved jobs: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingInternshipIds.remove(internshipId);
        });
      }
    }
  }

  Future<void> _showInternshipDetails(Map<String, dynamic> internship) async {
    final tags =
        ((internship['tags'] as List?) ?? []).map((e) => '$e').toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                internship['title'] as String? ?? 'Internship',
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${internship['company'] ?? ''} • ${internship['mode'] ?? ''}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                'Salary: ${internship['salary'] ?? 'Negotiable'}',
                style: const TextStyle(
                    color: AppTheme.success, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                (internship['description'] as String?)?.trim().isNotEmpty ==
                        true
                    ? internship['description'] as String
                    : 'No additional description provided.',
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              if ((internship['aboutRole'] as String?)?.trim().isNotEmpty ==
                  true) ...[
                const SizedBox(height: 12),
                const Text('About the Role',
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  (internship['aboutRole'] as String).trim(),
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
              const SizedBox(height: 14),
              const Text('Required Skills',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (tags.isEmpty)
                const Text('No skills listed yet.',
                    style: TextStyle(color: Colors.black45))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(tag,
                              style: const TextStyle(
                                  color: Color(0xFF1565C0), fontSize: 12)),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _applyForInternship(internship);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Apply Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }

    final profile = await FirestoreService.getUserProfile(uid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _savedInternshipIds
        ..clear()
        ..addAll(((profile?['savedInternships'] as List?) ?? const [])
            .map((e) => '$e')
            .where((item) => item.trim().isNotEmpty));
      _loadingProfile = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryLight),
      );
    }

    const filters = ['Industry Match', 'All', 'Remote', 'Onsite', 'Hybrid'];
    final studentIndustry =
        ((_profile?['industry'] ?? _profile?['field']) as String?) ?? '';
    final normalizedStudentIndustry = _normalizeIndustry(studentIndustry);

    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('internships')
            .where('active', isEqualTo: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final internships = docs.map((doc) {
            final data = doc.data();
            final company = (data['company'] as String?) ?? 'Company';
            return {
              'id': doc.id,
              'companyId': (data['companyId'] as String?) ?? '',
              'logo':
                  company.isEmpty ? 'C' : company.substring(0, 1).toUpperCase(),
              'company': company,
              'location': (data['location'] as String?) ?? 'Remote',
              'title': (data['title'] as String?) ?? 'Internship',
              'mode': (data['type'] as String?) ??
                  (data['location'] as String?) ??
                  'Remote',
              'duration': (data['duration'] as String?) ?? '3 months',
              'salary': (data['salary'] as String?) ??
                  (data['stipend'] as String?) ??
                  'Negotiable',
              'description': (data['description'] as String?) ?? '',
              'aboutRole': (data['aboutRole'] as String?) ?? '',
              'tags':
                  ((data['skills'] as List?) ?? []).map((e) => '$e').toList(),
              'industry': (data['industry'] as String?) ?? '',
            };
          }).toList();

          final matchingInternships = internships.where((item) {
            if (normalizedStudentIndustry.isEmpty) return true;
            final internshipIndustry =
                _normalizeIndustry(item['industry'] as String?);
            return internshipIndustry.isEmpty ||
                internshipIndustry == normalizedStudentIndustry;
          }).toList();

          List<Map<String, dynamic>> filteredInternships;
          switch (_selectedFilterIndex) {
            case 0:
              filteredInternships = matchingInternships;
              break;
            case 1:
              filteredInternships = internships;
              break;
            case 2:
              filteredInternships = internships
                  .where((item) =>
                      _normalizeMode(item['mode'] as String?) == 'remote')
                  .toList();
              break;
            case 3:
              filteredInternships = internships
                  .where((item) =>
                      _normalizeMode(item['mode'] as String?) == 'onsite')
                  .toList();
              break;
            case 4:
              filteredInternships = internships
                  .where((item) =>
                      _normalizeMode(item['mode'] as String?) == 'hybrid')
                  .toList();
              break;
            default:
              filteredInternships = matchingInternships;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Browse Jobs',
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 34,
                            fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SavedJobsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.bookmark_outline_rounded),
                    tooltip: 'Saved jobs',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${filteredInternships.length} opportunities found',
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: studentIndustry.isEmpty
                      ? 'Set your industry in Profile for better matches'
                      : 'Showing internships for $studentIndustry',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon:
                      const Icon(Icons.filter_alt_outlined, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final selected = index == _selectedFilterIndex;
                    final label = filters[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilterIndex = index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              selected ? const Color(0xFFE8F0FF) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF1565C0)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF1565C0)
                                  : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: filters.length,
                ),
              ),
              const SizedBox(height: 20),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryLight),
                  ),
                )
              else if (filteredInternships.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    _selectedFilterIndex == 0
                        ? (studentIndustry.isEmpty
                            ? 'No internships available right now.'
                            : 'No internships found for $studentIndustry yet.')
                        : 'No internships found for ${filters[_selectedFilterIndex]} filter.',
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                )
              else
                ...filteredInternships.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => _showInternshipDetails(item),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item['logo'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['company'] as String,
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 18),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['location'] as String,
                                          style: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success
                                              .withValues(alpha: 0.18),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          item['salary'] as String,
                                          style: const TextStyle(
                                            color: AppTheme.success,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _savingInternshipIds
                                                .contains(item['id'] as String)
                                            ? null
                                            : () =>
                                                _toggleSavedInternship(item),
                                        icon: _savingInternshipIds
                                                .contains(item['id'] as String)
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Icon(
                                                _savedInternshipIds.contains(
                                                        item['id'] as String)
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_outline,
                                                color: _savedInternshipIds
                                                        .contains(item['id']
                                                            as String)
                                                    ? Colors.orange
                                                    : AppTheme.textMuted,
                                              ),
                                        tooltip: _savedInternshipIds
                                                .contains(item['id'] as String)
                                            ? 'Remove saved job'
                                            : 'Save job',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if ((item['aboutRole'] as String?)
                                      ?.trim()
                                      .isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 8),
                                Text(
                                  (item['aboutRole'] as String).trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _pill(
                                    item['mode'] as String,
                                    const Color(0xFF204C92),
                                    const Color(0xFF4EA0FF),
                                  ),
                                  _pill(
                                    item['duration'] as String,
                                    const Color(0xFF41256E),
                                    AppTheme.primaryLight,
                                  ),
                                  ...(item['tags'] as List<String>).map(
                                    (tag) => _pill(
                                      tag,
                                      const Color(0xFF23235A),
                                      AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: text.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MyCvTab extends StatefulWidget {
  const _MyCvTab();

  @override
  State<_MyCvTab> createState() => _MyCvTabState();
}

class _MyCvTabState extends State<_MyCvTab> {
  String? _fileName;
  String? _cvStoragePath;
  String? _cvStorageUrl;
  bool _uploadingCv = false;
  bool _loadingCv = true;
  bool _savingManual = false;
  final _ageCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  Map<String, dynamic> _cvData = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadCvData();
  }

  Future<void> _loadCvData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => _loadingCv = false);
      }
      return;
    }

    final profile = await FirestoreService.getUserProfile(uid);
    if (!mounted) return;

    setState(() {
      _fileName = profile?['cvFileName'] as String?;
      _cvStoragePath = profile?['cvStoragePath'] as String?;
      _cvStorageUrl = profile?['cvStorageSignedUrl'] as String?;
      _ageCtrl.text = (profile?['age']?.toString() ?? '').trim();
      _experienceCtrl.text = ((profile?['experience'] as String?) ??
              (profile?['cvExperience'] as String?) ??
              '')
          .trim();
      _cvData = {
        'detected_skills':
            ((profile?['cvSkills'] as List?) ?? []).map((e) => '$e').toList(),
        'experience': (profile?['cvExperience'] as String?) ?? '',
        'summary': (profile?['cvSummary'] as String?) ?? '',
        'recommendations': ((profile?['cvRecommendations'] as List?) ?? [])
            .map((e) => '$e')
            .toList(),
      };
      _loadingCv = false;
    });
  }

  Future<void> _pickCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to read this file. Try a PDF or TXT CV.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    setState(() => _uploadingCv = true);

    final storageUpload = await AiService.uploadCvToStorage(
      bytes: bytes,
      fileName: file.name,
      userId: uid,
    );

    final hasStorageError = storageUpload.containsKey('_error');
    final storageError = (storageUpload['_error'] as String?) ?? '';
    if (hasStorageError) {
      if (!mounted) return;
      setState(() => _uploadingCv = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          storageError.isNotEmpty
              ? 'CV upload failed: $storageError'
              : 'CV upload failed. Please try again.',
        ),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    final analysis = await AiService.analyzeCv(
      bytes: bytes,
      fileName: file.name,
    );

    final hasAnalysisError = analysis.containsKey('_error');
    final analysisError = (analysis['_error'] as String?) ?? '';

    final detectedSkills = ((analysis['detected_skills'] as List?) ?? [])
        .map((e) => '$e')
        .toList();
    final recommendations = ((analysis['recommendations'] as List?) ?? [])
        .map((e) => '$e')
        .toList();

    final profile = await FirestoreService.getUserProfile(uid);
    final existingSkills =
        ((profile?['skills'] as List?) ?? []).map((e) => '$e').toList();
    final mergedSkills = <String>{
      ...existingSkills,
      ...detectedSkills,
    }.toList();

    await FirestoreService.updateUserProfile(uid, {
      'cvFileName': file.name,
      'cvStorageBucket': storageUpload['bucket'] as String?,
      'cvStoragePath': storageUpload['path'] as String?,
      'cvStorageSignedUrl': storageUpload['signed_url'] as String?,
      'cvAnalyzed': analysis.isNotEmpty && !hasAnalysisError,
      'cvSkills': detectedSkills,
      'cvExperience': (analysis['experience'] as String?) ?? '',
      'cvSummary': (analysis['summary'] as String?) ?? '',
      'cvRecommendations': recommendations,
      'cvAnalyzeError': analysisError,
      'cvUploadedAt': FieldValue.serverTimestamp(),
      'skills': mergedSkills,
      if ((analysis['experience'] as String?)?.trim().isNotEmpty == true)
        'experience': analysis['experience'],
    });

    if (!mounted) return;
    setState(() {
      _fileName = file.name;
      _cvStoragePath = storageUpload['path'] as String?;
      _cvStorageUrl = storageUpload['signed_url'] as String?;
      _cvData = analysis;
      if ((analysis['experience'] as String?)?.trim().isNotEmpty == true &&
          (analysis['experience'] as String).toLowerCase() != 'unknown') {
        _experienceCtrl.text = (analysis['experience'] as String).trim();
      }
      _uploadingCv = false;
    });

    final analyzed = analysis.isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(!hasAnalysisError && analyzed
          ? 'CV uploaded and saved. AI extracted details updated.'
          : (analysisError.isNotEmpty
              ? 'CV uploaded, but analysis failed: $analysisError'
              : 'CV uploaded and saved. AI extraction was not available for this file.')),
      backgroundColor:
          (!hasAnalysisError && analyzed) ? AppTheme.success : AppTheme.warning,
    ));
  }

  Future<void> _saveManualDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ageText = _ageCtrl.text.trim();
    final experienceText = _experienceCtrl.text.trim();
    final parsedAge = int.tryParse(ageText);

    if (ageText.isNotEmpty &&
        (parsedAge == null || parsedAge < 15 || parsedAge > 80)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid age between 15 and 80.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    setState(() => _savingManual = true);
    await FirestoreService.updateUserProfile(uid, {
      'age': parsedAge,
      'experience': experienceText,
      if (experienceText.isNotEmpty) 'cvExperience': experienceText,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => _savingManual = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Manual details saved successfully.'),
      backgroundColor: AppTheme.success,
    ));
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detectedSkills =
        ((_cvData['detected_skills'] as List?) ?? []).map((e) => '$e').toList();
    final recommendations =
        ((_cvData['recommendations'] as List?) ?? []).map((e) => '$e').toList();
    final summary = (_cvData['summary'] as String?) ?? '';
    final experience = (_cvData['experience'] as String?) ?? '';
    final hasDetectedExperience =
        experience.trim().isNotEmpty && experience.toLowerCase() != 'unknown';

    if (_loadingCv) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryLight),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Upload CV',
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 48 / 2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
              'Upload your resume - our AI will extract your skills and match you with internships.',
              style: TextStyle(color: Colors.black54, fontSize: 16)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFF121236),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF3A34B8), width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Color(0xFF24245C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload_file_rounded,
                      color: AppTheme.primaryLight, size: 58),
                ),
                const SizedBox(height: 22),
                Text(
                  _fileName == null ? 'Tap to choose your CV' : _fileName!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text('Supported: PDF, TXT, DOCX (Max 10MB)',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                if ((_cvStoragePath ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Stored in Supabase: ${_cvStoragePath!}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if ((_cvStorageUrl ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Signed access URL generated (7 days)',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _uploadingCv ? null : _pickCv,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.35),
                          blurRadius: 18,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _uploadingCv
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('+ Upload PDF / TXT / DOCX',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF18183C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2D2D5E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Manual Student Details',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                    hintText: 'Enter your age',
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _experienceCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: hasDetectedExperience
                        ? 'Experience (editable)'
                        : 'Experience (manual entry)',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    hintText: 'e.g. 2 years mobile development',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _savingManual ? null : _saveManualDetails,
                    icon: _savingManual
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Manual Details'),
                  ),
                ),
              ],
            ),
          ),
          if (summary.trim().isNotEmpty ||
              experience.trim().isNotEmpty ||
              detectedSkills.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF18183C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D2D5E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI CV Insights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (experience.trim().isNotEmpty)
                    Text('Experience: $experience',
                        style: const TextStyle(color: AppTheme.textSecondary)),
                  if (summary.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(summary,
                        style: const TextStyle(color: AppTheme.textMuted)),
                  ],
                  if (detectedSkills.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: detectedSkills
                          .map((skill) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF23235A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(skill,
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12)),
                              ))
                          .toList(),
                    ),
                  ],
                  if (recommendations.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...recommendations.take(3).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $item',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 12)),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppliedTab extends StatefulWidget {
  const _AppliedTab();

  @override
  State<_AppliedTab> createState() => _AppliedTabState();
}

class _AppliedTabState extends State<_AppliedTab> {
  String _normalizeIndustry(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

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

  Timestamp? _getInterviewTimestamp(Map<String, dynamic> data) {
    final direct = data['interviewDate'];
    if (direct is Timestamp) return direct;
    final legacy = data['interviewAt'];
    if (legacy is Timestamp) return legacy;
    return null;
  }

  bool _isInPersonInterview(String type) {
    final normalized = type.trim().toLowerCase();
    return normalized == 'physical' ||
        normalized == 'inperson' ||
        normalized == 'in_person' ||
        normalized == 'onsite';
  }

  String _formatAppliedDate(Timestamp? ts) {
    if (ts == null) return 'Recently applied';
    final date = ts.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(Timestamp? ts) {
    if (ts == null) return 'Not set';
    final dt = ts.toDate();
    final date =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString();
    final minute = dt.minute.toString().padLeft(2, '0');
    final meridiem = dt.hour >= 12 ? 'PM' : 'AM';
    return '$date $hour:$minute $meridiem';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      case 'interview_scheduled':
        return AppTheme.primaryLight;
      default:
        return AppTheme.warning;
    }
  }

  Future<void> _notifyCompanyOnApplication({
    required Map<String, dynamic> internship,
    required String studentUid,
    required String studentName,
  }) async {
    final companyId = (internship['companyId'] as String? ?? '').trim();
    if (companyId.isEmpty) return;

    final companyDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();
    final companyData = companyDoc.data() ?? <String, dynamic>{};
    if (companyData['notifyNewApplications'] == false) {
      return;
    }

    final title = (internship['title'] as String?)?.trim().isNotEmpty == true
        ? internship['title'] as String
        : 'your internship';

    await NotificationService.instance.createInAppNotification(
      recipientId: companyId,
      senderId: studentUid,
      type: 'application_submitted',
      title: 'New internship application',
      body: '$studentName applied for $title.',
      data: {
        'internshipId': internship['id'] ?? '',
        'companyId': companyId,
        'studentId': studentUid,
      },
    );
  }

  Future<void> _notifyApplicantOnApplication({
    required Map<String, dynamic> internship,
    required String studentUid,
  }) async {
    final title = (internship['title'] as String?)?.trim().isNotEmpty == true
        ? internship['title'] as String
        : 'this internship';
    final company =
        (internship['company'] as String?)?.trim().isNotEmpty == true
            ? internship['company'] as String
            : 'the company';

    await NotificationService.instance.createInAppNotification(
      recipientId: studentUid,
      senderId: internship['companyId'] as String?,
      type: 'application_confirmation',
      title: 'Application submitted',
      body: 'You applied for $title at $company.',
      data: {
        'internshipId': internship['id'] ?? '',
        'companyId': internship['companyId'] ?? '',
      },
    );
  }

  Future<void> _applyForInternship(Map<String, dynamic> internship) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final internshipId = (internship['id'] as String?)?.trim() ?? '';
    if (internshipId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to apply for this internship right now.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    final existing = await FirebaseFirestore.instance
        .collection('applications')
        .where('studentId', isEqualTo: uid)
        .where('internshipId', isEqualTo: internshipId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have already applied for this internship.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final studentName = (userData['name'] as String?)?.trim().isNotEmpty == true
        ? userData['name'] as String
        : (FirebaseAuth.instance.currentUser?.displayName ?? 'Student');
    final studentEmail =
        (userData['email'] as String?)?.trim().isNotEmpty == true
            ? userData['email'] as String
            : (FirebaseAuth.instance.currentUser?.email ?? '');

    await FirebaseFirestore.instance.collection('applications').add({
      'studentId': uid,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'internshipId': internshipId,
      'companyId': internship['companyId'],
      'title': internship['title'],
      'company': internship['company'],
      'industry': internship['industry'],
      'status': 'applied',
      'appliedAt': FieldValue.serverTimestamp(),
    });

    await _notifyApplicantOnApplication(
      internship: internship,
      studentUid: uid,
    );
    await _notifyCompanyOnApplication(
      internship: internship,
      studentUid: uid,
      studentName: studentName,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Application submitted successfully.'),
      backgroundColor: AppTheme.success,
    ));
  }

  Future<void> _showInternshipDetails(Map<String, dynamic> internship) async {
    final tags =
        ((internship['tags'] as List?) ?? []).map((e) => '$e').toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                internship['title'] as String? ?? 'Internship',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${internship['company'] ?? ''} • ${internship['location'] ?? internship['mode'] ?? ''}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                'Salary: ${internship['salary'] ?? 'Negotiable'}',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (internship['description'] as String?)?.trim().isNotEmpty ==
                        true
                    ? internship['description'] as String
                    : ((internship['aboutRole'] as String?)
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? internship['aboutRole'] as String
                        : 'No additional description provided.'),
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'Required Skills',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (tags.isEmpty)
                const Text(
                  'No skills listed yet.',
                  style: TextStyle(color: Colors.black45),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _applyForInternship(internship);
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Apply Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInterviewLink(String rawLink) async {
    var link = rawLink.trim();
    if (link.isEmpty) return;

    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid interview link.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    final canOpen = await canLaunchUrl(uri);
    if (!canOpen) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to open interview link.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _deleteApplication(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Application',
            style: TextStyle(color: Colors.black87)),
        content: const Text(
          'Are you sure you want to remove this application?',
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await doc.reference.delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Application deleted.'),
      backgroundColor: AppTheme.warning,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(
        child: Text('Please login again.',
            style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, profileSnapshot) {
          final profile =
              profileSnapshot.data?.data() ?? const <String, dynamic>{};
          final studentSkills = ((profile['skills'] as List?) ?? const [])
              .map((e) => '$e')
              .where((e) => e.trim().isNotEmpty)
              .toList();
          final studentIndustry = _normalizeIndustry(
            (profile['industry'] ?? profile['field']) as String?,
          );

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .where('studentId', isEqualTo: uid)
                .limit(200)
                .snapshots(),
            builder: (context, applicationsSnapshot) {
              var docs = applicationsSnapshot.data?.docs ?? [];
              docs.sort((a, b) {
                final at = a.data()['appliedAt'] as Timestamp?;
                final bt = b.data()['appliedAt'] as Timestamp?;
                final aMs = at?.millisecondsSinceEpoch ?? 0;
                final bMs = bt?.millisecondsSinceEpoch ?? 0;
                return bMs.compareTo(aMs);
              });

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('internships')
                    .where('active', isEqualTo: true)
                    .limit(200)
                    .snapshots(),
                builder: (context, internshipsSnapshot) {
                  final internships = internshipsSnapshot.data?.docs ?? [];
                  final suggestedJobs = internships.map((doc) {
                    final data = doc.data();
                    final skills = ((data['skills'] as List?) ?? const [])
                        .map((e) => '$e')
                        .where((e) => e.trim().isNotEmpty)
                        .toList();
                    final industry =
                        _normalizeIndustry((data['industry'] as String?));
                    final match = _calculateMatch(skills, studentSkills);
                    return {
                      'id': doc.id,
                      'companyId': (data['companyId'] as String?) ?? '',
                      'title': (data['title'] as String?) ?? 'Internship',
                      'company': (data['company'] as String?) ?? 'Company',
                      'location': ((data['type'] as String?) ??
                              (data['location'] as String?) ??
                              'Remote')
                          .trim(),
                      'mode': ((data['type'] as String?) ??
                              (data['location'] as String?) ??
                              'Remote')
                          .trim(),
                      'salary': (data['salary'] as String?) ??
                          (data['stipend'] as String?) ??
                          'Negotiable',
                      'description':
                          ((data['description'] as String?) ?? '').trim(),
                      'tags': skills,
                      'aboutRole':
                          ((data['aboutRole'] as String?) ?? '').trim(),
                      'industry': industry,
                      'match': match,
                    };
                  }).where((item) {
                    if (studentIndustry.isEmpty) return true;
                    final jobIndustry = item['industry'] as String?;
                    return jobIndustry == null ||
                        jobIndustry.isEmpty ||
                        jobIndustry == studentIndustry;
                  }).toList();

                  suggestedJobs.sort((a, b) =>
                      (b['match'] as int).compareTo(a['match'] as int));

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Applications',
                                style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Track your submitted applications (${docs.length})',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 24),
                      if (applicationsSnapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryLight),
                        )
                      else if (docs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.inbox_rounded,
                                  color: Colors.grey, size: 44),
                              SizedBox(height: 12),
                              Text('No applications yet',
                                  style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 6),
                              Text(
                                  'Apply to internships from the Browse Jobs tab.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 15)),
                            ],
                          ),
                        )
                      else
                        ...docs.map((doc) {
                          final data = doc.data();
                          final status =
                              (data['status'] as String?) ?? 'applied';
                          final interviewType =
                              (data['interviewType'] as String?) ?? '';
                          final interviewAt = _getInterviewTimestamp(data);
                          final interviewLink =
                              (data['interviewLink'] as String?) ?? '';
                          final interviewLocation =
                              (data['interviewLocation'] as String?) ?? '';
                          final interviewToken =
                              (data['interviewToken'] as String?) ?? '';
                          final statusColor = _statusColor(status);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['title'] as String? ??
                                            'Internship',
                                        style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data['company'] as String? ?? 'Company',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Applied: ${_formatAppliedDate(data['appliedAt'] as Timestamp?)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                if (status == 'interview_scheduled') ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Interview (${interviewType.toUpperCase()}): ${_formatDateTime(interviewAt)}',
                                    style: const TextStyle(
                                        color: Color(0xFF1565C0)),
                                  ),
                                  if (interviewType == 'online' &&
                                      interviewLink.isNotEmpty)
                                    GestureDetector(
                                      onTap: () =>
                                          _openInterviewLink(interviewLink),
                                      child: Text('Link: $interviewLink',
                                          style: const TextStyle(
                                              color: Color(0xFF1565C0),
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  Color(0xFF1565C0))),
                                    ),
                                  if (_isInPersonInterview(interviewType) &&
                                      interviewLocation.isNotEmpty)
                                    Text('Location: $interviewLocation',
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                  if (interviewToken.isNotEmpty)
                                    Text('Token: $interviewToken',
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                ],
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _deleteApplication(doc),
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppTheme.error, size: 18),
                                    label: const Text('Delete Application',
                                        style:
                                            TextStyle(color: AppTheme.error)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 28),
                      const Text(
                        'Suggested Jobs',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ranked by your profile skills and field.',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                      const SizedBox(height: 14),
                      if (internshipsSnapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryLight),
                        )
                      else if (suggestedJobs.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Text(
                            'No suggested jobs available right now.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      else
                        ...suggestedJobs.take(10).map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _showInternshipDetails(item),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['title'] as String,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1565C0)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${item['match']}% match',
                                              style: const TextStyle(
                                                color: Color(0xFF1565C0),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${item['company']} • ${item['location']}',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        (item['aboutRole'] as String).isEmpty
                                            ? 'No additional description provided.'
                                            : item['aboutRole'] as String,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _showInternshipDetails(item),
                                          icon: const Icon(Icons.visibility),
                                          label: const Text('View & Apply'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ================== INDUSTRY FORECAST SCREEN ==================

class IndustryForecastScreen extends StatefulWidget {
  final String field;
  const IndustryForecastScreen({super.key, required this.field});

  @override
  State<IndustryForecastScreen> createState() => _IndustryForecastScreenState();
}

class _IndustryForecastScreenState extends State<IndustryForecastScreen> {
  bool _loading = true;
  Map<String, dynamic> _trends = const {};

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    final data = await AiService.generateIndustryTrends(widget.field);

    if (!mounted) return;

    setState(() {
      _trends = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final industry = (_trends['industry'] as String?) ?? widget.field;

    final overview = (_trends['overview'] as String?) ??
        'AI trend model indicates demand is increasing for practical, tool-based skills in IT & Software roles.';

    final trendItems = ((_trends['trends'] as List?) ?? [])
        .whereType<Map>()
        .map((item) => {
              'skill': (item['skill'] ?? 'Skill').toString(),
              'demandPct': int.tryParse('${item['demandPct']}') ?? 50,
              'yoy': (item['yoy'] ?? '+0% YoY').toString(),
              'direction': (item['direction'] ?? 'up').toString(),
            })
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('$industry Forecast'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 🔹 AI CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE3F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.trending_up, color: Color(0xFF3692FF)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Market Intelligence: $industry',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overview,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Forecasted Skills',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ...trendItems.map((item) {
                  final demand = item['demandPct'] as int;

                  final direction = item['direction'] as String;

                  final color = direction == 'down'
                      ? Colors.red
                      : direction == 'flat'
                          ? Colors.orange
                          : Colors.green;

                  final icon = direction == 'down'
                      ? Icons.trending_down
                      : direction == 'flat'
                          ? Icons.trending_flat
                          : Icons.trending_up;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),

                      // ✨ subtle futuristic touch
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          color.withOpacity(0.03),
                        ],
                      ),

                      border: Border.all(color: color.withOpacity(0.25)),

                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.12),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 🔹 icon
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 18),
                        ),

                        const SizedBox(width: 10),

                        // 🔹 skill
                        Expanded(
                          child: Text(
                            item['skill'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // 🔹 demand
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$demand%',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              item['yoy'] as String,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
