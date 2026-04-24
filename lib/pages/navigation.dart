import 'package:flutter/material.dart';
import 'package:skillmatch/pages/dashboard_tab.dart';
import 'package:skillmatch/pages/applicant/profile/profilepage.dart';
import 'package:skillmatch/pages/applicant/home/home_screen.dart';

import '../admin/admin_dashboard.dart';
import '../models/user_model.dart';
import 'applicant/jobs/browse_jobs_page.dart';
import 'applicant/applicant_dashboard.dart';
import 'applicant/home/home_screen.dart';
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
        label: 'Profile',
        icon: Icons.person_rounded,
        page: const ProfilePage(),
      ),
      _NavPage(
        label: 'Upload CV',
        icon: Icons.cloud_upload_rounded,
        page: const UploadCvPage(returnResultOnExtract: false),
      ),
    ];

    switch (role) {
      case UserRole.admin:
        return [
          _NavPage(
            label: 'Dashboard',
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
          _NavPage(
            label: 'Home',
            icon: Icons.home_rounded,
            page: const DashboardTab(),
          ),
          ...commonPages,
        ];

      case UserRole.company:
        return [];

      case UserRole.applicant:
        return [
          _NavPage(
            label: 'Dashboard',
            icon: Icons.space_dashboard_rounded,
            page: ApplicantDashboard(user: widget.user),
          ),
          _NavPage(
            label: 'Browse Jobs',
            icon: Icons.search_rounded,
            page: const BrowseJobsPage(),
          ),
          _NavPage(
            label: 'Applications', // 🔥 FIXED (was My Applications)
            icon: Icons.assignment_rounded,
            page: const HomeScreen(initialTabIndex: 2),
          ),
          _NavPage(
            label: 'Upload CV',
            icon: Icons.cloud_upload_rounded,
            page: const UploadCvPage(returnResultOnExtract: false),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user.role;

    if (role == UserRole.company) {
      return CompanyDashboard(user: widget.user);
    }

    final pages = _pages;

    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages.map((entry) => entry.page).toList(),
      ),

      // 🔥 FIXED CUSTOM NAV BAR
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: List.generate(pages.length, (index) {
              final item = pages[index];
              final isSelected = _selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center, // ✅ FIXED
                    children: [
                      Icon(
                        item.icon,
                        color:
                            isSelected ? const Color(0xFF6C63FF) : Colors.grey,
                        size: isSelected ? 26 : 24,
                      ),
                      const SizedBox(height: 4),

                      // ✅ PERFECT CENTER ALIGNMENT
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF6C63FF)
                                : Colors.grey,
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavPage {
  final String label;
  final IconData icon;
  final Widget page;

  const _NavPage({
    required this.label,
    required this.icon,
    required this.page,
  });
}
