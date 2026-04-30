import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:skillmatch/pages/applicant/upload_cv_page.dart';
import 'package:skillmatch/pages/auth/otp_verification_page.dart';
import 'package:skillmatch/services/auth_service.dart';
import 'package:skillmatch/widgets/supabase_image_widget.dart';
import '../../../shared/chat_overlay.dart';

class _ProfileColors {
  static const Color primary = Color(0xFF1565C0);
  static const Color navy = Color(0xFF1E3A5F);
  static const Color background = Color(0xFFF5F7FB);
  static const Color border = Color(0xFFDCE3F0);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color softBlue = Color(0xFFEAF3FF);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String _profileBucket = 'profile';

  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _graduationCtrl = TextEditingController();
  final _avatarUrlCtrl = TextEditingController();

  static const List<String> _industryOptions = [
    'IT & Software',
    'Business & Management',
    'Design & UX/UI',
    'Engineering',
    'Healthcare',
    'Other',
  ];

  bool _loading = true;
  bool _saving = false;
  bool _initialized = false;
  bool _uploadingAvatar = false;

  String _email = '';
  String _role = 'applicant';

  List<String> _manualSkills = [];
  List<String> _aiSkills = [];
  List<Map<String, dynamic>> _certifications = [];
  String _cvText = '';

  int _matchRate = 0;
  bool _aiVerified = false;

  User get _user => FirebaseAuth.instance.currentUser!;

  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance.collection('users').doc(_user.uid);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _locationCtrl.dispose();
    _industryCtrl.dispose();
    _bioCtrl.dispose();
    _graduationCtrl.dispose();
    _avatarUrlCtrl.dispose();
    super.dispose();
  }

  List<String> get _allSkills {
    final merged = {..._aiSkills, ..._manualSkills}.toList();
    merged.sort();
    return merged;
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await _docRef.get();
      final data = doc.data() ?? <String, dynamic>{};

      _nameCtrl.text =
          (data['displayName'] as String?) ?? (_user.displayName ?? '').trim();
      _headlineCtrl.text = (data['headline'] as String?) ?? '';
      _locationCtrl.text = (data['location'] as String?) ?? '';
      _industryCtrl.text = (data['industry'] as String?) ??
          (data['field'] as String?) ??
          _industryOptions.first;
      _bioCtrl.text = (data['bio'] as String?) ?? '';
      _graduationCtrl.text =
          (data['graduationYear'] as String?) ?? 'Class of 2025';
      _avatarUrlCtrl.text = (data['avatarStoragePath'] as String?) ??
          (data['avatarUrl'] as String?) ??
          '';

      _manualSkills = (data['skills'] as List?)?.cast<String>() ?? <String>[];
      _aiSkills = (data['aiSkills'] as List?)?.cast<String>() ?? <String>[];

      _certifications = ((data['certifications'] as List?) ?? []).map((e) {
        return Map<String, dynamic>.from(e as Map);
      }).toList();
      _cvText = (data['cvText'] as String?) ?? '';

      _matchRate = (data['matchRate'] as num?)?.toInt() ?? 0;
      _aiVerified = (data['aiVerified'] as bool?) ?? false;

      _email = (data['email'] as String?) ?? (_user.email ?? '');
      _role = (data['role'] as String?) ?? 'applicant';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialized = true;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if email is verified
    final localEmailVerified = await AuthService.isEmailVerifiedLocally(_user.uid);
    if (!localEmailVerified) {
      if (!mounted) return;
      final shouldVerify = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Email Verification Required'),
          content: const Text(
            'You need to verify your email before editing your profile. Would you like to verify now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Verify Email'),
            ),
          ],
        ),
      );

      if (shouldVerify == true) {
        if (!mounted) return;
        await AuthService.sendEmailVerification();
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationPage(
              email: _user.email ?? '',
              purpose: 'email_verification',
              onSuccess: () async {
                await AuthService.confirmEmailVerification(
                  email: _user.email ?? '',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email verified successfully.'),
                    backgroundColor: _ProfileColors.primary,
                  ),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    setState(() => _saving = true);

    final displayName = _nameCtrl.text.trim();
    final headline = _headlineCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final industry = _industryCtrl.text.trim().isEmpty
        ? _industryOptions.first
        : _industryCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    final graduationYear = _graduationCtrl.text.trim();
    final avatarUrl = _avatarUrlCtrl.text.trim();

    try {
      await _docRef.set({
        'displayName': displayName,
        'headline': headline,
        'location': location,
        'industry': industry,
        'field': industry,
        'bio': bio,
        'graduationYear': graduationYear,
        'avatarStoragePath': avatarUrl,
        'skills': _manualSkills,
        'aiSkills': _aiSkills,
        'certifications': _certifications,
        'cvText': _cvText,
        'email': _email,
        'role': _role,
        'matchRate': _matchRate,
        'aiVerified': _aiVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if ((_user.displayName ?? '').trim() != displayName) {
        await _user.updateDisplayName(displayName);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _uploadAvatarToSupabase() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );

    if (!mounted || picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final ext = file.extension?.toLowerCase() ?? 'jpg';
    final safeExt = ['png', 'jpg', 'jpeg', 'webp'].contains(ext) ? ext : 'jpg';
    final path =
        'users/${_user.uid}/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    setState(() => _uploadingAvatar = true);
    try {
      final storage = Supabase.instance.client.storage.from(_profileBucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      await _docRef.set({
        'avatarStoragePath': path,
        'avatarStorageBucket': _profileBucket,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _avatarUrlCtrl.text = path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Profile image uploaded to Supabase $_profileBucket bucket.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avatar upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _nameCtrl.text);
    final headlineCtrl = TextEditingController(text: _headlineCtrl.text);
    final locationCtrl = TextEditingController(text: _locationCtrl.text);
    String selectedIndustry = _industryCtrl.text.trim().isEmpty
        ? _industryOptions.first
        : _industryCtrl.text.trim();
    final graduationCtrl = TextEditingController(text: _graduationCtrl.text);
    final bioCtrl = TextEditingController(text: _bioCtrl.text);
    final avatarUrlCtrl = TextEditingController(text: _avatarUrlCtrl.text);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _ProfileColors.navy,
                              _ProfileColors.primary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(26),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Update your public applicant details',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _DialogSection(
                              title: 'Basic Information',
                              icon: Icons.person_outline_rounded,
                              child: Column(
                                children: [
                                  _ProfileFormField(
                                    controller: nameCtrl,
                                    label: 'Full Name',
                                    icon: Icons.badge_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileFormField(
                                    controller: headlineCtrl,
                                    label: 'Headline',
                                    icon: Icons.work_outline_rounded,
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfilePickerTile(
                                    title: 'Professional Field',
                                    value: selectedIndustry,
                                    icon: Icons.category_outlined,
                                    onTap: () async {
                                      final selected =
                                          await showModalBottomSheet<String>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24),
                                          ),
                                        ),
                                        builder: (_) =>
                                            _ProfileIndustryPickerSheet(
                                          options: _industryOptions,
                                          selectedValue: selectedIndustry,
                                        ),
                                      );
                                      if (selected != null) {
                                        setDialogState(
                                          () => selectedIndustry = selected,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DialogSection(
                              title: 'Profile Details',
                              icon: Icons.info_outline_rounded,
                              child: Column(
                                children: [
                                  _ProfileFormField(
                                    controller: graduationCtrl,
                                    label: 'Graduation',
                                    icon: Icons.school_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileFormField(
                                    controller: locationCtrl,
                                    label: 'Location',
                                    icon: Icons.location_on_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileFormField(
                                    controller: avatarUrlCtrl,
                                    label: 'Avatar URL',
                                    icon: Icons.image_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _uploadingAvatar
                                          ? null
                                          : _uploadAvatarToSupabase,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _ProfileColors.primary,
                                        side: const BorderSide(
                                          color: _ProfileColors.border,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      icon: _uploadingAvatar
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: _ProfileColors.primary,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.cloud_upload_outlined,
                                            ),
                                      label: const Text(
                                        'Upload Profile Icon',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DialogSection(
                              title: 'Bio',
                              icon: Icons.notes_rounded,
                              child: _ProfileFormField(
                                controller: bioCtrl,
                                label: 'Bio',
                                icon: Icons.short_text_rounded,
                                maxLines: 4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _nameCtrl.text = nameCtrl.text.trim();
                                        _headlineCtrl.text =
                                            headlineCtrl.text.trim();
                                        _industryCtrl.text = selectedIndustry;
                                        _graduationCtrl.text =
                                            graduationCtrl.text.trim();
                                        _locationCtrl.text =
                                            locationCtrl.text.trim();
                                        _avatarUrlCtrl.text =
                                            avatarUrlCtrl.text.trim();
                                        _bioCtrl.text = bioCtrl.text.trim();
                                      });
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _ProfileColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddSkillDialog() async {
    final skillCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DialogHeader(
                  title: 'Add Skill',
                  subtitle: 'Add a manual skill to your profile',
                  icon: Icons.bolt_rounded,
                ),
                const SizedBox(height: 18),
                _ProfileFormField(
                  controller: skillCtrl,
                  label: 'Enter a skill',
                  icon: Icons.add_circle_outline_rounded,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ProfileColors.navy,
                          side: const BorderSide(
                            color: _ProfileColors.border,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final skill = skillCtrl.text.trim();
                          if (skill.isNotEmpty &&
                              !_manualSkills.contains(skill) &&
                              !_aiSkills.contains(skill)) {
                            setState(() => _manualSkills.add(skill));
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ProfileColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCertificationDialog({int? index}) async {
    final existing = index != null ? _certifications[index] : null;
    final titleCtrl =
        TextEditingController(text: existing?['title']?.toString() ?? '');
    final issuerCtrl =
        TextEditingController(text: existing?['issuer']?.toString() ?? '');
    final dateCtrl =
        TextEditingController(text: existing?['date']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogHeader(
                    title: index == null
                        ? 'Add Certification'
                        : 'Edit Certification',
                    subtitle: 'Keep your achievements organized',
                    icon: Icons.verified_outlined,
                  ),
                  const SizedBox(height: 18),
                  _ProfileFormField(
                    controller: titleCtrl,
                    label: 'Title',
                    icon: Icons.workspace_premium_outlined,
                  ),
                  const SizedBox(height: 12),
                  _ProfileFormField(
                    controller: issuerCtrl,
                    label: 'Issuer',
                    icon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 12),
                  _ProfileFormField(
                    controller: dateCtrl,
                    label: 'Date',
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (index != null) ...[
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() => _certifications.removeAt(index));
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ProfileColors.navy,
                            side: const BorderSide(
                              color: _ProfileColors.border,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final item = {
                              'title': titleCtrl.text.trim(),
                              'issuer': issuerCtrl.text.trim(),
                              'date': dateCtrl.text.trim(),
                            };
                            if ((item['title'] ?? '').isEmpty) return;
                            setState(() {
                              if (index == null) {
                                _certifications.add(item);
                              } else {
                                _certifications[index] = item;
                              }
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ProfileColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _removeSkill(String skill) {
    if (_aiSkills.contains(skill)) return;
    setState(() => _manualSkills.remove(skill));
  }

  Future<void> _openCvUploadPage() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => UploadCvPage(initialCvText: _cvText)),
    );

    if (result == null) return;

    final extractedSkills = (result['aiSkills'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList() ??
        <String>[];

    final extractedCerts =
        ((result['certifications'] as List?) ?? const <dynamic>[])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => (e['title'] ?? '').toString().trim().isNotEmpty)
            .toList();

    final mergedCertsByKey = <String, Map<String, dynamic>>{};
    for (final cert in [..._certifications, ...extractedCerts]) {
      final title = (cert['title'] ?? '').toString().trim();
      final issuer = (cert['issuer'] ?? '').toString().trim();
      final date = (cert['date'] ?? '').toString().trim();
      final key = '$title|$issuer|$date'.toLowerCase();
      if (title.isNotEmpty) {
        mergedCertsByKey[key] = {
          'title': title,
          'issuer': issuer,
          'date': date,
        };
      }
    }

    setState(() {
      _cvText = (result['cvText'] as String?)?.trim() ?? _cvText;
      _aiSkills = extractedSkills;
      _certifications = mergedCertsByKey.values.toList();
      _aiVerified = extractedSkills.isNotEmpty || extractedCerts.isNotEmpty;
    });

    await _saveProfile();
  }

  Widget _buildSmallInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String number, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _ProfileColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: _ProfileColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _ProfileColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    final isAiSkill = _aiSkills.contains(skill);

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 10),
      child: InputChip(
        label: Text(skill),
        selected: isAiSkill,
        showCheckmark: false,
        avatar: isAiSkill
            ? const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: _ProfileColors.primary,
              )
            : null,
        onDeleted: isAiSkill ? null : () => _removeSkill(skill),
        deleteIconColor: _ProfileColors.textMuted,
        backgroundColor: Colors.white,
        selectedColor: _ProfileColors.softBlue,
        elevation: 0,
        labelStyle: TextStyle(
          color: isAiSkill ? _ProfileColors.primary : _ProfileColors.navy,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _ProfileColors.border),
        ),
      ),
    );
  }

  Widget _buildCertificationCard(Map<String, dynamic> cert, int index) {
    return GestureDetector(
      onTap: () => _showCertificationDialog(index: index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _ProfileColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _ProfileColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: _ProfileColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert['title']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _ProfileColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Issued ${cert['date'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _ProfileColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              color: _ProfileColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String avatarUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _ProfileColors.navy,
            _ProfileColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _ProfileColors.primary.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.28),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? SupabaseImageWidget(
                          storagePath: avatarUrl,
                          isCircular: true,
                          radius: 50,
                        )
                      : Container(
                          color: Colors.white,
                          child: const Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: _ProfileColors.textMuted,
                          ),
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _showEditProfileDialog,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _ProfileColors.primary),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: _ProfileColors.primary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameCtrl.text.isEmpty ? 'Your Name' : _nameCtrl.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _headlineCtrl.text.isEmpty ? 'Add your headline' : _headlineCtrl.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallInfoChip(
                Icons.school_outlined,
                _graduationCtrl.text.isEmpty
                    ? 'Class of 2025'
                    : _graduationCtrl.text,
              ),
              _buildSmallInfoChip(
                Icons.location_on_outlined,
                _locationCtrl.text.isEmpty ? 'Add location' : _locationCtrl.text,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Text(
              _industryCtrl.text.isEmpty
                  ? _industryOptions.first
                  : _industryCtrl.text.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _loadProfile();
    }

    final avatarUrl = _avatarUrlCtrl.text.trim();

    return ChatOverlay(
      child: Scaffold(
        backgroundColor: _ProfileColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'Profile',
            style: TextStyle(
              color: _ProfileColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _ProfileColors.navy,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: _ProfileColors.primary,
              ),
              onPressed: _showEditProfileDialog,
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _ProfileColors.primary,
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(avatarUrl),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _showEditProfileDialog,
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _ProfileColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 54,
                            width: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _ProfileColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.035),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _openCvUploadPage,
                              icon: const Icon(
                                Icons.upload_file_rounded,
                                color: _ProfileColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          _statCard('${_allSkills.length}', 'SKILLS'),
                          _statCard('$_matchRate%', 'MATCH'),
                          _statCard('${_certifications.length}', 'CERTS'),
                        ],
                      ),

                      const SizedBox(height: 22),

                      _ProfileSection(
                        title: 'Technical Skills',
                        subtitle: 'Skills added manually and extracted from CV.',
                        icon: Icons.bolt_rounded,
                        actionLabel: '+ Add',
                        onActionTap: _showAddSkillDialog,
                        child: _allSkills.isEmpty
                            ? const _EmptyPanel(
                                icon: Icons.bolt_outlined,
                                message: 'No skills added yet.',
                              )
                            : Wrap(
                                children: _allSkills.map(_buildSkillChip).toList(),
                              ),
                      ),

                      const SizedBox(height: 18),

                      _ProfileSection(
                        title: 'About Me',
                        subtitle: 'A short professional summary for recruiters.',
                        icon: Icons.person_outline_rounded,
                        actionLabel: _bioCtrl.text.isEmpty ? '+ Add' : 'Edit',
                        onActionTap: _showEditProfileDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _ProfileColors.background,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _ProfileColors.border),
                          ),
                          child: Text(
                            _bioCtrl.text.isEmpty
                                ? 'Write a short professional bio that highlights your goals and experience...'
                                : _bioCtrl.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: _bioCtrl.text.isEmpty
                                  ? _ProfileColors.textMuted
                                  : _ProfileColors.navy,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      _ProfileSection(
                        title: 'Certifications',
                        subtitle: 'Showcase courses, awards, and credentials.',
                        icon: Icons.verified_outlined,
                        actionLabel: '+ Add',
                        onActionTap: () => _showCertificationDialog(),
                        child: _certifications.isEmpty
                            ? const _EmptyPanel(
                                icon: Icons.verified_outlined,
                                message: 'No certifications added yet.',
                              )
                            : Column(
                                children: _certifications
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => _buildCertificationCard(
                                        entry.value,
                                        entry.key,
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ProfileColors.primary,
                            disabledBackgroundColor:
                                _ProfileColors.primary.withOpacity(0.45),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onActionTap;
  final Widget child;

  const _ProfileSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onActionTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfileColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _ProfileColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: _ProfileColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _ProfileColors.textMuted,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  foregroundColor: _ProfileColors.primary,
                  backgroundColor: _ProfileColors.primary.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPanel({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: _ProfileColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ProfileColors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: _ProfileColors.primary.withOpacity(0.45),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfileColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _ProfileColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: _ProfileColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ProfileColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _ProfileColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DialogSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ProfileColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ProfileColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _ProfileColors.primary, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _ProfileColors.navy,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProfileFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _ProfileFormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _ProfileColors.primary),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(
          color: _ProfileColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _ProfileColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _ProfileColors.primary,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

class _ProfilePickerTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfilePickerTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _ProfileColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: _ProfileColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: _ProfileColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _ProfileColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileIndustryPickerSheet extends StatefulWidget {
  final List<String> options;
  final String selectedValue;

  const _ProfileIndustryPickerSheet({
    required this.options,
    required this.selectedValue,
  });

  @override
  State<_ProfileIndustryPickerSheet> createState() =>
      _ProfileIndustryPickerSheetState();
}

class _ProfileIndustryPickerSheetState
    extends State<_ProfileIndustryPickerSheet> {
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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _ProfileColors.border,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Set Professional Field',
              style: TextStyle(
                color: _ProfileColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose the category that best matches your profile.',
              style: TextStyle(
                color: _ProfileColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.options.map((option) {
              final selected = option == _localSelected;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? _ProfileColors.primary.withOpacity(0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? _ProfileColors.primary
                        : _ProfileColors.border,
                  ),
                ),
                child: RadioListTile<String>(
                  value: option,
                  groupValue: _localSelected,
                  activeColor: _ProfileColors.primary,
                  title: Text(
                    option,
                    style: TextStyle(
                      color: selected
                          ? _ProfileColors.primary
                          : _ProfileColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _localSelected = value);
                    Navigator.pop(context, value);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}