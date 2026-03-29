import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'pages/wrapper.dart';

bool get _supportsFirebaseOnCurrentPlatform {
  if (kIsWeb) return true;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return true;
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!_supportsFirebaseOnCurrentPlatform) {
    runApp(
      const SkillMatchApp(
        startupMessage:
            'Firebase is not supported on this platform. Use Android, iOS, Web, macOS, or Windows.',
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: 'https://bmliitwxgkgrdpeyeiqu.supabase.co',
      anonKey: 'sb_publishable_zSJsdNSg9LaGimkRl9uzeg_5LCG8qns',
    );

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable App Check only for release builds.
    // In debug/dev, skip attestation to avoid 403 failures.
    if (kReleaseMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
    }

    runApp(const SkillMatchApp());
  } catch (e) {
    runApp(SkillMatchApp(startupMessage: 'Firebase init error:\n$e'));
  }
}

class SkillMatchApp extends StatelessWidget {
  final String? startupMessage;

  const SkillMatchApp({super.key, this.startupMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillMatch',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
      ),
      home: startupMessage != null
          ? _ErrorScreen(message: startupMessage!)
          : const AuthWrapper(),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

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
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 60),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
