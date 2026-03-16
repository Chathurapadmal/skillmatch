import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth/login_page.dart';
import 'applicant/applicant_dashboard.dart';
import 'company/company_dashboard.dart';
import '../admin/admin_dashboard.dart';

/// Root widget that listens to auth-state AND Firestore role changes.
/// Automatically routes to the correct screen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, authSnap) {
        // ── Still waiting for auth state ───────────────────────────────────
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // ── Not logged in → show login ─────────────────────────────────────
        final user = authSnap.data;
        if (user == null) {
          return const LoginPage();
        }

        // ── Logged in → listen for role changes in Firestore ──────────────
        return StreamBuilder<UserModel?>(
          stream: AuthService.userModelStream(user.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final userModel = userSnap.data;

            // Firestore doc not yet created / missing
            if (userModel == null) {
              return const _LoadingScreen(message: 'Setting up your account…');
            }

            // ── Route by role ──────────────────────────────────────────────
            switch (userModel.role) {
              case UserRole.admin:
                return AdminDashboard(user: userModel);
              case UserRole.company:
                return CompanyDashboard(user: userModel);
              case UserRole.applicant:
                return ApplicantDashboard(user: userModel);
            }
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({this.message = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
