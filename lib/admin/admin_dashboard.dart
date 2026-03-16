import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../profilepage.dart';
import '../services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Overview'),
    _NavItem(icon: Icons.people_rounded, label: 'Users'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.amber,
              child: Icon(Icons.person, color: Color(0xFF1A237E), size: 18),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
                return;
              }
              if (value == 'signout') await AuthService.signOut();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.user.email,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    const Text('Administrator',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A237E).withValues(alpha: 0.12),
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _navItems
            .map((n) => NavigationDestination(
                  icon: Icon(n.icon),
                  label: n.label,
                ))
            .toList(),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _OverviewTab(adminUser: widget.user),
          const _UsersTab(),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final UserModel adminUser;

  const _OverviewTab({required this.adminUser});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.amber, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Welcome, ${adminUser.displayName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Full access — manage users, roles, and platform data.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Live user counts from Firestore
          const Text(
            'Platform Overview',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, snap) {
              int total = 0, applicants = 0, companies = 0, admins = 0;

              if (snap.hasData) {
                for (final doc in snap.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  total++;
                  switch (d['role'] as String?) {
                    case 'company':
                      companies++;
                      break;
                    case 'admin':
                      admins++;
                      break;
                    default:
                      applicants++;
                  }
                }
              }

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _CountCard(
                    label: 'Total Users',
                    count: total,
                    icon: Icons.people_rounded,
                    color: const Color(0xFF1A237E),
                  ),
                  _CountCard(
                    label: 'Applicants',
                    count: applicants,
                    icon: Icons.person_search_rounded,
                    color: Colors.teal,
                  ),
                  _CountCard(
                    label: 'Companies',
                    count: companies,
                    icon: Icons.business_rounded,
                    color: Colors.blue,
                  ),
                  _CountCard(
                    label: 'Admins',
                    count: admins,
                    icon: Icons.shield_rounded,
                    color: Colors.amber.shade700,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Users Tab ─────────────────────────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search users…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase().trim()),
          ),
        ),

        // User list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Center(child: Text('No users found.'));
              }

              final docs = snap.data!.docs.where((doc) {
                if (_search.isEmpty) return true;
                final d = doc.data() as Map<String, dynamic>;
                final email = (d['email'] as String? ?? '').toLowerCase();
                final name =
                    (d['displayName'] as String? ?? '').toLowerCase();
                return email.contains(_search) || name.contains(_search);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text('No matching users.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data() as Map<String, dynamic>;
                  final role = d['role'] as String? ?? 'applicant';
                  final name = d['displayName'] as String? ?? 'Unknown';
                  final email = d['email'] as String? ?? '';
                  final company = d['companyName'] as String?;

                  return _UserTile(
                    uid: doc.id,
                    name: name,
                    email: email,
                    role: role,
                    companyName: company,
                    onRoleChange: (newRole) =>
                        _changeRole(doc.id, newRole),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _changeRole(String uid, String newRole) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'role': newRole});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Role updated to "$newRole"'),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }
}

// ── User Tile ─────────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? companyName;
  final void Function(String) onRoleChange;

  const _UserTile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.companyName,
    required this.onRoleChange,
  });

  static const _roles = ['applicant', 'company', 'admin'];

  Color get _roleColor {
    switch (role) {
      case 'admin':
        return Colors.amber.shade700;
      case 'company':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  IconData get _roleIcon {
    switch (role) {
      case 'admin':
        return Icons.shield_rounded;
      case 'company':
        return Icons.business_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: _roleColor.withValues(alpha: 0.15),
            child: Icon(_roleIcon, color: _roleColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(email,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                if (companyName != null)
                  Text(companyName!,
                      style: TextStyle(
                          color: Colors.blue.shade600, fontSize: 11)),
              ],
            ),
          ),

          // Role dropdown
          PopupMenuButton<String>(
            tooltip: 'Change role',
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    role,
                    style: TextStyle(
                        color: _roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down,
                      color: _roleColor, size: 16),
                ],
              ),
            ),
            onSelected: onRoleChange,
            itemBuilder: (_) => _roles
                .map(
                  (r) => PopupMenuItem(
                    value: r,
                    child: Row(children: [
                      Icon(
                        r == 'admin'
                            ? Icons.shield_rounded
                            : r == 'company'
                                ? Icons.business_rounded
                                : Icons.person_rounded,
                        size: 18,
                        color: r == 'admin'
                            ? Colors.amber.shade700
                            : r == 'company'
                                ? Colors.blue
                                : Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      Text(r,
                          style: TextStyle(
                              fontWeight: role == r
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ]),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _CountCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
