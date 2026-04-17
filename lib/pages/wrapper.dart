import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/auth_gate_controller.dart';
import 'auth/login_page.dart';
import 'navigation.dart';

/// Root widget that listens to auth-state AND Firestore role changes.
/// Automatically routes to the correct screen.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AuthGateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthGateController()..start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService.isDevelopmentAuthBypassEnabled) {
      return const _DevBypassWrapper();
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        switch (_controller.stage) {
          case AuthGateStage.checkingAuth:
          case AuthGateStage.loadingProfile:
            return const _LoadingScreen(
              message: 'Setting up your account…',
            );

          case AuthGateStage.unauthenticated:
            return const LoginPage();

          case AuthGateStage.authenticated:
            final model = _controller.userModel;
            if (model == null) {
              return const _LoadingScreen(message: 'Loading your profile…');
            }
            return MainNavigationPage(user: model);

          case AuthGateStage.permissionDenied:
            return const _AuthDataErrorScreen(
              title: 'Firestore access denied',
              message:
                  'Your account is signed in, but Firestore rules are blocking user profile access.',
            );

          case AuthGateStage.error:
            return _AuthDataErrorScreen(
              title: 'Unable to load account data',
              message: _controller.errorMessage ??
                  'An unknown error occurred while loading account data.',
            );
        }
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

class _AuthDataErrorScreen extends StatelessWidget {
  final String title;
  final String message;

  const _AuthDataErrorScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 54, color: Colors.red),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await AuthService.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
