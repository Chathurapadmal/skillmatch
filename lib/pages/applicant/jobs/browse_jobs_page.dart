import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';

const Color _primary = Color(0xFF1565C0);
const Color _navy = Color(0xFF1E3A5F);
const Color _accent = Color(0xFF2E86AB);
const Color _background = Color(0xFFF8FAFC);
const Color _cardBorder = Color(0xFFDCE3F0);
const Color _softBlue = Color(0xFFEAF3FA);
const Color _mutedText = Color(0xFF64748B);

class BrowseJobsPage extends StatefulWidget {
  const BrowseJobsPage({super.key});

  @override
  State<BrowseJobsPage> createState() => _BrowseJobsPageState();
}

class _BrowseJobsPageState extends State<BrowseJobsPage> {
  final TextEditingController _queryController =
      TextEditingController(text: 'software engineer');
  final TextEditingController _locationController =
      TextEditingController(text: 'remote');

  bool _isLoading = false;
  String? _error;
  int _resultCount = 0;
  int _databaseCount = 0;
  int _adzunaCount = 0;
  final Set<String> _applyingJobKeys = <String>{};
  List<JobItem> _jobs = const [];

  @override
  void initState() {
    super.initState();
    _searchJobs();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _searchJobs() async {
    final query = _queryController.text.trim();
    final location = _locationController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _error = 'Enter a job title or keyword.';
        _jobs = const [];
        _resultCount = 0;
        _databaseCount = 0;
        _adzunaCount = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      JobSearchResponse? apiResponse;
      String? apiError;
      List<JobItem> dbJobs = const [];
      String? dbError;

      try {
        apiResponse = await ApiService.fetchJobs(
          query: query,
          location: location.isEmpty ? 'remote' : location,
        );
      } catch (e) {
        apiError = e.toString().replaceFirst('Exception: ', '');
      }

      try {
        dbJobs = await _searchDatabaseJobs(query: query, location: location);
      } catch (e) {
        dbError = e.toString().replaceFirst('Exception: ', '');
      }

      final mergedJobs = _mergeJobs(
        dbJobs,
        apiResponse?.jobs ?? const <JobItem>[],
      );

      final adzunaCount = apiResponse?.jobs.length ?? 0;
      final databaseCount = dbJobs.length;

      final combinedError = (apiError != null && dbError != null)
          ? 'Unable to search jobs right now.\n$apiError\n$dbError'
          : null;

      if (!mounted) return;

      setState(() {
        _jobs = mergedJobs;
        _resultCount = mergedJobs.length;
        _adzunaCount = adzunaCount;
        _databaseCount = databaseCount;
        _error = combinedError;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _jobs = const [];
        _resultCount = 0;
        _databaseCount = 0;
        _adzunaCount = 0;
      });
    }
  }

  Future<List<JobItem>> _searchDatabaseJobs({
    required String query,
    required String location,
  }) async {
    final queryTokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    final normalizedLocation = location.trim().toLowerCase();

    final snapshot = await FirebaseFirestore.instance
        .collection('internships')
        .where('active', isEqualTo: true)
        .limit(250)
        .get();

    final jobs = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final title = (data['title'] as String?)?.trim() ?? 'Internship';
          final company = (data['company'] as String?)?.trim() ?? 'Company';
          final roleDescription = (data['aboutRole'] as String?)?.trim() ??
              (data['description'] as String?)?.trim() ??
              '';
          final jobLocation = ((data['location'] as String?) ??
                  (data['type'] as String?) ??
                  'Remote')
              .trim();
          final salary = ((data['salary'] as String?) ??
                  (data['stipend'] as String?) ??
                  'Negotiable')
              .trim();
          final skills = ((data['skills'] as List?) ?? const [])
              .map((item) => '$item'.trim())
              .where((item) => item.isNotEmpty)
              .join(', ');

          final searchableText = [
            title,
            company,
            roleDescription,
            jobLocation,
            skills,
          ].join(' ').toLowerCase();

          final queryMatches =
              queryTokens.every((token) => searchableText.contains(token));
          final locationMatches = normalizedLocation.isEmpty ||
              jobLocation.toLowerCase().contains(normalizedLocation);

          if (!queryMatches || !locationMatches) {
            return null;
          }

          return JobItem(
            title: title,
            company: company,
            location: jobLocation,
            description: roleDescription,
            salary: salary,
            url: 'skillmatch://internship/${doc.id}',
            source: 'SkillMatch DB',
          );
        })
        .whereType<JobItem>()
        .toList();

    return jobs;
  }

  List<JobItem> _mergeJobs(List<JobItem> primary, List<JobItem> secondary) {
    final merged = <JobItem>[];
    final seen = <String>{};

    void addJobs(List<JobItem> items) {
      for (final job in items) {
        final key =
            '${job.title.toLowerCase()}|${job.company.toLowerCase()}|${job.location.toLowerCase()}';
        if (seen.add(key)) {
          merged.add(job);
        }
      }
    }

    addJobs(primary);
    addJobs(secondary);
    return merged;
  }

  Future<void> _openJob(String rawUrl) async {
    final link = rawUrl.trim();
    if (link.isEmpty) return;

    Uri uri;
    try {
      uri = Uri.parse(link);
    } catch (_) {
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open job link.'),
          backgroundColor: _navy,
        ),
      );
    }
  }

  String _jobKey(JobItem job) {
    return '${job.title.toLowerCase()}|${job.company.toLowerCase()}|${job.location.toLowerCase()}';
  }

  String? _extractInternshipId(JobItem job) {
    if (job.source != 'SkillMatch DB') return null;
    final uri = Uri.tryParse(job.url.trim());
    if (uri == null || uri.scheme != 'skillmatch') return null;

    // Support both formats:
    // 1) skillmatch://internship/<id>  (host=internship, path=/id)
    // 2) skillmatch:///internship/<id> (path=/internship/id)
    String id = '';
    if (uri.host == 'internship' && uri.pathSegments.isNotEmpty) {
      id = uri.pathSegments.first.trim();
    } else if (uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'internship') {
      id = uri.pathSegments[1].trim();
    }

    return id.isEmpty ? null : id;
  }

  Future<void> _showJobDetails(JobItem job) async {
    await showModalBottomSheet<void>(
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
                job.title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _sourceBadge(job.source),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(Icons.business_outlined, job.company),
                  _pill(Icons.place_outlined, job.location),
                  _pill(Icons.payments_outlined, job.salary),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                job.description.trim().isEmpty
                    ? 'No additional description provided.'
                    : job.description,
                style: const TextStyle(
                  color: Color(0xFF58637A),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _applyToJob(job);
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Apply'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (job.source == 'SkillMatch DB') {
                          _applyToJob(job);
                        } else {
                          _openJob(job.url);
                        }
                      },
                      icon: Icon(
                        job.source == 'SkillMatch DB'
                            ? Icons.check_circle_outline_rounded
                            : Icons.open_in_new_rounded,
                      ),
                      label: Text(
                        job.source == 'SkillMatch DB'
                            ? 'Quick Apply'
                            : 'Open Listing',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyToJob(JobItem job) async {
    final key = _jobKey(job);
    if (_applyingJobKeys.contains(key)) return;

    setState(() => _applyingJobKeys.add(key));

    try {
      if (job.source != 'SkillMatch DB') {
        if (job.url.trim().isEmpty) {
          throw Exception('No application link available for this job.');
        }
        await _openJob(job.url);
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Please sign in to apply for this job.');
      }

      final internshipId = _extractInternshipId(job);
      if (internshipId == null) {
        throw Exception('Unable to apply for this job right now.');
      }

      final existing = await FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: uid)
          .where('internshipId', isEqualTo: internshipId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('You have already applied for this internship.');
      }

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? <String, dynamic>{};
      final studentName =
          (userData['name'] as String?)?.trim().isNotEmpty == true
              ? userData['name'] as String
              : (FirebaseAuth.instance.currentUser?.displayName ?? 'Student');
      final studentEmail =
          (userData['email'] as String?)?.trim().isNotEmpty == true
              ? userData['email'] as String
              : (FirebaseAuth.instance.currentUser?.email ?? '');

      final internshipDoc = await FirebaseFirestore.instance
          .collection('internships')
          .doc(internshipId)
          .get();
      final internshipData = internshipDoc.data() ?? <String, dynamic>{};

      await FirebaseFirestore.instance.collection('applications').add({
        'studentId': uid,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'internshipId': internshipId,
        'companyId': internshipData['companyId'],
        'title': internshipData['title'] ?? job.title,
        'company': internshipData['company'] ?? job.company,
        'industry': internshipData['industry'] ?? '',
        'status': 'applied',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Application submitted successfully.'),
        backgroundColor: AppTheme.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.warning,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _applyingJobKeys.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1554F6), Color(0xFF4E7BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x331554F6),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.work_history_rounded,
                            color: Colors.white, size: 26),
                        SizedBox(width: 10),
                        Text(
                          'Browse Jobs',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Discover matches from SkillMatch and live market listings',
                      style: TextStyle(
                        color: Color(0xFFEAF1FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _summaryChip(
                          icon: Icons.grid_view_rounded,
                          label: '$_resultCount Total',
                        ),
                        _summaryChip(
                          icon: Icons.apartment_rounded,
                          label: '$_databaseCount SkillMatch',
                        ),
                        _summaryChip(
                          icon: Icons.public_rounded,
                          label: '$_adzunaCount Adzuna',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E9F6)),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _queryController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchJobs(),
                            decoration: InputDecoration(
                              hintText: 'Search by title, skill, or keyword',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: const Color(0xFFF7FAFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _locationController,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _searchJobs(),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Location (e.g. remote, new york)',
                                    prefixIcon:
                                        const Icon(Icons.location_on_outlined),
                                    filled: true,
                                    fillColor: const Color(0xFFF7FAFF),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE0E0E0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE0E0E0)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _searchJobs,
                                icon: const Icon(Icons.tune_rounded),
                                label: const Text('Search'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isLoading
                          ? 'Searching jobs...'
                          : 'Showing $_resultCount jobs matched to your search',
                      style: const TextStyle(
                        color: Color(0xFFEAF1FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x24FFFFFF),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFD8DE)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 36),
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: _searchJobs,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_jobs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  color: Color(0xFF7F8CA3), size: 34),
              SizedBox(height: 10),
              Text(
                'No jobs found. Try another keyword or location.',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _searchJobs,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final job = _jobs[index];
          final isApplying = _applyingJobKeys.contains(_jobKey(job));
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4EBF7)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120A2F6A),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _sourceBadge(job.source),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(Icons.business_outlined, job.company),
                      _pill(Icons.place_outlined, job.location),
                      _pill(Icons.payments_outlined, job.salary),
                    ],
                  ),
                  if (job.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      job.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF58637A),
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          job.source == 'SkillMatch DB'
                              ? 'Matched from your platform database'
                              : 'Live listing from job provider',
                          style: const TextStyle(
                            color: Color(0xFF52607A),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showJobDetails(job),
                            icon:
                                const Icon(Icons.visibility_outlined, size: 18),
                            label: const Text('View'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed:
                                isApplying ? null : () => _applyToJob(job),
                            icon: isApplying
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    job.source == 'SkillMatch DB'
                                        ? Icons.send_rounded
                                        : Icons.open_in_new_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              isApplying
                                  ? 'Applying...'
                                  : (job.source == 'SkillMatch DB'
                                      ? 'Apply'
                                      : 'Apply Now'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sourceBadge(String source) {
    final isLocal = source == 'SkillMatch DB';
    final bg = isLocal ? const Color(0xFFE8F1FF) : const Color(0xFFEAF8EE);
    final fg = isLocal ? const Color(0xFF1B5ED8) : const Color(0xFF1E8B4A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        source,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF60708D)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2E3A4D),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}