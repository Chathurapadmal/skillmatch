import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/backup_code_service.dart';
import '../../services/firestore_user_service.dart';
import '../../services/totp_service.dart';


class TwoFASetupPage extends StatefulWidget {
  final UserModel user;

  const TwoFASetupPage({super.key, required this.user});

  @override
  State<TwoFASetupPage> createState() => _TwoFASetupPageState();
}

class _TwoFASetupPageState extends State<TwoFASetupPage> {
  // TOTP secret (generated once and reused)
  late final String _secret;
  late final String _otpauthUrl;

  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _verifying = false;
  bool _secretVisible = false;
  bool _done = false; // true once verified; shows backup codes
  List<String> _backupCodes = [];

  @override
  void initState() {
    super.initState();
    _secret = widget.user.totpSecret?.isNotEmpty == true
        ? widget.user.totpSecret!
        : TotpService.generateSecret();

    _otpauthUrl = TotpService.buildOtpauthUrl(
      email: widget.user.email,
      secret: _secret,
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);

    try {
      final valid = TotpService.verifyCode(_secret, _codeCtrl.text.trim());

      if (!valid) {
        if (!mounted) return;
        _showSnack('Incorrect code. Try again.');
        return;
      }

      // Generate backup codes
      final plainCodes = BackupCodeService.generateCodes();
      final hashedCodes = BackupCodeService.hashCodes(plainCodes);

      // Persist to Firestore and Secure Storage
      await Future.wait([
        FirestoreUserService.enableTwoFactor(
          uid: widget.user.uid,
          totpSecret: _secret, // TODO (production): remove from Firestore
          backupCodesHash: hashedCodes,
        ),
        TotpService.saveSecretLocally(_secret),
      ]);

      // Mark TOTP verified for this session so AuthWrapper skips the challenge
      AuthService.totpSessionVerified.value = true;

      if (!mounted) return;
      setState(() {
        _done = true;
        _backupCodes = plainCodes;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
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
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
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
                child: _done ? _backupCodesCard() : _setupCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 2FA setup card: QR + code input ──────────────────────────────────────
  Widget _setupCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Icon(Icons.security_rounded,
                  size: 48, color: Color(0xFF1A237E)),
              const SizedBox(height: 12),
              const Text(
                'Set Up 2-Step Verification',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan the QR code with Google Authenticator, Authy, or '
                'Microsoft Authenticator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // QR code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _otpauthUrl,
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1A237E),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Manual secret key
              _ManualSecretTile(
                secret: _secret,
                visible: _secretVisible,
                onToggle: () =>
                    setState(() => _secretVisible = !_secretVisible),
              ),
              const SizedBox(height: 24),

              // Code input
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter the 6-digit code from your app to confirm:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final c = v?.trim() ?? '';
                  if (c.length != 6 || int.tryParse(c) == null) {
                    return 'Enter the 6-digit code.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _verifying ? null : _verify,
                  child: _verifying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify & Enable 2FA',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => AuthService.signOut(),
                child: const Text(
                  'Cancel and sign out',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Backup codes card (shown after successful 2FA setup) ──────────────────
  Widget _backupCodesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 56, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              '2FA Enabled!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Save these backup codes somewhere safe.\n'
              'Each code can be used once if you lose access to your authenticator app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Grid of backup codes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _backupCodes.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _CodeChip(code: _backupCodes[i]),
                          ),
                          const SizedBox(width: 8),
                          if (i + 1 < _backupCodes.length)
                            Expanded(
                              child: _CodeChip(code: _backupCodes[i + 1]),
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Copy all button
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: _backupCodes.join('\n')));
                _showSnack('Backup codes copied to clipboard.', isError: false);
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy All Codes'),
            ),
            const SizedBox(height: 20),

            // Continue button
            // AuthWrapper is already watching totpSessionVerified.value = true,
            // so it will route automatically. This button dismisses the snackbar
            // and is just a visual cue for the user.
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // AuthWrapper handles routing automatically via stream.
                  // Dismiss any snackbar first.
                  ScaffoldMessenger.of(context).clearSnackBars();
                },
                child: const Text(
                  'Continue to App',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Manual secret tile ────────────────────────────────────────────────────────

class _ManualSecretTile extends StatelessWidget {
  final String secret;
  final bool visible;
  final VoidCallback onToggle;

  const _ManualSecretTile({
    required this.secret,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Format secret in groups of 4 for readability
    final formatted = _formatSecret(secret);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.key_rounded, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manual entry key',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                visible
                    ? SelectableText(
                        formatted,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      )
                    : const Text(
                        '••••  ••••  ••••  ••••  ••••  ••••  ••••  ••••',
                        style: TextStyle(letterSpacing: 1, color: Colors.grey),
                      ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              visible ? Icons.visibility_off : Icons.visibility,
              size: 18,
            ),
            onPressed: onToggle,
            tooltip: visible ? 'Hide' : 'Show',
          ),
          if (visible)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: secret));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Secret key copied.')),
                );
              },
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }

  static String _formatSecret(String s) {
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

// ── Backup code chip ──────────────────────────────────────────────────────────

class _CodeChip extends StatelessWidget {
  final String code;

  const _CodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1A237E).withValues(alpha: 0.3)),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
