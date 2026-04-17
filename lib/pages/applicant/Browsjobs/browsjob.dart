import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/api_service.dart';

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

    if (query.isEmpty) {
      setState(() {
        _error = 'Enter a job title or keyword.';
        _jobs = const [];
        _resultCount = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.fetchJobs(
        query: query,
        location: _locationController.text.trim().isEmpty
            ? 'remote'
            : _locationController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _jobs = response.jobs;
        _resultCount = response.count;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _jobs = const [];
        _resultCount = 0;
      });
    }
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
        const SnackBar(content: Text('Could not open job link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Browse Jobs',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _queryController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchJobs(),
                    decoration: InputDecoration(
                      hintText: 'Search by title, skill, or keyword',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
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
                            hintText: 'Location (e.g. remote, new york)',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _searchJobs,
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLoading
                        ? 'Searching jobs...'
                        : '$_resultCount results from Adzuna',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
      );
    }

    if (_jobs.isEmpty) {
      return const Center(
        child: Text(
          'No jobs found. Try another keyword or location.',
          style: TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _searchJobs,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final job = _jobs[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE6EAF0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
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
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        job.source,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: job.url.trim().isEmpty
                            ? null
                            : () => _openJob(job.url),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('View Job'),
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

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.black54),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
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
