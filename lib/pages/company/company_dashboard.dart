import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../shared/chat_overlay.dart';
import '../../shared/notifications_center_screen.dart';
import '../../shared/supabase_storage_page.dart';
import '../../theme/app_theme.dart';

part 'company_dashboard_overview_candidate.part.dart';
part 'company_dashboard_management_settings.part.dart';
part 'company_dashboard_dialogs_misc.part.dart';

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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
          title: Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF2E86AB)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
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
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.15),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
                selectedIcon:
                    Icon(Icons.work_rounded, color: Color(0xFF1565C0)),
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
      ),
    );
  }
}
