import 'package:flutter/material.dart';
import 'package:skillmatch/student/profile/profilepage.dart';

import '../admin/admin_dashboard.dart';
import './dashboard_tab.dart';
import '../models/user_model.dart';
import 'applicant/applicant_dashboard.dart';
import 'applicant/upload_cv_page.dart';
import 'company/company_dashboard.dart';

class MainNavigationPage extends StatefulWidget {
  final UserModel user;

  const MainNavigationPage({super.key, required this.user});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  List<_NavPage> get _pages {
    final role = widget.user.role;

    final commonPages = <_NavPage>[
      _NavPage(
        label: 'Home',
        icon: Icons.home_rounded,
        page: const DashboardTab(),
      ),
      _NavPage(
        label: 'Profile',
        icon: Icons.person_rounded,
        page: const ProfilePage(),
      ),
      _NavPage(
        label: 'Upload CV',
        icon: Icons.upload_file_rounded,
        page: const UploadCvPage(returnResultOnExtract: false),
      ),
    ];

    switch (role) {
      case UserRole.admin:
        return [
          _NavPage(
            label: 'Overview',
            icon: Icons.dashboard_rounded,
            page: AdminDashboard(
              user: widget.user,
              showInternalNavigation: false,
              initialTabIndex: 0,
            ),
          ),
          _NavPage(
            label: 'Users',
            icon: Icons.people_rounded,
            page: AdminDashboard(
              user: widget.user,
              showInternalNavigation: false,
              initialTabIndex: 1,
            ),
          ),
          ...commonPages,
        ];
      case UserRole.company:
        return [
          _NavPage(
            label: 'Dashboard',
            icon: Icons.business_center_rounded,
            page: CompanyDashboard(user: widget.user),
          ),
          ...commonPages,
        ];
      case UserRole.applicant:
        return [
          _NavPage(
            label: 'Dashboard',
            icon: Icons.space_dashboard_rounded,
            page: ApplicantDashboard(user: widget.user),
          ),
          ...commonPages,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages.map((entry) => entry.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: pages
            .map(
              (entry) => NavigationDestination(
                icon: Icon(entry.icon),
                label: entry.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavPage {
  final String label;
  final IconData icon;
  final Widget page;

  const _NavPage({required this.label, required this.icon, required this.page});
}
