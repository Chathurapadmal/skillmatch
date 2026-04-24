import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../shared/chat_overlay.dart';
import '../../shared/notifications_center_screen.dart';
import '../../shared/supabase_storage_page.dart';
import '../../theme/app_theme.dart';
import '../../widgets/supabase_image_widget.dart';

class CompanyDashboard extends StatefulWidget {
  final UserModel user;

  const CompanyDashboard({super.key, required this.user});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  int _selectedIndex = 0;

  String get _companyId => widget.user.uid;

  String get _companyLabel {
    final fromModel = (widget.user.companyName ?? '').trim();
    if (fromModel.isNotEmpty) return fromModel;
    return widget.user.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _CompanyOverviewTab(
        companyId: _companyId,
        companyName: _companyLabel,
      ),
      _CandidateDiscoveryTab(
        companyId: _companyId,
        companyName: _companyLabel,
      ),
      _InternshipManagementTab(
        companyId: _companyId,
        companyName: _companyLabel,
      ),
      _TokenManagementTab(companyId: _companyId),
      _CompanySettingsTab(
        companyId: _companyId,
        initialCompanyName: _companyLabel,
        email: widget.user.email,
      ),
    ];

    return ChatOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            _selectedIndex == 0
                ? 'Company Workspace'
                : _selectedIndex == 1
                    ? 'Candidate Discovery'
                    : _selectedIndex == 2
                        ? 'Internship Posts'
                        : _selectedIndex == 3
                            ? 'Access Tokens'
                            : 'Company Settings',
            style: const TextStyle(
              color: Color(0xFF1E3A5F),
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipientId', isEqualTo: _companyId)
                  .where('read', isEqualTo: false)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                final unread = snapshot.data?.docs.length ?? 0;
                return IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsCenterScreen(),
                      ),
                    );
                  },
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded,
                          color: Color(0xFF1E3A5F)),
                      if (unread > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
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
              },
            ),
            PopupMenuButton<String>(
              icon: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1E3A5F),
                child: Icon(Icons.business, color: Colors.white, size: 18),
              ),
              onSelected: (value) async {
                if (value == 'privacy') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _PrivacyPolicyPage(),
                    ),
                  );
                  return;
                }
                if (value == 'security') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _SecurityPage(),
                    ),
                  );
                  return;
                }
                if (value == 'terms') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _TermsOfServicePage(),
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
                        _companyLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        widget.user.email,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Company Account',
                        style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'privacy',
                  child: Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined),
                      SizedBox(width: 8),
                      Text('Privacy Policy'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'security',
                  child: Row(
                    children: [
                      Icon(Icons.security_outlined),
                      SizedBox(width: 8),
                      Text('Security'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'terms',
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined),
                      SizedBox(width: 8),
                      Text('Terms of Service'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon:
                  Icon(Icons.dashboard_rounded, color: Color(0xFF1565C0)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon:
                  Icon(Icons.people_alt_rounded, color: Color(0xFF1565C0)),
              label: 'Candidates',
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon: Icon(Icons.work_rounded, color: Color(0xFF1565C0)),
              label: 'Posts',
            ),
            NavigationDestination(
              icon: Icon(Icons.key_outlined),
              selectedIcon: Icon(Icons.key, color: Color(0xFF1565C0)),
              label: 'Tokens',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon:
                  Icon(Icons.settings_rounded, color: Color(0xFF1565C0)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyOverviewTab extends StatelessWidget {
  final String companyId;
  final String companyName;

  const _CompanyOverviewTab({
    required this.companyId,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('internships')
          .where('companyId', isEqualTo: companyId)
          .limit(200)
          .snapshots(),
      builder: (context, internshipSnap) {
        final internships = internshipSnap.data?.docs ?? const [];
        final activePosts = internships.where((doc) {
          final data = doc.data();
          return data['active'] != false;
        }).length;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('applications')
              .where('companyId', isEqualTo: companyId)
              .limit(500)
              .snapshots(),
          builder: (context, appsSnap) {
            final applications = appsSnap.data?.docs ?? const [];
            final shortlisted = applications.where((doc) {
              final status =
                  (doc.data()['status'] as String? ?? '').toLowerCase();
              return status == 'approved' || status == 'interview_scheduled';
            }).length;

            final isLoading =
                internshipSnap.connectionState == ConnectionState.waiting ||
                    appsSnap.connectionState == ConnectionState.waiting;

            final topApplications = [...applications]..sort((a, b) {
                final at = a.data()['appliedAt'] as Timestamp?;
                final bt = b.data()['appliedAt'] as Timestamp?;
                return (bt?.millisecondsSinceEpoch ?? 0)
                    .compareTo(at?.millisecondsSinceEpoch ?? 0);
              });

            void openApplicantsDetails() {
              final items = topApplications.map((e) {
                final status =
                    (e.data()['status'] as String? ?? '').toUpperCase();
                return '${(e.data()['studentName'] as String? ?? 'Student')} • $status';
              }).toList();

              // ✅ SAME FIX as shortlisted
              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No applications received yet'),
                  ),
                );
                return;
              }

              _showMetricDetails(
                context,
                title: 'Applicants',
                items: items,
              );
            }

            void openShortlistedDetails() {
              final items = topApplications.where((e) {
                final status =
                    (e.data()['status'] as String? ?? '').toLowerCase();
                return status == 'approved' || status == 'interview_scheduled';
              }).map((e) {
                final status =
                    (e.data()['status'] as String? ?? '').toUpperCase();
                return '${(e.data()['studentName'] as String? ?? 'Student')} • $status';
              }).toList();

              // ✅ FIX: handle empty state properly
              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No shortlisted candidates yet'),
                  ),
                );
                return;
              }

              _showMetricDetails(
                context,
                title: 'Shortlisted Candidates',
                items: items,
              );
            }

            void openActivePostsDetails() {
              final items = internships
                  .where((e) => e.data()['active'] != false)
                  .map((e) =>
                      '${(e.data()['title'] as String? ?? 'Internship')} • ${(e.data()['type'] as String? ?? 'Mode')}')
                  .toList();

              // ✅ FIX (same as others)
              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No active posts yet'),
                  ),
                );
                return;
              }

              _showMetricDetails(
                context,
                title: 'Active Posts',
                items: items,
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                        'Welcome, $companyName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your recruitment overview is ready.\nTrack your applicants and manage\nyour workspace efficiency here.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Metrics Column
                _DashboardCard(
                  icon: Icons.person_search_outlined,
                  title: 'Applicants',
                  value: '${applications.length}',
                  subtitleText: '12% this week', // Placeholders based on design
                  subtitleIcon: Icons.trending_up,
                  subtitleColor: const Color(0xFF0D9488), // Teal success
                  onTap: openApplicantsDetails,
                ),
                _DashboardCard(
                  icon: Icons.star_rounded,
                  title: 'Shortlisted',
                  value: '$shortlisted',
                  subtitleText: '8 ready for interview',
                  subtitleIcon: Icons.check_circle,
                  subtitleColor: const Color(0xFF0D9488),
                  onTap: openShortlistedDetails,
                ),
                _DashboardCard(
                  icon: Icons.work,
                  title: 'Active Posts',
                  value: '$activePosts',
                  subtitleText: '3 closing soon',
                  subtitleIcon: Icons.access_time_filled,
                  subtitleColor: const Color(0xFF94A3B8), // Slate grey
                  onTap: openActivePostsDetails,
                ),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Top-Matched Candidate Workflow',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0F4C81),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                else if (topApplications.isEmpty)
                  const _DashboardEmptyState()
                else
                  ...topApplications.take(5).map((doc) {
                    final data = doc.data();
                    final status =
                        (data['status'] as String? ?? 'applied').toLowerCase();
                    return _buildApplicantTile(data, status);
                  }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildApplicantTile(Map<String, dynamic> data, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE3F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['studentName'] as String?)?.trim().isNotEmpty == true
                      ? data['studentName'] as String
                      : 'Student Candidate',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (data['title'] as String?) ?? 'Internship role',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: _statusColor(status),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      case 'interview_scheduled':
        return const Color(0xFF1E88E5);
      default:
        return AppTheme.warning;
    }
  }

  void _showMetricDetails(
    BuildContext context, {
    required String title,
    required List<String> items,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const Text('No records found.',
                    style: TextStyle(color: Colors.grey))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) => ListTile(
                      leading: const Icon(Icons.circle, size: 10),
                      title: Text(items[index]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateDiscoveryTab extends StatefulWidget {
  final String companyId;
  final String companyName;

  const _CandidateDiscoveryTab({
    required this.companyId,
    required this.companyName,
  });

  @override
  State<_CandidateDiscoveryTab> createState() => _CandidateDiscoveryTabState();
}

class _CandidateDiscoveryTabState extends State<_CandidateDiscoveryTab> {
  String _companyIndustry = '';
  bool _loadingIndustry = true;
  String _candidateScope = 'Applied';
  bool _enforceIndustryFilter = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyIndustry();
  }

  Future<void> _loadCompanyIndustry() async {
    final doc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .get();

    if (!mounted) return;

    final data = doc.data() ?? <String, dynamic>{};
    setState(() {
      _companyIndustry = (data['industry'] as String? ?? '').trim();
      _loadingIndustry = false;
    });
  }

  String _normalize(String value) => value.trim().toLowerCase();

  bool _industryMatches(String industry) {
    if (!_enforceIndustryFilter || _companyIndustry.trim().isEmpty) return true;
    final candidate = _normalize(industry);
    final company = _normalize(_companyIndustry);
    if (candidate.isEmpty || company.isEmpty) return true;
    return candidate == company ||
        candidate.contains(company) ||
        company.contains(candidate);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_alt_outlined,
                      size: 18, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loadingIndustry
                          ? 'Loading company industry filter...'
                          : _companyIndustry.isEmpty
                              ? 'Industry filter: all candidates'
                              : 'Industry filter: $_companyIndustry',
                      style: const TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _candidateScope,
                      decoration:
                          const InputDecoration(labelText: 'Candidate Scope'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Applied', child: Text('Applied only')),
                        DropdownMenuItem(
                            value: 'All', child: Text('All profiles')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _candidateScope = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<bool>(
                      value: _enforceIndustryFilter,
                      decoration:
                          const InputDecoration(labelText: 'Industry Filter'),
                      items: const [
                        DropdownMenuItem(
                            value: true, child: Text('Company industry')),
                        DropdownMenuItem(
                            value: false, child: Text('All industries')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _enforceIndustryFilter = value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .where('companyId', isEqualTo: widget.companyId)
                .limit(600)
                .snapshots(),
            builder: (context, appSnapshot) {
              final apps = appSnapshot.data?.docs ?? const [];
              final appByStudent = <String, Map<String, dynamic>>{};
              for (final doc in apps) {
                final data = doc.data();
                final studentId = (data['studentId'] as String? ?? '').trim();
                if (studentId.isEmpty) continue;
                final existing = appByStudent[studentId];
                final currentAt = data['updatedAt'] as Timestamp? ??
                    data['appliedAt'] as Timestamp?;
                if (existing == null) {
                  appByStudent[studentId] = {...data, '_docId': doc.id};
                  continue;
                }
                final existingAt = existing['updatedAt'] as Timestamp? ??
                    existing['appliedAt'] as Timestamp?;
                if ((currentAt?.millisecondsSinceEpoch ?? 0) >=
                    (existingAt?.millisecondsSinceEpoch ?? 0)) {
                  appByStudent[studentId] = {...data, '_docId': doc.id};
                }
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'applicant')
                    .limit(300)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  final docs = snapshot.data?.docs ?? const [];
                  final filtered = docs.where((doc) {
                    final data = doc.data();
                    final industry =
                        ((data['industry'] ?? data['field']) as String? ?? '')
                            .trim();
                    final hasApplication = appByStudent.containsKey(doc.id);

                    if (_candidateScope == 'Applied' && !hasApplication) {
                      return false;
                    }

                    return _industryMatches(industry);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: _EmptyPanel(
                        icon: Icons.people_outline,
                        message: 'No candidate profiles match this filter yet.',
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data();
                      final application = appByStudent[doc.id];
                      final appStatus =
                          (application?['status'] as String? ?? 'none')
                              .toLowerCase();
                      final hasApplied = application != null;
                      final canDecide = hasApplied && appStatus == 'applied';

                      final skills = ((data['skills'] as List?) ?? [])
                          .map((e) => '$e')
                          .toList();
                      final cvSkills = ((data['cvSkills'] as List?) ?? [])
                          .map((e) => '$e')
                          .toList();
                      final verified = ((data['verifiedSkills'] as List?) ?? [])
                          .map((e) => '$e')
                          .toList();
                      final allSkills = {...skills, ...cvSkills}.toList();
                      final certifications =
                          ((data['certifications'] as List?) ??
                                  const <dynamic>[])
                              .length;
                      final githubConnected = data['githubConnected'] == true;
                      final githubUsername =
                          (data['githubUsername'] as String? ?? '').trim();
                      final githubSkills =
                          ((data['githubSkills'] as List?) ?? [])
                              .map((e) => '$e')
                              .toList();
                      final cvFile =
                          (data['cvFileName'] as String? ?? '').trim();
                      final cvLink =
                          (data['cvStorageSignedUrl'] as String? ?? '').trim();

                      return GestureDetector(
                        onTap: () => _showCandidateDetails(doc.id, data),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDCE3F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  (data['avatarStoragePath'] as String?)
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? SupabaseImageWidget(
                                          storagePath: data['avatarStoragePath']
                                              as String?,
                                          isCircular: true,
                                          radius: 24,
                                        )
                                      : ((data['avatarUrl'] as String?)
                                                  ?.trim()
                                                  .isNotEmpty ==
                                              true
                                          ? CircleAvatar(
                                              backgroundColor:
                                                  const Color(0xFF1565C0),
                                              backgroundImage: NetworkImage(
                                                  data['avatarUrl'] as String),
                                            )
                                          : const CircleAvatar(
                                              backgroundColor:
                                                  Color(0xFF1565C0),
                                              child: Icon(Icons.person,
                                                  color: Colors.white),
                                            )),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (data['displayName'] as String?)
                                                      ?.trim()
                                                      .isNotEmpty ==
                                                  true
                                              ? data['displayName'] as String
                                              : 'Student Profile',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          (data['email'] as String?) ??
                                              'No email',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (verified.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.success
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${verified.length} verified',
                                        style: const TextStyle(
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: hasApplied
                                        ? _statusColor(appStatus)
                                            .withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    hasApplied
                                        ? 'Application: ${appStatus.replaceAll('_', ' ').toUpperCase()}'
                                        : 'No application submitted',
                                    style: TextStyle(
                                      color: hasApplied
                                          ? _statusColor(appStatus)
                                          : Colors.grey,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _miniTag(
                                    icon: Icons.apartment_outlined,
                                    text: ((data['industry'] ?? data['field'])
                                                as String? ??
                                            'Industry not set')
                                        .trim(),
                                  ),
                                  _miniTag(
                                    icon: Icons.workspace_premium_outlined,
                                    text: '$certifications credentials',
                                  ),
                                  _miniTag(
                                    icon: Icons.description_outlined,
                                    text: cvFile.isEmpty
                                        ? 'No CV metadata'
                                        : cvFile,
                                  ),
                                ],
                              ),
                              if (allSkills.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'Skills and CV-extracted skills',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: allSkills
                                      .take(12)
                                      .map((skill) => _skillPill(
                                            skill,
                                            color: const Color(0xFF1565C0),
                                          ))
                                      .toList(),
                                ),
                              ],
                              if (verified.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'Verified badges',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: verified
                                      .map((skill) => _skillPill(skill,
                                          color: AppTheme.success))
                                      .toList(),
                                ),
                              ],
                              if (githubConnected) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.code_rounded,
                                      size: 16,
                                      color: Color(0xFF24292F),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      githubUsername.isEmpty
                                          ? 'GitHub linked'
                                          : 'GitHub: @$githubUsername',
                                      style: const TextStyle(
                                        color: Color(0xFF24292F),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (githubSkills.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: githubSkills
                                        .map((skill) => _skillPill(
                                              skill,
                                              color: const Color(0xFF24292F),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: cvLink.isEmpty
                                          ? null
                                          : () => _openExternal(cvLink),
                                      icon: const Icon(Icons.download_outlined),
                                      label: const Text('Open CV'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: hasApplied
                                          ? () => _scheduleInterview(
                                                doc.id,
                                                data['displayName'] ??
                                                    'Student',
                                                data['email'] ?? '',
                                              )
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF8A5BFF),
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(
                                          Icons.calendar_today_outlined),
                                      label: const Text('Schedule'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (canDecide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _updateApplicationStatus(
                                          doc.id,
                                          'approved',
                                          data,
                                        ),
                                        icon: const Icon(
                                            Icons.check_circle_outline),
                                        label: const Text('Approve'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.success,
                                          side: const BorderSide(
                                            color: AppTheme.success,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _updateApplicationStatus(
                                          doc.id,
                                          'rejected',
                                          data,
                                        ),
                                        icon: const Icon(Icons.clear_outlined),
                                        label: const Text('Reject'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.error,
                                          side: const BorderSide(
                                            color: AppTheme.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showCandidateDetails(
    String studentId,
    Map<String, dynamic> data,
  ) async {
    await _registerProfileView(studentId);

    final skills = ((data['skills'] as List?) ?? []).map((e) => '$e').toList();
    final cvSkills =
        ((data['cvSkills'] as List?) ?? []).map((e) => '$e').toList();
    final verified =
        ((data['verifiedSkills'] as List?) ?? []).map((e) => '$e').toList();
    final certs = ((data['certifications'] as List?) ?? const <dynamic>[])
        .map((e) => '$e')
        .toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Candidate Profile'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  (data['avatarStoragePath'] as String?)?.trim().isNotEmpty ==
                          true
                      ? SupabaseImageWidget(
                          storagePath: data['avatarStoragePath'] as String?,
                          isCircular: true,
                          radius: 26,
                        )
                      : ((data['avatarUrl'] as String?)?.trim().isNotEmpty ==
                              true
                          ? CircleAvatar(
                              radius: 26,
                              backgroundImage:
                                  NetworkImage(data['avatarUrl'] as String),
                            )
                          : const CircleAvatar(
                              radius: 26,
                              child: Icon(Icons.person),
                            )),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((data['displayName'] as String?) ?? 'Student'),
                        Text((data['email'] as String?) ?? '',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Age: ${(data['age'] ?? 'Not set')}'),
              const SizedBox(height: 6),
              Text(
                  'Industry: ${((data['industry'] ?? data['field']) as String? ?? 'Not set').trim()}'),
              const SizedBox(height: 10),
              const Text('Skills',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: {...skills, ...cvSkills}
                    .take(20)
                    .map((s) => _skillPill(s, color: const Color(0xFF1565C0)))
                    .toList(),
              ),
              if (verified.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Verified Skills',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: verified
                      .map((s) => _skillPill(s, color: AppTheme.success))
                      .toList(),
                ),
              ],
              if (certs.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Credentials: ${certs.length}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerProfileView(String studentId) async {
    if (studentId.isEmpty) return;

    final profileRef =
        FirebaseFirestore.instance.collection('users').doc(studentId);

    await profileRef.set({
      'profileViews': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await profileRef.collection('profile_views').add({
      'companyId': widget.companyId,
      'companyName': widget.companyName,
      'viewedAt': FieldValue.serverTimestamp(),
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      case 'interview_scheduled':
        return const Color(0xFF1E88E5);
      case 'applied':
        return AppTheme.warning;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openExternal(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return;
    final canOpen = await canLaunchUrl(uri);
    if (!canOpen) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _scheduleInterview(
    String studentId,
    String studentName,
    String studentEmail,
  ) {
    showDialog(
      context: context,
      builder: (context) => _InterviewSchedulingDialog(
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        companyId: widget.companyId,
      ),
    );
  }

  Future<void> _updateApplicationStatus(
    String studentId,
    String newStatus,
    Map<String, dynamic> studentData,
  ) async {
    final appQuery = await FirebaseFirestore.instance
        .collection('applications')
        .where('studentId', isEqualTo: studentId)
        .where('companyId', isEqualTo: widget.companyId)
        .limit(1)
        .get();

    if (appQuery.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No submitted application found for this candidate.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    await appQuery.docs.first.reference.update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': studentId,
      'type': 'application_status',
      'title': newStatus == 'approved'
          ? 'Application Approved!'
          : 'Application Rejected',
      'message': newStatus == 'approved'
          ? '${widget.companyName} has approved your application!'
          : '${widget.companyName} did not move forward with your application.',
      'companyName': widget.companyName,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Candidate application marked as ${newStatus.replaceAll('_', ' ')}.',
        ),
        backgroundColor:
            newStatus == 'approved' ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  Widget _miniTag({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5A6C83)),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(color: Color(0xFF5A6C83), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _skillPill(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InternshipManagementTab extends StatefulWidget {
  final String companyId;
  final String companyName;

  const _InternshipManagementTab({
    required this.companyId,
    required this.companyName,
  });

  @override
  State<_InternshipManagementTab> createState() =>
      _InternshipManagementTabState();
}

class _InternshipManagementTabState extends State<_InternshipManagementTab> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _aboutRoleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _compensationCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _minGpaCtrl = TextEditingController();

  bool _publishing = false;
  String _mode = 'Remote';
  String _postType = 'Internship';
  String _duration = 'Not specified';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _aboutRoleCtrl.dispose();
    _locationCtrl.dispose();
    _compensationCtrl.dispose();
    _skillsCtrl.dispose();
    _minGpaCtrl.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final aboutRole = _aboutRoleCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final compensation = _compensationCtrl.text.trim();
    final minGpa = double.tryParse(_minGpaCtrl.text.trim());

    final skills = _skillsCtrl.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (title.isEmpty || description.isEmpty || skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Title, description, and required skills are required.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    setState(() => _publishing = true);

    final companyDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .get();
    final companyData = companyDoc.data() ?? <String, dynamic>{};

    await FirebaseFirestore.instance.collection('internships').add({
      'companyId': widget.companyId,
      'company': widget.companyName,
      'postType': _postType,
      'title': title,
      'description': description,
      'aboutRole': aboutRole,
      'location': location.isEmpty ? _mode : location,
      'type': _mode,
      'duration': _duration,
      'salary': compensation.isEmpty ? 'Negotiable' : compensation,
      'stipend': compensation.isEmpty ? 'Negotiable' : compensation,
      'skills': skills,
      'minimumGpa': minGpa,
      'industry': (companyData['industry'] as String?) ?? '',
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    _titleCtrl.clear();
    _descCtrl.clear();
    _aboutRoleCtrl.clear();
    _locationCtrl.clear();
    _compensationCtrl.clear();
    _skillsCtrl.clear();
    _minGpaCtrl.clear();

    setState(() => _publishing = false);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Internship post published.'),
      backgroundColor: AppTheme.success,
    ));
  }

  Future<void> _togglePostStatus(
      DocumentReference<Map<String, dynamic>> ref, bool active) async {
    await ref.set({
      'active': !active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deletePost(DocumentReference<Map<String, dynamic>> ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Internship Post?'),
        content: const Text('This will permanently remove this internship.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await ref.delete();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE3F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Internship Post',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Software Engineer Intern',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Role responsibilities and outcomes',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _aboutRoleCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'About the Role',
                  hintText: 'Team, impact, and key expectations for this role',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _postType,
                decoration: const InputDecoration(labelText: 'Post Type'),
                items: const [
                  DropdownMenuItem(
                      value: 'Internship', child: Text('Internship')),
                  DropdownMenuItem(value: 'Job', child: Text('Job')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _postType = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Colombo / Remote',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _mode,
                decoration: const InputDecoration(labelText: 'Work Mode'),
                items: const [
                  DropdownMenuItem(value: 'Remote', child: Text('Remote')),
                  DropdownMenuItem(value: 'Onsite', child: Text('Onsite')),
                  DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _mode = value);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _duration,
                decoration: const InputDecoration(labelText: 'Duration'),
                items: const [
                  DropdownMenuItem(
                      value: 'Not specified', child: Text('Not specified')),
                  DropdownMenuItem(value: '1 month', child: Text('1 month')),
                  DropdownMenuItem(value: '3 months', child: Text('3 months')),
                  DropdownMenuItem(value: '6 months', child: Text('6 months')),
                  DropdownMenuItem(
                      value: '12 months', child: Text('12 months')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _duration = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _compensationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Salary/Stipend',
                  hintText: 'LKR 45,000 / month',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _minGpaCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Minimum GPA',
                  hintText: '3.0',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _skillsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Required Skills',
                  hintText: 'Flutter, Firebase, REST',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _publishing ? null : _publishPost,
                  icon: _publishing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish_outlined),
                  label: const Text('Publish Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Recent Posts',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('internships')
              .where('companyId', isEqualTo: widget.companyId)
              .limit(200)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            docs.sort((a, b) {
              final at = a.data()['createdAt'] as Timestamp?;
              final bt = b.data()['createdAt'] as Timestamp?;
              return (bt?.millisecondsSinceEpoch ?? 0)
                  .compareTo(at?.millisecondsSinceEpoch ?? 0);
            });

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              );
            }

            if (docs.isEmpty) {
              return const _EmptyPanel(
                icon: Icons.work_outline,
                message: 'No internship posts yet.',
              );
            }

            return Column(
              children: docs.take(10).map((doc) {
                final data = doc.data();
                final active = data['active'] != false;
                final aboutRole = (data['aboutRole'] as String? ?? '').trim();
                final skills =
                    ((data['skills'] as List?) ?? []).map((e) => '$e').toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCE3F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (data['title'] as String?) ?? 'Internship',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Switch(
                            value: active,
                            activeColor: const Color(0xFF1565C0),
                            onChanged: (_) =>
                                _togglePostStatus(doc.reference, active),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(data['postType'] as String?) ?? 'Internship'} • ${(data['type'] as String?) ?? 'Mode'} • ${(data['location'] as String?) ?? ''}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${(data['duration'] as String?) ?? 'Not specified'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Compensation: ${(data['salary'] as String?) ?? (data['stipend'] as String?) ?? 'Negotiable'}',
                        style: const TextStyle(color: Color(0xFF1565C0)),
                      ),
                      if (aboutRole.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'About the Role: $aboutRole',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                      if (skills.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills
                              .take(8)
                              .map((skill) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F0FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      skill,
                                      style: const TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _deletePost(doc.reference),
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.error),
                          label: const Text('Delete',
                              style: TextStyle(color: AppTheme.error)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TokenManagementTab extends StatelessWidget {
  final String companyId;

  const _TokenManagementTab({required this.companyId});

  Future<void> _generateToken(BuildContext context) async {
    final token = _randomToken();
    await FirebaseFirestore.instance.collection('company_tokens').add({
      'companyId': companyId,
      'token': token,
      'role': 'candidate_access',
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Access token generated.'),
      backgroundColor: AppTheme.success,
    ));
  }

  Future<void> _toggleTokenStatus(
      DocumentReference<Map<String, dynamic>> ref, bool active) async {
    await ref.set({
      'active': !active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _randomToken() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final chars =
        List.generate(16, (_) => alphabet[rand.nextInt(alphabet.length)]);
    return chars.join();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE3F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Role-Based Access Tokens',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Generate and share tokens with team members to control hiring workflows.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _generateToken(context),
                  icon: const Icon(Icons.key_outlined),
                  label: const Text('Generate Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('company_tokens')
              .where('companyId', isEqualTo: companyId)
              .limit(200)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            docs.sort((a, b) {
              final at = a.data()['createdAt'] as Timestamp?;
              final bt = b.data()['createdAt'] as Timestamp?;
              return (bt?.millisecondsSinceEpoch ?? 0)
                  .compareTo(at?.millisecondsSinceEpoch ?? 0);
            });

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              );
            }

            if (docs.isEmpty) {
              return const _EmptyPanel(
                icon: Icons.key_off_outlined,
                message: 'No tokens created yet.',
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final token = (data['token'] as String?) ?? '';
                final role = (data['role'] as String?) ?? 'candidate_access';
                final active = data['active'] != false;
                final createdAt = data['createdAt'] as Timestamp?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCE3F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              token,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: token));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text('Token copied.'),
                                backgroundColor: AppTheme.success,
                              ));
                            },
                            icon: const Icon(Icons.copy_rounded),
                          ),
                        ],
                      ),
                      Text(
                        'Role: $role',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        createdAt == null
                            ? 'Created just now'
                            : 'Created: ${_fmtDate(createdAt)}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppTheme.success.withValues(alpha: 0.12)
                                  : AppTheme.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              active ? 'ACTIVE' : 'PAUSED',
                              style: TextStyle(
                                color: active
                                    ? AppTheme.success
                                    : AppTheme.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () =>
                                _toggleTokenStatus(doc.reference, active),
                            icon: Icon(active
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline),
                            label: Text(active ? 'Pause' : 'Activate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _fmtDate(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _CompanySettingsTab extends StatefulWidget {
  final String companyId;
  final String initialCompanyName;
  final String email;

  const _CompanySettingsTab({
    required this.companyId,
    required this.initialCompanyName,
    required this.email,
  });

  @override
  State<_CompanySettingsTab> createState() => _CompanySettingsTabState();
}

class _CompanySettingsTabState extends State<_CompanySettingsTab> {
  static const String _profileBucket = 'profile';

  final _nameCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();

  bool _notifyNewApplications = true;
  bool _notifyCandidateSuggestions = true;
  bool _darkMode = false;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingLogo = false;

  static const List<String> _industryOptions = [
    'IT & Software',
    'Business & Management',
    'Design & UX/UI',
    'Engineering',
    'Healthcare',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _industryCtrl.dispose();
    _websiteCtrl.dispose();
    _descriptionCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .get();
    final data = doc.data() ?? <String, dynamic>{};

    if (!mounted) return;

    _nameCtrl.text = (data['name'] as String?)?.trim().isNotEmpty == true
        ? data['name'] as String
        : widget.initialCompanyName;
    _industryCtrl.text = (data['industry'] as String?) ?? '';
    _websiteCtrl.text = (data['website'] as String?) ?? '';
    _descriptionCtrl.text = (data['description'] as String?) ?? '';
    _logoCtrl.text = (data['logoStoragePath'] as String?) ??
        (data['logoUrl'] as String?) ??
        '';
    _notifyNewApplications = data['notifyNewApplications'] as bool? ?? true;
    _notifyCandidateSuggestions =
        data['notifyCandidateSuggestions'] as bool? ?? true;
    _darkMode = (data['appearanceMode'] as String? ?? 'light') == 'dark';

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .set({
      'name': _nameCtrl.text.trim(),
      'industry': _industryCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'logoStoragePath': _logoCtrl.text.trim(),
      'notifyNewApplications': _notifyNewApplications,
      'notifyCandidateSuggestions': _notifyCandidateSuggestions,
      'appearanceMode': _darkMode ? 'dark' : 'light',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Company profile and preferences updated.'),
      backgroundColor: AppTheme.success,
    ));
  }

  Future<void> _pickIndustry() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF161A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _industryOptions
              .map(
                (option) => ListTile(
                  leading: Icon(
                    _industryCtrl.text.trim() == option
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _industryCtrl.text.trim() == option
                        ? AppTheme.primaryLight
                        : AppTheme.textSecondary,
                  ),
                  title: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, option),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected == null || !mounted) return;
    setState(() => _industryCtrl.text = selected);
  }

  Future<void> _uploadCompanyLogoToSupabase() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (!mounted || picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final ext = file.extension?.toLowerCase() ?? 'jpg';
    final safeExt = ['png', 'jpg', 'jpeg', 'webp'].contains(ext) ? ext : 'jpg';
    final path =
        'companies/${widget.companyId}/logo_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    setState(() => _uploadingLogo = true);
    try {
      final storage = Supabase.instance.client.storage.from(_profileBucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .set({
        'logoStoragePath': path,
        'logoStorageBucket': _profileBucket,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _logoCtrl.text = path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Company logo uploaded to Supabase $_profileBucket bucket.'),
        backgroundColor: AppTheme.success,
      ));
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('bucket not found') ||
          message.contains('statuscode: 404')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Supabase bucket "profile" not found. Please create it in Supabase Storage.'),
          backgroundColor: AppTheme.warning,
        ));
      } else if (message.contains('statuscode: 403') ||
          message.contains('row-level security') ||
          message.contains('unauthorized') ||
          message.contains('permission denied')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Supabase policy denied upload (403). Allow INSERT/SELECT on bucket "profile" for anon and authenticated roles.'),
          backgroundColor: AppTheme.warning,
        ));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logo upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Company Logo Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE3F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.image_rounded,
                      color: Color(0xFF1565C0), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Company Logo',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_logoCtrl.text.trim().isNotEmpty) ...[
                const Text(
                  'Current Logo',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 120,
                      height: 120,
                      color: const Color(0xFFF4F7FC),
                      child: FutureBuilder<String?>(
                        future: _logoCtrl.text.trim().contains('http')
                            ? Future.value(_logoCtrl.text.trim())
                            : ImageService.getCompanyLogoUrl(
                                _logoCtrl.text.trim()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError || snapshot.data == null) {
                            return const Icon(
                              Icons.business,
                              size: 48,
                              color: Color(0xFF1565C0),
                            );
                          }

                          return Image.network(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.business,
                              size: 48,
                              color: Color(0xFF1565C0),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _uploadingLogo ? null : _uploadCompanyLogoToSupabase,
                  icon: _uploadingLogo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Upload Company Logo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Company Profile Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE3F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.business_rounded,
                      color: Color(0xFF1565C0), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Company Profile',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.business, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: const Text('Industry',
                    style: TextStyle(color: Colors.black87, fontSize: 14)),
                subtitle: Text(
                  _industryCtrl.text.trim().isEmpty
                      ? 'Select industry'
                      : _industryCtrl.text.trim(),
                  style: const TextStyle(color: Color(0xFF1565C0)),
                ),
                trailing: const Icon(Icons.keyboard_arrow_down_rounded),
                onTap: _pickIndustry,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFDCE3F0)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _websiteCtrl,
                decoration: InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.language, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Company Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description, size: 20),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Notification Preferences Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE3F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_rounded,
                      color: Color(0xFF1565C0), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Notification Preferences',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('New applications',
                    style: TextStyle(color: Colors.black87)),
                subtitle: const Text(
                    'Get notified about new applicant submissions',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: _notifyNewApplications,
                onChanged: (value) {
                  setState(() => _notifyNewApplications = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Candidate suggestions',
                    style: TextStyle(color: Colors.black87)),
                subtitle: const Text('Get notified about matching candidates',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                value: _notifyCandidateSuggestions,
                onChanged: (value) {
                  setState(() => _notifyCandidateSuggestions = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Legal & More Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE3F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.gavel_rounded,
                      color: Color(0xFF1565C0), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Legal & Information',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _PrivacyPolicyPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.privacy_tip_outlined),
                      label: const Text('Privacy Policy'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _SecurityPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.security_outlined),
                      label: const Text('Security'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _TermsOfServicePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Terms of Service'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Save & Logout Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE3F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save All Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => AuthService.signOut(),
                  icon: const Icon(Icons.logout, color: AppTheme.error),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ============================================================================
// Interview Scheduling Dialog
// ============================================================================

class _InterviewSchedulingDialog extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String companyId;

  const _InterviewSchedulingDialog({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.companyId,
  });

  @override
  State<_InterviewSchedulingDialog> createState() =>
      _InterviewSchedulingDialogState();
}

class _InterviewSchedulingDialogState
    extends State<_InterviewSchedulingDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _interviewType = 'online';
  final _locationCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _scheduling = false;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _linkCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _scheduleInterview() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _scheduling = true);

    try {
      final interviewDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final appQuery = await FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: widget.studentId)
          .where('companyId', isEqualTo: widget.companyId)
          .limit(1)
          .get();

      if (appQuery.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('applications').add({
          'studentId': widget.studentId,
          'companyId': widget.companyId,
          'studentName': widget.studentName,
          'studentEmail': widget.studentEmail,
          'status': 'interview_scheduled',
          'interviewDate': interviewDateTime,
          'interviewType': _interviewType,
          'interviewLocation': _locationCtrl.text.trim(),
          'interviewLink': _linkCtrl.text.trim(),
          'interviewToken': _tokenCtrl.text.trim(),
          'appliedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await appQuery.docs.first.reference.update({
          'status': 'interview_scheduled',
          'interviewDate': interviewDateTime,
          'interviewType': _interviewType,
          'interviewLocation': _locationCtrl.text.trim(),
          'interviewLink': _linkCtrl.text.trim(),
          'interviewToken': _tokenCtrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': widget.studentId,
        'type': 'interview_scheduled',
        'title': 'Interview Scheduled!',
        'message':
            'Your interview with ${widget.companyId} has been scheduled. Check your applications for details.',
        'companyName': widget.companyId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interview scheduled and student notified.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scheduling interview: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() => _scheduling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Schedule Interview',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Student: ${widget.studentName}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Interview Date'),
                subtitle: Text(
                  _selectedDate == null
                      ? 'Select date'
                      : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Interview Time'),
                subtitle: Text(
                  _selectedTime == null
                      ? 'Select time'
                      : _selectedTime!.format(context),
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.access_time_outlined),
                onTap: _pickTime,
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interview Type',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(label: Text('Online'), value: 'online'),
                      ButtonSegment(
                          label: Text('In-Person'), value: 'inperson'),
                      ButtonSegment(label: Text('Phone'), value: 'phone'),
                    ],
                    selected: <String>{_interviewType},
                    onSelectionChanged: (newSelection) {
                      setState(() => _interviewType = newSelection.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_interviewType == 'inperson')
                TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Interview Location',
                    hintText: 'Office address or meeting room',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                )
              else
                TextField(
                  controller: _linkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Meeting Link',
                    hintText: 'Zoom/Teams/Google Meet URL',
                    prefixIcon: Icon(Icons.link_outlined),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _tokenCtrl,
                decoration: const InputDecoration(
                  labelText: 'Optional Access Token',
                  hintText: 'Meeting code, password, etc.',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _scheduling ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _scheduling ? null : _scheduleInterview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                    child: _scheduling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Schedule Interview'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Analytics Tab
// ============================================================================

class _CompanyAnalyticsTab extends StatefulWidget {
  final String companyId;

  const _CompanyAnalyticsTab({required this.companyId});

  @override
  State<_CompanyAnalyticsTab> createState() => _CompanyAnalyticsTabState();
}

class _CompanyAnalyticsTabState extends State<_CompanyAnalyticsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('companyId', isEqualTo: widget.companyId)
          .snapshots(),
      builder: (context, appSnapshot) {
        if (!appSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        final applications = appSnapshot.data!.docs;
        final totalApps = applications.length;
        final approved =
            applications.where((d) => d['status'] == 'approved').length;
        final rejected =
            applications.where((d) => d['status'] == 'rejected').length;
        final interviewed = applications
            .where(
                (d) => d['status'] == 'approved' && d['interviewDate'] != null)
            .length;
        final hired = applications.where((d) => d['status'] == 'hired').length;

        int pending = totalApps - approved - rejected;

        final approvalRate = totalApps > 0 ? (approved / totalApps) * 100 : 0.0;
        final interviewRate =
            approved > 0 ? (interviewed / approved) * 100 : 0.0;
        final hireRate = approved > 0 ? (hired / approved) * 100 : 0.0;

        final appsByPost = <String, int>{};
        for (var app in applications) {
          final postId = app['internshipId'] as String?;
          if (postId != null) {
            appsByPost[postId] = (appsByPost[postId] ?? 0) + 1;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCE3F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Application Funnel',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FunnelStage(
                    label: 'Total Applications',
                    count: totalApps,
                    percentage: 100.0,
                    color: const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 12),
                  _FunnelStage(
                    label: 'Pending Review',
                    count: pending,
                    percentage: totalApps > 0 ? (pending / totalApps) * 100 : 0,
                    color: const Color(0xFFFFB020),
                  ),
                  const SizedBox(height: 12),
                  _FunnelStage(
                    label: 'Approved / Shortlisted',
                    count: approved,
                    percentage: approvalRate,
                    color: AppTheme.success,
                  ),
                  const SizedBox(height: 12),
                  _FunnelStage(
                    label: 'Interviewed',
                    count: interviewed,
                    percentage:
                        totalApps > 0 ? (interviewed / totalApps) * 100 : 0,
                    color: const Color(0xFF8A5BFF),
                  ),
                  const SizedBox(height: 12),
                  _FunnelStage(
                    label: 'Hired',
                    count: hired,
                    percentage: totalApps > 0 ? (hired / totalApps) * 100 : 0,
                    color: const Color(0xFF18C17C),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE3F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Approval Rate',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${approvalRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE3F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Interview Rate',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${interviewRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Color(0xFF8A5BFF),
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCE3F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Hire Rate',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hireRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Color(0xFF18C17C),
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (appsByPost.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE3F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Applications by Job Post',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...appsByPost.entries.map((entry) {
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('internships')
                            .doc(entry.key)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final postTitle =
                              snapshot.data?['title'] as String? ??
                                  'Unknown Post';
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      postTitle,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFF1565C0).withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${entry.value} applications',
                                      style: const TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FunnelStage extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const _FunnelStage({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE3F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPolicyPage extends StatelessWidget {
  const _PrivacyPolicyPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A5F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE3F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Last Updated: March 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'At SkillMatch, we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our platform.\n\n'
                  '1. Information We Collect\n'
                  'We collect information you provide directly, such as your company details, contact information, and application data.\n\n'
                  '2. How We Use Your Information\n'
                  'We use your information to operate the platform, improve services, and communicate with you about your account.\n\n'
                  '3. Data Security\n'
                  'We implement appropriate security measures to protect your personal information against unauthorized access.\n\n'
                  '4. Your Rights\n'
                  'You have the right to access, correct, or delete your personal data.\n\n'
                  'For more information, please contact our support team.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityPage extends StatelessWidget {
  const _SecurityPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Security',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A5F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE3F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security Center',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Account Security',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Use a strong password with mix of characters\n'
                  '• Enable two-factor authentication (coming soon)\n'
                  '• Review active sessions regularly\n'
                  '• Do not share your login credentials\n'
                  '• Logout when using shared devices',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data Protection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• All data is encrypted in transit and at rest\n'
                  '• We use industry-standard security protocols\n'
                  '• Regular security audits are conducted\n'
                  '• Access logs are maintained for compliance',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Report a Security Issue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you discover a security vulnerability, please email our security team at security@skillmatch.app',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsOfServicePage extends StatelessWidget {
  const _TermsOfServicePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A5F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE3F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Effective Date: March 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'By using SkillMatch, you agree to these Terms of Service.\n\n'
                  '1. Use License\n'
                  'Permission is granted to temporarily download material from the SkillMatch platform for personal, non-commercial transitory viewing only.\n\n'
                  '2. Disclaimer\n'
                  'The materials on SkillMatch are provided on an "as is" basis. SkillMatch makes no warranties or representations regarding the accuracy or completeness of the information.\n\n'
                  '3. Limitations\n'
                  'In no event shall SkillMatch or its suppliers be liable for damages arising out of or related to your use of the platform.\n\n'
                  '4. User Responsibilities\n'
                  'You are responsible for maintaining confidentiality of your account and password. You agree to notify us immediately of any unauthorized use.\n\n'
                  '5. Modification of Terms\n'
                  'We may revise these terms at any time without notice. Your continued use constitutes acceptance of revised terms.\n\n'
                  'For clarifications, contact support@skillmatch.app',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPanel({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE3F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 34),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitleText;
  final IconData subtitleIcon;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitleText,
    required this.subtitleIcon,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // Light slate
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF0F4C81), size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(subtitleIcon, color: subtitleColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  subtitleText,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: const Color(0xFFCBD5E1)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inbox_rounded,
                      size: 32, color: Color(0xFFCBD5E1)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.search,
                        size: 16, color: Color(0xFF0F4C81)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'No applications received yet.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you receive new applications\nthat match your criteria, they will\nappear here for your review.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Future routing functionality could go here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C81),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Post a Job Now',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(16)));

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
