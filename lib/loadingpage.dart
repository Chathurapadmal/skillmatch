import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Navigate to next screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/auth');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1565C0), // deep blue
              Color(0xFF42A5F5), // light blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App name
                  const Text(
                    "skillMATCH",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tagline
                  const Text(
                    "From CV to Career",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 40),

                  // Loading indicator
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
