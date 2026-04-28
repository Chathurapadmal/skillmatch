import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/backup_code_service.dart';
import '../../services/firestore_user_service.dart';
import '../../services/totp_service.dart';

const Color _primary = Color(0xFF1565C0);
const Color _navy = Color(0xFF1E3A5F);
const Color _accent = Color(0xFF2E86AB);
const Color _background = Color(0xFFF8FAFC);
const Color _cardBorder = Color(0xFFDCE3F0);

class TwoFASetupPage extends StatefulWidget {
  final UserModel user;

  const TwoFASetupPage({super.key, required this.user});

  @override
  State<TwoFASetupPage> createState() => _TwoFASetupPageState();
}

class _TwoFASetupPageState extends State<TwoFASetupPage> {
  late final String _secret;
  late final String _otpauthUrl;

  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _verifying = false;
  bool _secretVisible = false;
  bool _done = false;
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

      final plainCodes = BackupCodeService.generateCodes();
      final hashedCodes = BackupCodeService.hashCodes(plainCodes);

      await Future.wait([
        FirestoreUserService.enableTwoFactor(
          uid: widget.user.uid,
          totpSecret: _secret,
          backupCodesHash: hashedCodes,
        ),
        TotpService.saveSecretLocally(_secret),
      ]);

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
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _navy : _accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_navy, _primary, _accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.25),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.55),
                      blurRadius: 45,
                      spreadRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -70,
              child: Container(
                height: 210,
                width: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(0.18),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _done ? _backupCodesCard() : _setupCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _setupCard() {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: _navy.withOpacity(0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, _accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 42,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Set Up 2-Step Verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: _navy,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan the QR code with Google Authenticator, Authy, or '
                'Microsoft Authenticator.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _otpauthUrl,
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: _navy,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: _primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _ManualSecretTile(
                secret: _secret,
                visible: _secretVisible,
                onToggle: () =>
                    setState(() => _secretVisible = !_secretVisible),
              ),
              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter the 6-digit code from your app to confirm:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
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
                  fontWeight: FontWeight.w900,
                  color: _navy,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: _background,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.red.shade400),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.red.shade400,
                      width: 1.5,
                    ),
                  ),
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

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: _primary.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => AuthService.signOut(),
                child: const Text(
                  'Cancel and sign out',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backupCodesCard() {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: _navy.withOpacity(0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, _accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              '2FA Enabled!',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: _navy,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'Save these backup codes somewhere safe.\n'
              'Each code can be used once if you lose access to your authenticator app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
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

            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: _backupCodes.join('\n')),
                );
                _showSnack('Backup codes copied to clipboard.', isError: false);
              },
              icon: const Icon(Icons.copy),
              label: const Text(
                'Copy All Codes',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: _accent.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                },
                child: const Text(
                  'Continue to App',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final formatted = _formatSecret(secret);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.key_rounded, size: 18, color: _primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manual entry key',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                visible
                    ? SelectableText(
                        formatted,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: _navy,
                        ),
                      )
                    : const Text(
                        '••••  ••••  ••••  ••••  ••••  ••••  ••••  ••••',
                        style: TextStyle(
                          letterSpacing: 1,
                          color: Colors.grey,
                        ),
                      ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              visible ? Icons.visibility_off : Icons.visibility,
              size: 18,
              color: _navy,
            ),
            onPressed: onToggle,
            tooltip: visible ? 'Hide' : 'Show',
          ),
          if (visible)
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: _primary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: secret));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Secret key copied.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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

class _CodeChip extends StatelessWidget {
  final String code;

  const _CodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _primary.withOpacity(0.28)),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1,
          color: _navy,
        ),
      ),
    );
  }
}