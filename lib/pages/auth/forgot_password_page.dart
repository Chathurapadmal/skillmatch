import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await AuthService.sendPasswordResetEmail(_emailCtrl.text);
      if (!mounted) return;
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4052B6),
                  Color(0xFF652FE7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),


          Positioned(
            top: -80,
            right: -60,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF652FE7).withOpacity(0.3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF652FE7),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // 🔙 Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      const SizedBox(height: 20),

                  
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(26),
                              child: _sent ? _successBody() : _formBody(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formBody() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
    
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Enter your email and we will send a reset link.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 24),

  
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onFieldSubmitted: (_) => _send(),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: Colors.black87),
              prefixIcon:
                  const Icon(Icons.alternate_email_rounded),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) {
              final e = v?.trim() ?? '';
              if (e.isEmpty || !e.contains('@')) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          
          GestureDetector(
            onTap: _loading ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4052B6),
                    Color(0xFF652FE7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF652FE7)
                        .withOpacity(0.6),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 64, color: Colors.green),

        const SizedBox(height: 20),

        const Text(
          'Email Sent!',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),

        const SizedBox(height: 8),

        Text(
          'Check your inbox at ${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white70, fontSize: 13),
        ),

        const SizedBox(height: 24),

        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4052B6),
                  Color(0xFF652FE7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}