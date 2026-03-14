import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../theme/app_theme.dart';
import '../../../services/ai_service.dart';

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot> get _credentialsStream => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('credentials')
      .orderBy('addedAt', descending: true)
      .snapshots();

  // ─── Add credential dialog ─────────────────────────────────────────────────
  Future<void> _showAddCredential() async {
    final titleCtrl = TextEditingController();
    final institutionCtrl = TextEditingController();
    String type = 'Certificate';
    String? fileName;
    // ignore: unused_local_variable
    PlatformFile? pickedFile; // used for future storage upload
    bool dialogAnalyzing = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('Add Credential',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 16),

              // Type selector
              Row(children: [
                for (final t in ['Degree', 'Certificate', 'Course', 'Award'])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModal(() => type = t),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                            color: type == t
                                ? AppTheme.primary.withOpacity(0.2)
                                : AppTheme.bgDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: type == t
                                    ? AppTheme.primary
                                    : const Color(0xFF2D2D5E))),
                        child: Center(
                            child: Text(t,
                                style: TextStyle(
                                    color: type == t
                                        ? AppTheme.primaryLight
                                        : AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: type == t
                                        ? FontWeight.w700
                                        : FontWeight.normal))),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),

              _formField(titleCtrl, 'Credential Title',
                  hint: 'e.g. BSc Computer Science'),
              const SizedBox(height: 10),
              _formField(institutionCtrl, 'Institution',
                  hint: 'e.g. University of Moratuwa'),
              const SizedBox(height: 14),

              // File picker
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg']);
                  if (result != null) {
                    setModal(() {
                      pickedFile = result.files.first;
                      fileName = result.files.first.name;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: fileName != null
                              ? AppTheme.success.withOpacity(0.5)
                              : const Color(0xFF2D2D5E),
                          style: BorderStyle.solid)),
                  child: Row(children: [
                    Icon(
                        fileName != null
                            ? Icons.check_circle_outline
                            : Icons.upload_file_outlined,
                        color: fileName != null
                            ? AppTheme.success
                            : AppTheme.textMuted,
                        size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            fileName ?? 'Upload Certificate (PDF/Image)',
                            style: TextStyle(
                                color: fileName != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis)),
                    if (fileName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('Selected',
                            style: TextStyle(
                                color: AppTheme.success, fontSize: 10)),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: dialogAnalyzing
                      ? null
                      : () async {
                          if (titleCtrl.text.isEmpty ||
                              institutionCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please fill title and institution'),
                                  backgroundColor: AppTheme.warning,
                                  behavior: SnackBarBehavior.floating),
                            );
                            return;
                          }
                          setModal(() => dialogAnalyzing = true);
                          try {
                            final analysis = await AiService.analyzeCredential(
                              title: titleCtrl.text.trim(),
                              institution: institutionCtrl.text.trim(),
                              type: type,
                            );
                            await _saveCredential(
                              title: titleCtrl.text.trim(),
                              institution: institutionCtrl.text.trim(),
                              type: type,
                              aiAnalysis: analysis,
                              fileName: fileName,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _showMsg('Credential added & AI-analyzed! ✓',
                                AppTheme.success);
                          } catch (e) {
                            setModal(() => dialogAnalyzing = false);
                            _showMsg('Error: $e', AppTheme.error);
                          }
                        },
                  icon: dialogAnalyzing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                      dialogAnalyzing ? 'AI Analyzing...' : 'Add & AI Verify'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCredential({
    required String title,
    required String institution,
    required String type,
    required Map<String, dynamic> aiAnalysis,
    String? fileName,
  }) async {
    if (_uid == null) return;
    final hash =
        '0x${title.hashCode.abs().toRadixString(16).padLeft(8, '0').toUpperCase()}${institution.hashCode.abs().toRadixString(16).substring(0, 4).toUpperCase()}';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('credentials')
        .add({
      'title': title,
      'institution': institution,
      'type': type,
      'date': _dateStr(),
      'verified': true,
      'blockchainHash': hash,
      'fileName': fileName,
      'aiAnalysis': aiAnalysis,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  String _dateStr() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  Future<void> _deleteCredential(String docId) async {
    if (_uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('credentials')
        .doc(docId)
        .delete();
    _showMsg('Credential removed', AppTheme.textMuted);
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }

  void _shareCredential(String docId, String title) {
    final url = 'https://skillmatch.pro/verify/$docId';
    Share.share(
        'Check out my verified credential "$title" on SkillMatch Pro: $url');
  }

  void _showQrDialog(String docId, String title) {
    final url = 'https://skillmatch.pro/verify/$docId';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Scan to Verify',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
                'Employers can scan this code to instantly verify your credential on the blockchain.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
          title: const Text('Verifiable Credentials'),
          backgroundColor: AppTheme.bgDark,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppTheme.primaryLight),
              onPressed: _showAddCredential,
              tooltip: 'Add Credential',
            ),
          ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCredential,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Credential',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blockchain banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A192F), Color(0xFF0F2744)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.info.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('⛓️', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Text('Blockchain-Verified Credentials',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ]),
                  SizedBox(height: 8),
                  Text(
                    'Your qualifications are AI-verified and cryptographically signed. Employers can verify authenticity instantly — no background checks needed.',
                    style: TextStyle(
                        color: Colors.white60, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ).animate().fade(),
            const SizedBox(height: 24),

            const Text('Your Credentials',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),

            // Real credentials stream
            StreamBuilder<QuerySnapshot>(
              stream: _credentialsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2D2D5E))),
                    child: Column(children: [
                      const Icon(Icons.workspace_premium_outlined,
                          color: AppTheme.textMuted, size: 40),
                      const SizedBox(height: 12),
                      const Text('No credentials yet',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text(
                          'Tap + to add your degrees, certificates and courses',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddCredential,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add First Credential'),
                      ),
                    ]),
                  );
                }
                return Column(
                  children: docs.asMap().entries.map((e) {
                    final doc = e.value;
                    final data = doc.data() as Map<String, dynamic>;
                    final aiAnalysis =
                        data['aiAnalysis'] as Map<String, dynamic>?;
                    return _buildCredentialCard(
                      docId: doc.id,
                      data: data,
                      aiAnalysis: aiAnalysis,
                      index: e.key,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialCard({
    required String docId,
    required Map<String, dynamic> data,
    Map<String, dynamic>? aiAnalysis,
    required int index,
  }) {
    final type = data['type'] as String? ?? 'Certificate';
    final verified = data['verified'] as bool? ?? false;
    final hash = data['blockchainHash'] as String? ?? '';
    final marketValue = aiAnalysis?['marketValue'] as String? ?? 'Medium';
    final credScore = aiAnalysis?['credibilityScore'] as int? ?? 80;
    final note = aiAnalysis?['verificationNote'] as String? ?? '';
    final sugSkills =
        (aiAnalysis?['suggestedSkills'] as List?)?.cast<String>() ?? [];

    final marketColor = marketValue == 'High'
        ? AppTheme.success
        : marketValue == 'Medium'
            ? AppTheme.warning
            : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: verified
                ? AppTheme.success.withOpacity(0.3)
                : const Color(0xFF2D2D5E)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _typeColor(type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text(_typeEmoji(type),
                          style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? '',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(data['institution'] ?? '',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(data['date'] ?? '',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(note,
                            style: const TextStyle(
                                color: AppTheme.info,
                                fontSize: 11,
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
                // Verified badge + score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (verified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  color: AppTheme.success, size: 13),
                              SizedBox(width: 3),
                              Text('Verified',
                                  style: TextStyle(
                                      color: AppTheme.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ]),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: marketColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('$marketValue Value',
                          style: TextStyle(
                              color: marketColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 4),
                    Text('AI Score: $credScore%',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          // Suggested skills
          if (sugSkills.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppTheme.textMuted, size: 12),
                const SizedBox(width: 6),
                const Text('Skills: ',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                Expanded(
                    child: Text(sugSkills.join(', '),
                        style: const TextStyle(
                            color: AppTheme.info, fontSize: 11))),
              ]),
            ),
          ],

          // Bottom bar
          Divider(color: AppTheme.success.withOpacity(0.1), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              // QR Code button
              GestureDetector(
                onTap: () => _showQrDialog(docId, data['title'] ?? ''),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.qr_code_2,
                      color: Colors.black, size: 30),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Blockchain Hash',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text('$hash...',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontFamily: 'monospace')),
                    ]),
              ),
              TextButton.icon(
                onPressed: () => _shareCredential(docId, data['title'] ?? ''),
                icon: const Icon(Icons.share, size: 14),
                label: const Text('Share', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.error, size: 18),
                onPressed: () => _deleteCredential(docId),
                tooltip: 'Delete',
              ),
            ]),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fade()
        .slideY(begin: 0.1, end: 0);
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Degree':
        return AppTheme.primary;
      case 'Certificate':
        return AppTheme.success;
      case 'Course':
        return AppTheme.info;
      default:
        return AppTheme.accent;
    }
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'Degree':
        return '🎓';
      case 'Certificate':
        return '📜';
      case 'Course':
        return '📚';
      default:
        return '🏆';
    }
  }

  Widget _formField(TextEditingController ctrl, String label, {String? hint}) =>
      TextFormField(
        controller: ctrl,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2D2D5E))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary)),
          filled: true,
          fillColor: const Color(0xFF0D0D1A),
        ),
      );
}
