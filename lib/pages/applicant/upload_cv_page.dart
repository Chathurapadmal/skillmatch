import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/aiserv.dart';
import '../../services/firestore_service.dart';
import '../../shared/chat_overlay.dart';
import '../../theme/app_theme.dart';

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
  String? _fileName;
  String? _cvStoragePath;
  String? _cvStorageUrl;
  bool _uploadingCv = false;
  bool _loadingCv = true;
  bool _savingManual = false;

  final _ageCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  Map<String, dynamic> _cvData = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadCvData();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCvData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingCv = false);
      return;
    }

    final profile = await FirestoreService.getUserProfile(uid);
    if (!mounted) return;

    setState(() {
      _fileName = profile?['cvFileName'] as String?;
      _cvStoragePath = profile?['cvStoragePath'] as String?;
      _cvStorageUrl = profile?['cvStorageSignedUrl'] as String?;
      _ageCtrl.text = (profile?['age']?.toString() ?? '').trim();
      _experienceCtrl.text = ((profile?['experience'] as String?) ??
              (profile?['cvExperience'] as String?) ??
              '')
          .trim();
      _cvData = {
        'detected_skills':
            ((profile?['cvSkills'] as List?) ?? []).map((e) => '$e').toList(),
        'experience': (profile?['cvExperience'] as String?) ?? '',
        'summary': (profile?['cvSummary'] as String?) ?? '',
        'recommendations': ((profile?['cvRecommendations'] as List?) ?? [])
            .map((e) => '$e')
            .toList(),
      };
      _loadingCv = false;
    });
  }

  Future<void> _pickCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to read this file. Try a PDF or TXT CV.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _uploadingCv = true);

    final storageUpload = await AiService.uploadCvToStorage(
      bytes: bytes,
      fileName: file.name,
      userId: uid,
    );

    final hasStorageError = storageUpload.containsKey('_error');
    final storageError = (storageUpload['_error'] as String?) ?? '';
    if (hasStorageError) {
      if (!mounted) return;
      setState(() => _uploadingCv = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            storageError.isNotEmpty
                ? 'CV upload failed: $storageError'
                : 'CV upload failed. Please try again.',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final analysis =
        await AiService.analyzeCv(bytes: bytes, fileName: file.name);
    final hasAnalysisError = analysis.containsKey('_error');
    final analysisError = (analysis['_error'] as String?) ?? '';

    final detectedSkills = ((analysis['detected_skills'] as List?) ?? [])
        .map((e) => '$e')
        .toList();
    final recommendations = ((analysis['recommendations'] as List?) ?? [])
        .map((e) => '$e')
        .toList();

    final profile = await FirestoreService.getUserProfile(uid);
    final existingSkills =
        ((profile?['skills'] as List?) ?? []).map((e) => '$e').toList();
    final mergedSkills =
        <String>{...existingSkills, ...detectedSkills}.toList();

    await FirestoreService.updateUserProfile(uid, {
      'cvFileName': file.name,
      'cvStorageBucket': storageUpload['bucket'] as String?,
      'cvStoragePath': storageUpload['path'] as String?,
      'cvStorageSignedUrl': storageUpload['signed_url'] as String?,
      'cvAnalyzed': analysis.isNotEmpty && !hasAnalysisError,
      'cvSkills': detectedSkills,
      'cvExperience': (analysis['experience'] as String?) ?? '',
      'cvSummary': (analysis['summary'] as String?) ?? '',
      'cvRecommendations': recommendations,
      'cvAnalyzeError': analysisError,
      'cvUploadedAt': FieldValue.serverTimestamp(),
      'skills': mergedSkills,
      if ((analysis['experience'] as String?)?.trim().isNotEmpty == true)
        'experience': analysis['experience'],
    });

    if (!mounted) return;

    setState(() {
      _fileName = file.name;
      _cvStoragePath = storageUpload['path'] as String?;
      _cvStorageUrl = storageUpload['signed_url'] as String?;
      _cvData = analysis;
      if ((analysis['experience'] as String?)?.trim().isNotEmpty == true &&
          (analysis['experience'] as String).toLowerCase() != 'unknown') {
        _experienceCtrl.text = (analysis['experience'] as String).trim();
      }
      _uploadingCv = false;
    });

    final analyzed = analysis.isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !hasAnalysisError && analyzed
              ? 'CV uploaded and saved. AI extracted details updated.'
              : (analysisError.isNotEmpty
                  ? 'CV uploaded, but analysis failed: $analysisError'
                  : 'CV uploaded and saved. AI extraction was not available for this file.'),
        ),
        backgroundColor: (!hasAnalysisError && analyzed)
            ? AppTheme.success
            : AppTheme.warning,
      ),
    );

    if (widget.returnResultOnExtract) {
      Navigator.of(context).pop({
        'cvText': widget.initialCvText,
        'aiSkills': detectedSkills,
        'certifications': const <Map<String, dynamic>>[],
      });
    }
  }

  Future<void> _saveManualDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ageText = _ageCtrl.text.trim();
    final experienceText = _experienceCtrl.text.trim();
    final parsedAge = int.tryParse(ageText);

    if (ageText.isNotEmpty &&
        (parsedAge == null || parsedAge < 15 || parsedAge > 80)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid age between 15 and 80.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _savingManual = true);
    await FirestoreService.updateUserProfile(uid, {
      'age': parsedAge,
      'experience': experienceText,
      if (experienceText.isNotEmpty) 'cvExperience': experienceText,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => _savingManual = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual details saved successfully.'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detectedSkills =
        ((_cvData['detected_skills'] as List?) ?? []).map((e) => '$e').toList();
    final recommendations =
        ((_cvData['recommendations'] as List?) ?? []).map((e) => '$e').toList();
    final summary = (_cvData['summary'] as String?) ?? '';
    final experience = (_cvData['experience'] as String?) ?? '';
    final hasDetectedExperience =
        experience.trim().isNotEmpty && experience.toLowerCase() != 'unknown';

    if (_loadingCv) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1026),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryLight),
        ),
      );
    }

    return ChatOverlay(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1026),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1026),
          foregroundColor: Colors.white,
          title: const Text('My CV'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Upload CV',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload your resume - AI will extract your skills and experience.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFF121236),
                  borderRadius: BorderRadius.circular(28),
                  border:
                      Border.all(color: const Color(0xFF3A34B8), width: 1.2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        color: Color(0xFF24245C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.upload_file_rounded,
                          color: AppTheme.primaryLight, size: 58),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _fileName == null ? 'Tap to choose your CV' : _fileName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Supported: PDF, TXT, DOCX (Max 10MB)',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                    ),
                    if ((_cvStoragePath ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Stored path: ${_cvStoragePath!}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if ((_cvStorageUrl ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Signed access URL generated (7 days)',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _uploadingCv ? null : _pickCv,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.35),
                              blurRadius: 18,
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _uploadingCv
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                '+ Upload PDF / TXT / DOCX',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF18183C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D2D5E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manual Student Details',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                        hintText: 'Enter your age',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _experienceCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: hasDetectedExperience
                            ? 'Experience (editable)'
                            : 'Experience (manual entry)',
                        labelStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        hintText: 'e.g. 2 years mobile development',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _savingManual ? null : _saveManualDetails,
                        icon: _savingManual
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save Manual Details'),
                      ),
                    ),
                  ],
                ),
              ),
              if (summary.trim().isNotEmpty ||
                  experience.trim().isNotEmpty ||
                  detectedSkills.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18183C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D2D5E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI CV Insights',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (experience.trim().isNotEmpty)
                        Text('Experience: $experience',
                            style:
                                const TextStyle(color: AppTheme.textSecondary)),
                      if (summary.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(summary,
                            style: const TextStyle(color: AppTheme.textMuted)),
                      ],
                      if (detectedSkills.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: detectedSkills
                              .map(
                                (skill) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF23235A),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (recommendations.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...recommendations.take(3).map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• $item',
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 12),
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
