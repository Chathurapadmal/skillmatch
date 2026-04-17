import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Saved Jobs',
          style: TextStyle(
            color: Color(0xFF1565C0),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1565C0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in to view saved jobs.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, profileSnapshot) {
                final savedIds = ((profileSnapshot.data
                            ?.data()?['savedInternships'] as List?) ??
                        const [])
                    .map((item) => '$item')
                    .where((item) => item.trim().isNotEmpty)
                    .toSet();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('internships')
                      .where('active', isEqualTo: true)
                      .limit(200)
                      .snapshots(),
                  builder: (context, internshipSnapshot) {
                    if (internshipSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      );
                    }

                    final savedJobs = internshipSnapshot.data?.docs
                            .where((doc) => savedIds.contains(doc.id))
                            .toList() ??
                        [];

                    if (savedJobs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No saved jobs yet. Tap the bookmark on a job card to save it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: savedJobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = savedJobs[index];
                        final data = doc.data();
                        final title =
                            (data['title'] as String?) ?? 'Internship';
                        final company =
                            (data['company'] as String?) ?? 'Company';
                        final location = ((data['type'] as String?) ??
                                (data['location'] as String?) ??
                                'Remote')
                            .trim();
                        final description =
                            (data['aboutRole'] as String?)?.trim() ?? '';
                        final skills = ((data['skills'] as List?) ?? const [])
                            .map((e) => '$e')
                            .toList();

                        return _SavedJobCard(
                          title: title,
                          company: company,
                          location: location,
                          description: description,
                          skills: skills,
                          onOpen: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (_) => Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 20, 24),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$company • $location',
                                      style: const TextStyle(
                                          color: Colors.black54),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      description.isEmpty
                                          ? 'No additional description provided.'
                                          : description,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (skills.isNotEmpty) ...[
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
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: skills
                                            .take(12)
                                            .map(
                                              (skill) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFE8F0FF),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  skill,
                                                  style: const TextStyle(
                                                    color: Color(0xFF1565C0),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
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

class _SavedJobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String description;
  final List<String> skills;
  final VoidCallback onOpen;

  const _SavedJobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.skills,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
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
            CircleAvatar(
              backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
              child: const Icon(Icons.bookmark, color: Color(0xFF1565C0)),
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
                  if (description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${skills.take(4).join(' • ')}${skills.length > 4 ? '…' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
