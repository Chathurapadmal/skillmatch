import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  static const List<String> _industryOptions = [
    'IT & Software',
    'Business & Management',
    'Design & UX/UI',
    'Engineering',
    'Healthcare',
    'Other',
  ];

  UserRole _selectedRole = UserRole.applicant;
  String _selectedIndustry = _industryOptions.first;
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await AuthService.register(
        email: _emailCtrl.text,
        password: _passCtrl.text,
        displayName: _nameCtrl.text,
        role: _selectedRole,
        companyName:
            _selectedRole == UserRole.company ? _companyCtrl.text : null,
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'industry': _selectedIndustry,
          'field': _selectedIndustry,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      // Navigation handled by AuthWrapper
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(AuthService.friendlyError(e));
    } catch (e) {
      if (!mounted) return;
      _showError('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    const Icon(Icons.work_rounded,
                        size: 64, color: Colors.white),
                    const SizedBox(height: 8),
                    const Text(
                      'SkillMatch',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Card ───────────────────────────────────────────────
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Role selector ──────────────────────────
                              const Text(
                                'I am registering as:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RoleTile(
                                      label: 'Applicant',
                                      icon: Icons.person_search_rounded,
                                      subtitle: 'Find your dream job',
                                      selected:
                                          _selectedRole == UserRole.applicant,
                                      onTap: () => setState(() =>
                                          _selectedRole = UserRole.applicant),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RoleTile(
                                      label: 'Company',
                                      icon: Icons.business_rounded,
                                      subtitle: 'Hire top talent',
                                      selected:
                                          _selectedRole == UserRole.company,
                                      onTap: () => setState(() =>
                                          _selectedRole = UserRole.company),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Full name
                              TextFormField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  label: _selectedRole == UserRole.company
                                      ? 'Contact Person Name'
                                      : 'Full Name',
                                  icon: Icons.person_outline,
                                ),
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? 'Name is required.'
                                    : null,
                              ),
                              const SizedBox(height: 14),

                              // Company name (only for company role)
                              if (_selectedRole == UserRole.company) ...[
                                TextFormField(
                                  controller: _companyCtrl,
                                  textInputAction: TextInputAction.next,
                                  decoration: _inputDecoration(
                                    label: 'Company Name',
                                    icon: Icons.business_outlined,
                                  ),
                                  validator: (v) => (v?.trim().isEmpty ?? true)
                                      ? 'Company name is required.'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                              ],

                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Set Professional Field',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _IndustrySelectorTile(
                                selectedValue: _selectedIndustry,
                                onTap: () async {
                                  final selected =
                                      await showModalBottomSheet<String>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: const Color(0xFF161A3A),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (_) => _IndustryPickerSheet(
                                      title: 'Set Professional Field',
                                      options: _industryOptions,
                                      selectedValue: _selectedIndustry,
                                    ),
                                  );

                                  if (selected != null && mounted) {
                                    setState(
                                        () => _selectedIndustry = selected);
                                  }
                                },
                              ),
                              const SizedBox(height: 14),

                              // Email
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (v) {
                                  final e = v?.trim() ?? '';
                                  if (e.isEmpty || !e.contains('@')) {
                                    return 'Enter a valid email.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Password
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscurePass,
                                textInputAction: TextInputAction.next,
                                decoration: _inputDecoration(
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePass
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                  ),
                                ),
                                validator: (v) {
                                  if ((v?.length ?? 0) < 6) {
                                    return 'Password must be at least 6 characters.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Confirm password
                              TextFormField(
                                controller: _confirmCtrl,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _register(),
                                decoration: _inputDecoration(
                                  label: 'Confirm Password',
                                  icon: Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) {
                                  if (v != _passCtrl.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Register button
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1565C0),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _loading ? null : _register,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Login link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Already have an account? '),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Color(0xFF1565C0),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}

// ── Role selector tile ────────────────────────────────────────────────────────
class _RoleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1565C0) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 30,
                color: selected ? Colors.white : Colors.grey.shade600),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white70 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndustrySelectorTile extends StatelessWidget {
  final String selectedValue;
  final VoidCallback onTap;

  const _IndustrySelectorTile({
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.business_center_outlined,
                color: Color(0xFF1565C0), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedValue,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _IndustryPickerSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String selectedValue;

  const _IndustryPickerSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  @override
  State<_IndustryPickerSheet> createState() => _IndustryPickerSheetState();
}

class _IndustryPickerSheetState extends State<_IndustryPickerSheet> {
  late String _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ...widget.options.map((option) {
              return RadioListTile<String>(
                dense: true,
                value: option,
                groupValue: _localSelected,
                activeColor: const Color(0xFF5B5BFF),
                title: Text(
                  option,
                  style:
                      const TextStyle(color: Color(0xFFD1D4EA), fontSize: 16),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _localSelected = value);
                  Navigator.pop(context, value);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
