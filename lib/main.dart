import 'package:flutter/material.dart';
import 'loadingpage.dart';

void main() {
  runApp(const SkillMatchApp());
}

class SkillMatchApp extends StatelessWidget {
  const SkillMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) =>
            const Scaffold(body: Center(child: Text("Onboarding Screen"))),
      },
    );
  }
}
