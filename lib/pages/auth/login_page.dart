import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _remember = false;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await AuthService.login(
          email: _emailCtrl.text, password: _passCtrl.text);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(AuthService.friendlyError(e));
    } catch (_) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF5000D2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
        
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4052B6), Color(0xFF652FE7)],
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
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                    
                          TweenAnimationBuilder(
                            tween: Tween(begin: 0.9, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                  scale: scale, child: child);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4052B6),
                                    Color(0xFF652FE7)
                                  ],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF652FE7),
                                    blurRadius: 20,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.work_rounded,
                                  size: 48, color: Colors.white),
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'SkillMatch',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'Connect talent with opportunity',
                            style: TextStyle(color: Colors.white70),
                          ),

                          const SizedBox(height: 36),

                        
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
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Text(
                                          'Welcome back',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),

                                        const SizedBox(height: 22),

                                        _modernField(
                                          controller: _emailCtrl,
                                          label: 'Email',
                                          icon: Icons.mail_outline_rounded,
                                        ),

                                        const SizedBox(height: 16),

                                        _modernField(
                                          controller: _passCtrl,
                                          label: 'Password',
                                          icon: Icons.lock_rounded,
                                          obscure: _obscurePass,
                                          suffix: IconButton(
                                            icon: Icon(
                                              _obscurePass
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: Colors.black54,
                                            ),
                                            onPressed: () => setState(() =>
                                                _obscurePass =
                                                    !_obscurePass),
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                    
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: _remember,
                                                  onChanged: (v) =>
                                                      setState(() =>
                                                          _remember = v ?? false),
                                                ),
                                                const Text(
                                                  'Remember me',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                            InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              splashColor: Colors.white24,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const ForgotPasswordPage(),
                                                  ),
                                                );
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 4),
                                                child: Text(
                                                  'Forgot Password?',
                                                  style: TextStyle(
                                                    color: Color.fromARGB(255, 2, 61, 74),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 18),

                                    
                                        GestureDetector(
                                          onTap:
                                              _loading ? null : _login,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            height: 52,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF4052B6),
                                                  Color(0xFF652FE7),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF652FE7)
                                                      .withOpacity(0.7),
                                                  blurRadius: 30,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: _loading
                                                  ? const CircularProgressIndicator(
                                                      color: Colors.white)
                                                  : const Text(
                                                      'Login',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 18),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "Don't have an account? ",
                                              style:
                                                  TextStyle(color: Colors.white70),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const RegisterPage(),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Register',
                                                style: TextStyle(
                                                  color: Color.fromARGB(255, 2, 61, 74),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4052B6)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) {
        if (label == 'Email') {
          final e = v?.trim() ?? '';
          if (e.isEmpty || !e.contains('@')) {
            return 'Enter a valid email.';
          }
        } else {
          if ((v?.length ?? 0) < 6) {
            return 'Password must be at least 6 characters.';
          }
        }
        return null;
      },
    );
  }
}