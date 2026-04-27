part of 'company_dashboard.dart';

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
              final items = topApplications
                  .map((e) =>
                      '${(e.data()['studentName'] as String? ?? 'Student')} • ${(e.data()['title'] as String? ?? 'Role')}')
                  .toList();
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
              _showMetricDetails(
                context,
                title: 'Active Posts',
                items: items,
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A5F), Color(0xFF2E86AB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A5F).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome Back! ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  companyName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.business_center,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Track applicants, manage active posts, and move top talent forward.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: openApplicantsDetails,
                        child: _MetricCard(
                          icon: Icons.assignment_ind_outlined,
                          label: 'Total Applicants',
                          value: '${applications.length}',
                          color: const Color(0xFF1565C0),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: openShortlistedDetails,
                        child: _MetricCard(
                          icon: Icons.check_circle_outline,
                          label: 'Shortlisted',
                          value: '$shortlisted',
                          color: AppTheme.success,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: openActivePostsDetails,
                        child: _MetricCard(
                          icon: Icons.work_outline,
                          label: 'Active Posts',
                          value: '$activePosts',
                          color: AppTheme.warning,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Recent Applications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 28),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (topApplications.isEmpty)
                  _EmptyPanel(
                    icon: Icons.inbox_rounded,
                    message: 'No applications received yet.',
                  )
                else
                  ...topApplications.take(5).map((doc) {
                    final data = doc.data();
                    final status =
                        (data['status'] as String? ?? 'applied').toLowerCase();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFDCE3F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data['studentName'] as String?)
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? data['studentName'] as String
                                      : 'Student Candidate',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E3A5F),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  (data['title'] as String?) ??
                                      'Internship position',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  _statusColor(status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    _statusColor(status).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
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
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Color(0xFF1565C0),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (items.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No records found',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (_, index) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1565C0)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      items[index],
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
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

  Widget _buildCandidateDiscoveryHeader() {
    final industryLabel = _loadingIndustry
        ? 'Loading company industry...'
        : _companyIndustry.isEmpty
            ? 'All industries'
            : _companyIndustry;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE3F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2E86AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.manage_search_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Candidate Discovery',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Review applicant profiles, verified skills, CV details, and interview actions in one focused workspace.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCandidateFilterSection(
              icon: Icons.filter_alt_outlined,
              title: 'Discovery Filters',
              subtitle:
                  'Choose which profiles appear and how closely they should match your company industry.',
              children: [
                _buildCandidateFilterRow([
                  DropdownButtonFormField<String>(
                    value: _candidateScope,
                    decoration: const InputDecoration(
                      labelText: 'Candidate Scope',
                      prefixIcon: Icon(Icons.people_alt_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Applied',
                        child: Text('Applied only'),
                      ),
                      DropdownMenuItem(
                        value: 'All',
                        child: Text('All profiles'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _candidateScope = value);
                    },
                  ),
                  DropdownButtonFormField<bool>(
                    value: _enforceIndustryFilter,
                    decoration: const InputDecoration(
                      labelText: 'Industry Filter',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: true,
                        child: Text('Company industry'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('All industries'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _enforceIndustryFilter = value);
                    },
                  ),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _candidateFilterChip(
                      icon: Icons.badge_outlined,
                      text: _candidateScope == 'Applied'
                          ? 'Showing applied candidates'
                          : 'Showing all applicant profiles',
                      color: const Color(0xFF1565C0),
                    ),
                    _candidateFilterChip(
                      icon: Icons.domain_outlined,
                      text: _enforceIndustryFilter
                          ? 'Industry: $industryLabel'
                          : 'Industry: all industries',
                      color: _enforceIndustryFilter
                          ? AppTheme.success
                          : const Color(0xFF8A5BFF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateFilterSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1565C0),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCandidateFilterRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _candidateFilterChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCandidateDiscoveryHeader(),
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
                        onTap: () => _showCandidateDetails(data),
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
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF1565C0),
                                    backgroundImage:
                                        (data['avatarUrl'] as String?)
                                                    ?.trim()
                                                    .isNotEmpty ==
                                                true
                                            ? NetworkImage(
                                                data['avatarUrl'] as String)
                                            : null,
                                    child: (data['avatarUrl'] as String?)
                                                ?.trim()
                                                .isNotEmpty ==
                                            true
                                        ? null
                                        : const Icon(Icons.person,
                                            color: Colors.white),
                                  ),
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

  void _showCandidateDetails(Map<String, dynamic> data) {
    final skills = ((data['skills'] as List?) ?? []).map((e) => '$e').toList();
    final cvSkills =
        ((data['cvSkills'] as List?) ?? []).map((e) => '$e').toList();
    final verified =
        ((data['verifiedSkills'] as List?) ?? []).map((e) => '$e').toList();
    final certs = ((data['certifications'] as List?) ?? const <dynamic>[])
        .map((e) => '$e')
        .toList();

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
                  CircleAvatar(
                    radius: 26,
                    backgroundImage:
                        (data['avatarUrl'] as String?)?.trim().isNotEmpty ==
                                true
                            ? NetworkImage(data['avatarUrl'] as String)
                            : null,
                    child: (data['avatarUrl'] as String?)?.trim().isNotEmpty ==
                            true
                        ? null
                        : const Icon(Icons.person),
                  ),
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
    // Find or create an application document for this student
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

    // Update existing application
    await appQuery.docs.first.reference.update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send notification to student
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
