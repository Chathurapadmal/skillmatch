import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth/login_page.dart';
import 'auth/email_verification_page.dart';
import 'auth/two_fa_setup_page.dart';
import 'auth/two_fa_verify_page.dart';
import 'main_navigation_page.dart';

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
            return ValueListenableBuilder<bool>(
              valueListenable: AuthService.totpSessionVerified,
              builder: (context, totpVerified, _) {
                // 1. Email must be verified first (release only)
                if (kReleaseMode && !userModel.emailVerified) {
                  return const EmailVerificationPage();
                }
                // 2. 2FA must be set up
                if (!userModel.twoFactorEnabled) {
                  return TwoFASetupPage(user: userModel);
                }
                // 3. Must pass 2FA verification for this session
                if (!totpVerified) {
                  return TwoFAVerifyPage(user: userModel);
                }
                // 4. Fully authenticated — route to main app
                return MainNavigationPage(user: userModel);
              },
            );
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
