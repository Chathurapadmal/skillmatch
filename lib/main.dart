import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'home_page.dart';
import 'profilepage.dart';
import 'auth_page.dart';
import 'loadingpage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const SkillMatchApp());
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text('Firebase Init Error:\n$e'),
          ),
        ),
      ),
    );
  }
}

class SkillMatchApp extends StatelessWidget {
  const SkillMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ START DIRECTLY AT HOME PAGE
      home: const DashboardTab(),

      // Keep routes for later navigation
      routes: {
        '/home': (context) => const DashboardTab(),
        '/profile': (context) => const ProfilePage(),
        '/auth': (context) => const AuthPage(),
        '/splash': (context) => const SplashScreen(),
      },
    );
  }
}