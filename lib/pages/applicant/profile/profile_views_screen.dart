import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class ProfileViewsScreen extends StatelessWidget {
  const ProfileViewsScreen({super.key});

  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _background = Color(0xFFF5F7FA);
  static const Color _cardBorder = Color(0xFFDCE3F0);

  String _fmtDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 24 && difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    }
    if (difference.inDays == 1) return 'yesterday';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _background,
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

                    return SafeArea(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildHeader(context, totalViews),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                _buildSection(
                                  title: 'Quick Insights',
                                  subtitle:
                                      'A snapshot of how your profile is performing.',
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildInsightCard(
                                          'Growth',
                                          '33% Increase',
                                          Icons.trending_up,
                                          Colors.orange.shade100,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildInsightCard(
                                          'Top Industry',
                                          'FinTech',
                                          Icons.business_center,
                                          Colors.blueGrey.shade100,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildHistorySection(views),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context, int totalViews) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildHeaderIconButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              const Text(
                'Profile Views',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 42), // Replaced the more_vert icon with an empty box to maintain exact centering
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PROFILE VIEWS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalViews',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '+4 this week',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                  ),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSectionTitle(
                  title: title,
                  subtitle: subtitle,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF172033),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> views,
  ) {
    return _buildSection(
      title: 'View History',
      subtitle: 'Companies that recently viewed your profile.',
      child: views.isEmpty
          ? _buildEmptyState()
          : Column(
              children: views
                  .map((doc) => _buildHistoryItem(doc.data()))
                  .toList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.visibility_off_outlined,
            color: Colors.grey,
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            'No company has viewed your profile yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> data) {
    final companyName = (data['companyName'] as String?) ?? 'Company';
    final viewedAt = data['viewedAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.business,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Viewed ${_fmtDate(viewedAt)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8EEF7)),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _primary,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Network',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }
}