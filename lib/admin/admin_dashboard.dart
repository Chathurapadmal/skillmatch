import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skillmatch/student/profile/profilepage.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../shared/chat_overlay.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;
  final bool showInternalNavigation;
  final int initialTabIndex;

  const AdminDashboard({
    super.key,
    required this.user,
    this.showInternalNavigation = true,
    this.initialTabIndex = 0,
  });

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
  void initState() {
    super.initState();
    final maxIndex = _navItems.length - 1;
    _selectedIndex = widget.initialTabIndex.clamp(0, maxIndex);
  }

  @override
  Widget build(BuildContext context) {
    return ChatOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),

        /// 🔥 PREMIUM APPBAR
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5F2EEA), Color(0xFF7B61FF)],
              ),
            ),
          ),
          title: const Text(
            "Admin Panel",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF7B61FF)),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                }
                if (value == 'signout') await AuthService.signOut();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'profile', child: Text("My Profile")),
                PopupMenuItem(value: 'signout', child: Text("Sign Out")),
              ],
            )
          ],
        ),

        /// ✨ FAB
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF7B61FF),
          elevation: 8,
          child: const Icon(Icons.auto_awesome),
          onPressed: () {},
        ),

        /// 🧭 NAVBAR
        bottomNavigationBar: widget.showInternalNavigation
            ? NavigationBar(
                selectedIndex: _selectedIndex,
                indicatorColor:
                    const Color(0xFF7B61FF).withOpacity(0.2),
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (i) =>
                    setState(() => _selectedIndex = i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_rounded),
                    label: "Overview",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_rounded),
                    label: "Users",
                  ),
                ],
              )
            : null,

        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _OverviewTab(adminUser: widget.user),
            const _UsersTab(),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// OVERVIEW TAB
////////////////////////////////////////////////////////////

class _OverviewTab extends StatelessWidget {
  final UserModel adminUser;

  const _OverviewTab({required this.adminUser});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🎉 PREMIUM BANNER
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5F2EEA), Color(0xFF7B61FF)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, Admin 👋",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Manage users, roles, and system analytics",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Platform Overview",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          /// 📊 COUNTS
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snap) {
              int total = 0, applicants = 0, companies = 0, admins = 0;

              if (snap.hasData) {
                for (final doc in snap.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  total++;
                  switch (d['role']) {
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
                children: [
                  _CountCard("Total Users", total, Icons.people, Colors.deepPurple),
                  _CountCard("Applicants", applicants, Icons.person, Colors.teal),
                  _CountCard("Companies", companies, Icons.business, Colors.blue),
                  _CountCard("Admins", admins, Icons.admin_panel_settings, Colors.orange),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// USERS TAB
////////////////////////////////////////////////////////////

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _search = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔍 SEARCH
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search users...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (v) =>
                setState(() => _search = v.toLowerCase()),
          ),
        ),

        /// 👥 USER LIST
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs.where((doc) {
                if (_search.isEmpty) return true;
                final d = doc.data() as Map<String, dynamic>;
                final name = (d['displayName'] ?? "").toLowerCase();
                final email = (d['email'] ?? "").toLowerCase();
                return name.contains(_search) ||
                    email.contains(_search);
              }).toList();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d =
                      docs[i].data() as Map<String, dynamic>;

                  return _UserTile(
                    name: d['displayName'] ?? "",
                    email: d['email'] ?? "",
                    role: d['role'] ?? "applicant",
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////
/// USER TILE
////////////////////////////////////////////////////////////

class _UserTile extends StatelessWidget {
  final String name;
  final String email;
  final String role;

  const _UserTile({
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: Text(name.isNotEmpty ? name[0] : "?"),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: role == 'admin'
                  ? Colors.deepPurple.shade100
                  : role == 'company'
                      ? Colors.blue.shade100
                      : Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: role == 'admin'
                    ? Colors.deepPurple
                    : role == 'company'
                        ? Colors.blue
                        : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// COUNT CARD
////////////////////////////////////////////////////////////

class _CountCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _CountCard(this.label, this.count, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// NAV ITEM
////////////////////////////////////////////////////////////

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}