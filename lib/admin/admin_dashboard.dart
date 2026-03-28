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

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Admin Panel",
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
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

        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF7B61FF),
          child: const Icon(Icons.auto_awesome),
          onPressed: () {},
        ),

        bottomNavigationBar: widget.showInternalNavigation
            ? NavigationBar(
                selectedIndex: _selectedIndex,
                indicatorColor:
                    const Color(0xFF7B61FF).withOpacity(0.15),
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


/// OVERVIEW TAB


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
          /// Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5F2EEA), Color(0xFF7B61FF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Full access — manage users, roles, and platform data",
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
                  _CountCard(label: "Total Users", count: total, icon: Icons.people),
                  _CountCard(label: "Applicants", count: applicants, icon: Icons.person),
                  _CountCard(label: "Companies", count: companies, icon: Icons.business),
                  _CountCard(label: "Admins", count: admins, icon: Icons.admin_panel_settings),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}


/// USERS TAB


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
        /// Search
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search by name, email or role...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) =>
                setState(() => _search = v.toLowerCase()),
          ),
        ),

        /// List
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


/// USER TILE


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
                  ? Colors.purple.shade100
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
                    ? Colors.purple
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


/// COUNT CARD


class _CountCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            "$count",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}


/// NAV ITEM


class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}