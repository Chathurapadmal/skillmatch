import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ProfileViewsScreen extends StatelessWidget {
  const ProfileViewsScreen({super.key});

  String _fmtDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile Views',
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
          ? const Center(child: Text('Sign in to view profile views.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, profileSnapshot) {
                final profile =
                    profileSnapshot.data?.data() ?? const <String, dynamic>{};
                final totalViews =
                    (profile['profileViews'] as num?)?.toInt() ?? 0;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('profile_views')
                      .orderBy('viewedAt', descending: true)
                      .snapshots(),
                  builder: (context, viewsSnapshot) {
                    if (viewsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      );
                    }

                    final views = viewsSnapshot.data?.docs ?? const [];

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDCE3F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.visibility_outlined,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Profile Views',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalViews',
                                      style: const TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'View History',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (views.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Center(
                              child: Text(
                                'No company has viewed your profile yet.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          )
                        else
                          ...views.map((doc) {
                            final data = doc.data();
                            final companyName = (data['companyName'] as String?)
                                        ?.trim()
                                        .isNotEmpty ==
                                    true
                                ? data['companyName'] as String
                                : 'Company';
                            final viewedAt = data['viewedAt'] as Timestamp?;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFDCE3F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF1565C0)
                                        .withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.business,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          companyName,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Viewed on ${_fmtDate(viewedAt)}',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
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
            ),
    );
  }
}
