import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  final _roleCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController(text: '10');
  bool _generating = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot> get _tokensStream => FirebaseFirestore.instance
      .collection('companies')
      .doc(_uid)
      .collection('tokens')
      .orderBy('createdAt', descending: true)
      .snapshots();

  String _makeToken(String role) {
    final prefix = role.length >= 2
        ? role.substring(0, 2).toUpperCase()
        : role.toUpperCase().padRight(2, 'X');
    final suffix =
        DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return 'SK-$prefix-$suffix';
  }

  Future<void> _generateToken() async {
    final role = _roleCtrl.text.trim();
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter an internship role'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _generating = true);
    final token = _makeToken(role);
    final maxUses = int.tryParse(_maxUsesCtrl.text) ?? 10;
    final expiry = DateTime.now().add(const Duration(days: 60));
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(_uid)
        .collection('tokens')
        .add({
      'role': role,
      'token': token,
      'link': 'https://skillmatch.pro/apply/$token',
      'uses': 0,
      'maxUses': maxUses,
      'expiry': expiry.toIso8601String().substring(0, 10),
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() => _generating = false);
    if (mounted) {
      _roleCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('New token generated! 🔑'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _revokeToken(String docId) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(_uid)
        .collection('tokens')
        .doc(docId)
        .update({'active': false});
  }

  Future<void> _deleteToken(String docId) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(_uid)
        .collection('tokens')
        .doc(docId)
        .delete();
  }

  @override
  void dispose() {
    _roleCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Access Tokens',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text(
                  'Generate unique tokens to invite qualified candidates securely.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 20),

              // ── Generate new token ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Generate New Token',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _roleCtrl,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Internship Role',
                        labelStyle:
                            TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        hintText: 'e.g. Flutter Developer Intern',
                        prefixIcon: Icon(Icons.work_outline, size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Color(0xFF2D2D5E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: AppTheme.primary),
                        ),
                        filled: true,
                        fillColor: Color(0xFF0D0D1A),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Text('Max uses:',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          controller: _maxUsesCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: Color(0xFF2D2D5E)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: AppTheme.primary),
                            ),
                            filled: true,
                            fillColor: Color(0xFF0D0D1A),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _generating
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary))
                        : GradientButton(
                            label: '+ Generate Token',
                            onTap: _generateToken,
                            icon: Icons.vpn_key,
                          ),
                  ],
                ),
              ).animate().fade(),
              const SizedBox(height: 24),

              const Text('Your Tokens',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              // ── Tokens list ──────────────────────────────────────────────
              StreamBuilder<QuerySnapshot>(
                stream: _tokensStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D2D5E))),
                      child: const Center(
                          child: Text('No tokens yet. Generate one above.',
                              style: TextStyle(color: AppTheme.textMuted))),
                    );
                  }
                  return Column(
                    children: docs.asMap().entries.map((e) {
                      final docId = e.value.id;
                      final t = e.value.data() as Map<String, dynamic>;
                      final uses = t['uses'] as int? ?? 0;
                      final maxUses = t['maxUses'] as int? ?? 10;
                      final active = t['active'] as bool? ?? true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          gradient: AppTheme.cardGradient,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: active
                                  ? AppTheme.primary.withOpacity(0.2)
                                  : const Color(0xFF2D2D5E)),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(t['role'] as String? ?? '',
                                            style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? AppTheme.success.withOpacity(0.15)
                                            : AppTheme.textMuted
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(active ? 'Active' : 'Expired',
                                          style: TextStyle(
                                              color: active
                                                  ? AppTheme.success
                                                  : AppTheme.textMuted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ]),
                                  const SizedBox(height: 10),
                                  // Token display
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF0D0D1A),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFF2D2D5E))),
                                    child: Row(children: [
                                      const Icon(Icons.vpn_key_outlined,
                                          color: AppTheme.textMuted, size: 14),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(t['token'] as String? ?? '',
                                            style: const TextStyle(
                                                color: AppTheme.primaryLight,
                                                fontSize: 13,
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(
                                              text:
                                                  t['token'] as String? ?? ''));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('Token copied!'),
                                                  backgroundColor:
                                                      AppTheme.success,
                                                  behavior: SnackBarBehavior
                                                      .floating));
                                        },
                                        child: const Icon(Icons.copy,
                                            color: AppTheme.textMuted,
                                            size: 16),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    const Icon(Icons.access_time_outlined,
                                        color: AppTheme.textMuted, size: 12),
                                    const SizedBox(width: 4),
                                    Text('Expires: ${t['expiry']}',
                                        style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 11)),
                                    const Spacer(),
                                    Text('$uses/$maxUses uses',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500)),
                                  ]),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: maxUses == 0 ? 0 : uses / maxUses,
                                    backgroundColor: const Color(0xFF2D2D5E),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        uses >= maxUses
                                            ? AppTheme.error
                                            : AppTheme.primary),
                                    borderRadius: BorderRadius.circular(3),
                                    minHeight: 4,
                                  ),
                                ],
                              ),
                            ),
                            Divider(color: const Color(0xFF2D2D5E), height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: t['link'] as String? ?? ''));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Link copied! 🔗'),
                                            backgroundColor: AppTheme.success,
                                            behavior:
                                                SnackBarBehavior.floating));
                                  },
                                  icon: const Icon(Icons.link, size: 14),
                                  label: const Text('Copy Link',
                                      style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryLight),
                                ),
                                const Spacer(),
                                if (active)
                                  TextButton(
                                    onPressed: () => _revokeToken(docId),
                                    child: const Text('Revoke',
                                        style: TextStyle(
                                            color: AppTheme.warning,
                                            fontSize: 12)),
                                  ),
                                TextButton(
                                  onPressed: () => _deleteToken(docId),
                                  child: const Text('Delete',
                                      style: TextStyle(
                                          color: AppTheme.error, fontSize: 12)),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      )
                          .animate(delay: Duration(milliseconds: e.key * 80))
                          .fade()
                          .slideY(begin: 0.08, end: 0);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
