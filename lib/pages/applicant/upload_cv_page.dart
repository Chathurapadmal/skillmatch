import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/ai_service.dart';
import '../../shared/chat_overlay.dart';

const Color _primary = Color(0xFF1565C0);
const Color _navy = Color(0xFF1E3A5F);
const Color _accent = Color(0xFF2E86AB);
const Color _background = Color(0xFFF8FAFC);
const Color _cardBorder = Color(0xFFDCE3F0);

class UploadCvPage extends StatefulWidget {
  final String initialCvText;
  final bool returnResultOnExtract;

  const UploadCvPage({
    super.key,
    this.initialCvText = '',
    this.returnResultOnExtract = true,
  });

  @override
  State<UploadCvPage> createState() => _UploadCvPageState();
}

class _UploadCvPageState extends State<UploadCvPage> {
  late final TextEditingController _cvTextCtrl;

  bool _uploading = false;
  bool _extracting = false;

  @override
  void initState() {
    super.initState();
    _cvTextCtrl = TextEditingController(text: widget.initialCvText);
  }

  @override
  void dispose() {
    _cvTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCvFile() async {
    setState(() => _uploading = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['txt', 'md'],
      );

      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.single;
      String content = '';

      if (file.bytes != null) {
        content = utf8.decode(file.bytes!, allowMalformed: true);
      } else if (!kIsWeb && file.path != null) {
        content = await File(file.path!).readAsString();
      }

      if (!mounted) return;

      if (content.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not read text from the selected file.')),
        );
        return;
      }

      setState(() {
        _cvTextCtrl.text = content;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded ${file.name} successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload CV file.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _extractAndReturn() async {
    final cvText = _cvTextCtrl.text.trim();
    if (cvText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload or paste your CV text first.')),
      );
      return;
    }

    setState(() => _extracting = true);
    try {
      final parsed = await AiService.extractCvProfile(cvText);
      final extractedSkills = (parsed['skills'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList() ??
          <String>[];
      final extractedCerts = ((parsed['certifications'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final applicantPath = AiService.inferApplicantPath(
        skills: extractedSkills,
        cvText: cvText,
        certifications: extractedCerts,
      );

      final companySuggestions = await _buildCompanySuggestions(
        extractedSkills: extractedSkills,
        applicantPath: applicantPath,
      );

      await _updateApplicantProfileAndCompanySuggestions(
        cvText: cvText,
        extractedSkills: extractedSkills,
        extractedCerts: extractedCerts,
        applicantPath: applicantPath,
        companySuggestions: companySuggestions,
      );

      if (!mounted) return;

      final result = {
        'cvText': cvText,
        'aiSkills': extractedSkills,
        'certifications': extractedCerts,
        'applicantPath': applicantPath,
        'suggestedCompanies': companySuggestions,
      };

      if (widget.returnResultOnExtract) {
        Navigator.pop(context, result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Extracted ${(result['aiSkills'] as List).length} skills, identified path "${result['applicantPath']}", and found ${(result['suggestedCompanies'] as List).length} company matches.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to extract data from CV.')),
      );
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  Future<List<Map<String, dynamic>>> _buildCompanySuggestions({
    required List<String> extractedSkills,
    required String applicantPath,
  }) async {
    final internships = await FirebaseFirestore.instance
        .collection('internships')
        .where('active', isEqualTo: true)
        .limit(120)
        .get();

    final ranked = <Map<String, dynamic>>[];

    for (final doc in internships.docs) {
      final data = doc.data();
      final requiredSkills = ((data['skills'] as List?) ?? const <dynamic>[])
          .map((e) => '$e')
          .toList();

      final score = AiService.calculateSkillMatchScore(
        candidateSkills: extractedSkills,
        requiredSkills: requiredSkills,
      );
      if (score < 35) continue;

      final breakdown = AiService.skillMatchBreakdown(
        candidateSkills: extractedSkills,
        requiredSkills: requiredSkills,
      );

      ranked.add({
        'internshipId': doc.id,
        'companyId': (data['companyId'] as String? ?? '').trim(),
        'companyName': (data['company'] as String? ?? 'Company').trim(),
        'roleTitle': (data['title'] as String? ?? 'Internship').trim(),
        'industry': (data['industry'] as String? ?? '').trim(),
        'matchScore': score,
        'matchedSkills': breakdown['matchedSkills'] ?? const <String>[],
        'missingSkills': breakdown['missingSkills'] ?? const <String>[],
        'applicantPath': applicantPath,
      });
    }

    ranked.sort(
        (a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int));
    return ranked.take(10).toList();
  }

  Future<void> _updateApplicantProfileAndCompanySuggestions({
    required String cvText,
    required List<String> extractedSkills,
    required List<Map<String, dynamic>> extractedCerts,
    required String applicantPath,
    required List<Map<String, dynamic>> companySuggestions,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final existing = await userDocRef.get();
    final existingSkills =
        ((existing.data()?['skills'] as List?) ?? const <dynamic>[])
            .map((e) => '$e')
            .toList();

    final mergedSkills = <String>{
      ...existingSkills,
      ...extractedSkills,
    }.toList();

    await userDocRef.set({
      'cvText': cvText,
      'aiSkills': extractedSkills,
      'cvSkills': extractedSkills,
      'certifications': extractedCerts,
      'skills': mergedSkills,
      'applicantPath': applicantPath,
      'industry': applicantPath,
      'field': applicantPath,
      'aiSuggestedCompanies': companySuggestions,
      'lastCvAiRunAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'aiVerified': extractedSkills.isNotEmpty || extractedCerts.isNotEmpty,
    }, SetOptions(merge: true));

    final suggestionsRef =
        FirebaseFirestore.instance.collection('company_candidate_suggestions');

    for (final suggestion in companySuggestions) {
      final companyId = (suggestion['companyId'] as String? ?? '').trim();
      if (companyId.isEmpty) continue;

      final docId = '${companyId}_$uid';
      await suggestionsRef.doc(docId).set({
        'companyId': companyId,
        'candidateId': uid,
        'matchScore': suggestion['matchScore'] ?? 0,
        'matchedSkills': suggestion['matchedSkills'] ?? const <String>[],
        'missingSkills': suggestion['missingSkills'] ?? const <String>[],
        'applicantPath': applicantPath,
        'internshipId': suggestion['internshipId'] ?? '',
        'roleTitle': suggestion['roleTitle'] ?? 'Internship',
        'companyName': suggestion['companyName'] ?? 'Company',
        'source': 'cv_ai',
        'status': 'new',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatOverlay(
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _navy),
          title: const Text(
            'Upload CV',
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_navy, _primary, _accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -10,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.description_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Seamless CV Upload',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Upload your CV and let AI extract\nskills instantly',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _uploading || _extracting ? null : _pickCvFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: _accent.withOpacity(0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _uploading
                                  ? const CircularProgressIndicator(
                                      color: _primary,
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_primary, _accent],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.cloud_upload_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                              const SizedBox(height: 14),
                              const Text(
                                "Upload your CV",
                                style: TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Supports TXT, MD (or paste below)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: _navy.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _cvTextCtrl,
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(color: _navy),
                            decoration: const InputDecoration(
                              hintText: "Paste your CV text here...",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _extracting || _uploading
                            ? null
                            : _extractAndReturn,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, _accent],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: _extracting
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    "Extract to Profile",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}