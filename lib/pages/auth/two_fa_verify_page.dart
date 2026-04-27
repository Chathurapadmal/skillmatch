import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/backup_code_service.dart';
import '../../services/firestore_user_service.dart';
import '../../services/totp_service.dart';

const Color _primary = Color(0xFF1565C0);
const Color _navy = Color(0xFF1E3A5F);
const Color _accent = Color(0xFF2E86AB);

// ─────────────────────────────────────────────────────────────────────────────
// TwoFAVerifyPage
// ─────────────────────────────────────────────────────────────────────────────
//
// Shown on every login for accounts where twoFactorEnabled = true.
// Asks for the current 6-digit TOTP code from the authenticator app.
// Also allows recovery using a one-time backup code.
//
// On success:
//   - Sets AuthService.totpSessionVerified.value = true
//   - AuthWrapper's ValueListenableBuilder sees the change and rebuilds,
//     routing to MainNavigationPage automatically.
//
// TODO (production): Replace verifyCode() with a backend API call and
//   never read the secret from Firestore on the client.

class TwoFAVerifyPage extends StatefulWidget {
  final UserModel user;

  const TwoFAVerifyPage({super.key, required this.user});

  @override
  State<TwoFAVerifyPage> createState() => _TwoFAVerifyPageState();
}

class _TwoFAVerifyPageState extends State<TwoFAVerifyPage> {
  final _codeCtrl = TextEditingController();
  final _backupCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _backupFormKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _useBackup = false; // toggle between TOTP and backup-code mode

  @override
  void dispose() {
    _codeCtrl.dispose();
    _backupCtrl.dispose();
    super.dispose();
  }

  // ── Verify 6-digit TOTP code ──────────────────────────────────────────────
  Future<void> _verifyTotp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      // Read secret from local secure storage first; fall back to Firestore
      // (demo only – in production the secret lives exclusively on the backend).
      // TODO (production): Replace with backend verification API call.
      String? secret = await TotpService.readSecretLocally();
      secret ??= widget.user.totpSecret;

      if (secret == null || secret.isEmpty) {
        _showSnack('TOTP secret not found. Please re-setup 2FA.');
        return;
      }

      final valid = TotpService.verifyCode(secret, _codeCtrl.text.trim());
      if (!valid) {
        if (!mounted) return;
        _showSnack('Incorrect code. Please check your authenticator app.');
        return;
      }

      AuthService.totpSessionVerified.value = true;
      // AuthWrapper rebuilds automatically — no manual navigation needed.
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Verify backup / recovery code ─────────────────────────────────────────
  Future<void> _verifyBackupCode() async {
    if (!_backupFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final idx = BackupCodeService.verifyCode(
        _backupCtrl.text.trim(),
        widget.user.backupCodesHash,
      );

      if (idx == -1) {
        if (!mounted) return;
        _showSnack('Invalid backup code.');
        return;
      }

      // Invalidate used backup code in Firestore
      await FirestoreUserService.consumeBackupCode(widget.user.uid, idx);

      AuthService.totpSessionVerified.value = true;
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(''),
        backgroundColor: _navy,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _navy,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_navy, _primary, _accent],
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
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phonelink_lock_rounded,
                            size: 36,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          '2-Step Verification',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        Text(
                          _useBackup
                              ? 'Enter one of your backup recovery codes.'
                              : 'Open your authenticator app and enter the 6-digit code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── TOTP mode ───────────────────────────────────────
                        if (!_useBackup)
                          Form(
                            key: _formKey,
                            child: TextFormField(
                              controller: _codeCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 28,
                                letterSpacing: 12,
                                fontWeight: FontWeight.bold,
                                color: _navy,
                              ),
                              decoration: const InputDecoration(
                                hintText: '000000',
                                counterText: '',
                                border: OutlineInputBorder(),
                                labelText: 'Authenticator Code',
                              ),
                              validator: (v) {
                                final c = v?.trim() ?? '';
                                if (c.length != 6 || int.tryParse(c) == null) {
                                  return 'Enter the 6-digit code.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _verifyTotp(),
                            ),
                          ),

                        // ── Backup code mode ────────────────────────────────
                        if (_useBackup)
                          Form(
                            key: _backupFormKey,
                            child: TextFormField(
                              controller: _backupCtrl,
                              keyboardType: TextInputType.text,
                              autocorrect: false,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                letterSpacing: 3,
                                fontFamily: 'monospace',
                                color: _navy,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'XXXXX-XXXXX',
                                border: OutlineInputBorder(),
                                labelText: 'Backup Recovery Code',
                              ),
                              validator: (v) {
                                if ((v?.trim().length ?? 0) < 5) {
                                  return 'Enter a valid backup code.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _verifyBackupCode(),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Verify button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loading
                                ? null
                                : (_useBackup
                                    ? _verifyBackupCode
                                    : _verifyTotp),
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
                                    'Verify',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Toggle TOTP ↔ backup code
                        TextButton(
                          onPressed: () {
                            _codeCtrl.clear();
                            _backupCtrl.clear();
                            setState(() => _useBackup = !_useBackup);
                          },
                          child: Text(
                            _useBackup
                                ? 'Use authenticator code instead'
                                : "Don't have your phone? Use a backup code",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Sign out
                        TextButton(
                          onPressed: () => AuthService.signOut(),
                          child: const Text(
                            'Sign out',
                            style: TextStyle(color: Colors.grey),
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
      ),
    );
  }
}