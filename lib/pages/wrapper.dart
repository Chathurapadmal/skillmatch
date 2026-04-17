import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth/login_page.dart';
import 'navigation.dart';

/// Root widget that listens to auth-state AND Firestore role changes.
/// Automatically routes to the correct screen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (AuthService.isDevelopmentAuthBypassEnabled) {
      return const _DevBypassWrapper();
    }

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

            // 2FA/email-verification gates are disabled temporarily.
            return MainNavigationPage(user: userModel);
          },
        );
      },
    );
  }
}

class _DevBypassWrapper extends StatefulWidget {
  const _DevBypassWrapper();

  @override
  State<_DevBypassWrapper> createState() => _DevBypassWrapperState();
}

class _DevBypassWrapperState extends State<_DevBypassWrapper> {
  late final Future<UserModel> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _buildDevUser();
  }

  Future<UserModel> _buildDevUser() async {
    final firebaseUser = await AuthService.ensureDevSession();
    AuthService.totpSessionVerified.value = true;

    return UserModel(
      uid: firebaseUser?.uid ?? 'dev-user',
      email: firebaseUser?.email ?? 'dev@skillmatch.local',
      displayName: firebaseUser?.displayName ?? 'Developer',
      role: UserRole.admin,
      emailVerified: true,
      twoFactorEnabled: true,
      profileCompleted: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      future: _bootstrapFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _LoadingScreen(message: 'Starting developer mode…');
        }

        if (snap.hasError || snap.data == null) {
          return const _LoadingScreen(
            message: 'Developer mode failed to initialize.',
          );
        }

        return MainNavigationPage(user: snap.data!);
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
