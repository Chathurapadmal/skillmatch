import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:skillmatch/pages/applicant/upload_cv_page.dart';
import 'package:skillmatch/shared/applicant_notification_button.dart';
import 'package:skillmatch/shared/supabase_storage_page.dart';
import 'package:skillmatch/widgets/supabase_image_widget.dart';
import '../../../shared/chat_overlay.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load profile.')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save profile.')));
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

      // Store only the path, not the signed URL (to avoid expiry issues)
      await _docRef.set({
        'avatarStoragePath': path,
        'avatarStorageBucket': _profileBucket,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      // Store path in controller for reference
      setState(() => _avatarUrlCtrl.text = path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Profile image uploaded to Supabase $_profileBucket bucket.'),
      ));
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('bucket not found') ||
          message.contains('statuscode: 404')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Supabase bucket "profile" not found. Please create it in Supabase Storage.'),
        ));
      } else if (message.contains('statuscode: 403') ||
          message.contains('row-level security') ||
          message.contains('unauthorized') ||
          message.contains('permission denied')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Supabase policy denied upload (403). Allow INSERT/SELECT on bucket "profile" for anon and authenticated roles.'),
        ));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar upload failed: $e')),
        );
      }
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
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  TextField(
                    controller: headlineCtrl,
                    decoration: const InputDecoration(labelText: 'Headline'),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Professional Field'),
                    subtitle: Text(selectedIndustry),
                    trailing: const Icon(Icons.keyboard_arrow_down_rounded),
                    onTap: () async {
                      final selected = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: const Color(0xFF161A3A),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => _ProfileIndustryPickerSheet(
                          options: _industryOptions,
                          selectedValue: selectedIndustry,
                        ),
                      );
                      if (selected != null) {
                        setDialogState(() => selectedIndustry = selected);
                      }
                    },
                  ),
                  TextField(
                    controller: graduationCtrl,
                    decoration: const InputDecoration(labelText: 'Graduation'),
                  ),
                  TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  TextField(
                    controller: avatarUrlCtrl,
                    decoration: const InputDecoration(labelText: 'Avatar URL'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _uploadingAvatar ? null : _uploadAvatarToSupabase,
                      icon: _uploadingAvatar
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Upload Profile Icon (Supabase)'),
                    ),
                  ),
                  TextField(
                    controller: bioCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Bio'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _nameCtrl.text = nameCtrl.text.trim();
                    _headlineCtrl.text = headlineCtrl.text.trim();
                    _industryCtrl.text = selectedIndustry;
                    _graduationCtrl.text = graduationCtrl.text.trim();
                    _locationCtrl.text = locationCtrl.text.trim();
                    _avatarUrlCtrl.text = avatarUrlCtrl.text.trim();
                    _bioCtrl.text = bioCtrl.text.trim();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _showAddSkillDialog() async {
    final skillCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Skill'),
          content: TextField(
            controller: skillCtrl,
            decoration: const InputDecoration(hintText: 'Enter a skill'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final skill = skillCtrl.text.trim();
                if (skill.isNotEmpty &&
                    !_manualSkills.contains(skill) &&
                    !_aiSkills.contains(skill)) {
                  setState(() {
                    _manualSkills.add(skill);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCertificationDialog({int? index}) async {
    final existing = index != null ? _certifications[index] : null;

    final titleCtrl = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );
    final issuerCtrl = TextEditingController(
      text: existing?['issuer']?.toString() ?? '',
    );
    final dateCtrl = TextEditingController(
      text: existing?['date']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            index == null ? 'Add Certification' : 'Edit Certification',
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: issuerCtrl,
                  decoration: const InputDecoration(labelText: 'Issuer'),
                ),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
              ],
            ),
          ),
          actions: [
            if (index != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _certifications.removeAt(index);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removeSkill(String skill) {
    if (_aiSkills.contains(skill)) return;
    setState(() {
      _manualSkills.remove(skill);
    });
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

  Widget _statCard(String number, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B52C6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, letterSpacing: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    final isAiSkill = _aiSkills.contains(skill);
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 12),
      child: InputChip(
        label: Text(skill),
        selected: isAiSkill,
        onDeleted: isAiSkill ? null : () => _removeSkill(skill),
        deleteIconColor: Colors.white,
        backgroundColor: const Color(0xFF02141C),
        selectedColor: const Color(0xFF4B52C6),
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildCertificationCard(Map<String, dynamic> cert, int index) {
    return GestureDetector(
      onTap: () => _showCertificationDialog(index: index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFD9DDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF4B52C6),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cert['issuer'] ?? ''}   ${cert['date'] ?? ''}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
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
        backgroundColor: const Color(0xFFDDE5F1),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            const ApplicantNotificationButton(),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupabaseStoragePage(),
                  ),
                );
              },
              icon: const Icon(Icons.cloud_outlined),
            ),
            IconButton(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF2447F9),
                                      width: 3,
                                    ),
                                  ),
                                  child: avatarUrl.isNotEmpty
                                      ? SupabaseImageWidget(
                                          storagePath: avatarUrl,
                                          isCircular: true,
                                          radius: 54,
                                        )
                                      : CircleAvatar(
                                          radius: 54,
                                          backgroundColor: Colors.white,
                                          child: const Icon(Icons.person,
                                              size: 55),
                                        ),
                                ),
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: GestureDetector(
                                    onTap: _showEditProfileDialog,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF2447F9),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _nameCtrl.text.isEmpty
                                  ? 'Your Name'
                                  : _nameCtrl.text,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _headlineCtrl.text.isEmpty
                                  ? 'Add your headline'
                                  : _headlineCtrl.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3452F2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _graduationCtrl.text.isEmpty
                                      ? 'Class of 2025'
                                      : _graduationCtrl.text,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(width: 28),
                                const Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _locationCtrl.text.isEmpty
                                      ? 'Add location'
                                      : _locationCtrl.text,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _industryCtrl.text.isEmpty
                                  ? _industryOptions.first
                                  : _industryCtrl.text,
                              style: const TextStyle(
                                color: Color(0xFF3452F2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _showEditProfileDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B52C6),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Edit Profile'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _openCvUploadPage,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF4B52C6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Icon(Icons.upload_file, size: 26),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          _statCard('${_allSkills.length}', 'SKILLS'),
                          _statCard('$_matchRate%', 'MATCH RATE'),
                          _statCard(
                              '${_certifications.length}', 'CERTIFICATES'),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Technical Skills',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_aiVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                'AI Verified',
                                style: TextStyle(
                                  color: Color(0xFF4B52C6),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        children: [
                          ..._allSkills.map(_buildSkillChip),
                          Container(
                            margin:
                                const EdgeInsets.only(right: 10, bottom: 12),
                            child: OutlinedButton.icon(
                              onPressed: _showAddSkillDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.65,
                                ),
                                side: const BorderSide(color: Colors.black54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Certifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._certifications.asMap().entries.map(
                            (entry) =>
                                _buildCertificationCard(entry.value, entry.key),
                          ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _showCertificationDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Certification'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8C1CF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          _bioCtrl.text.isEmpty
                              ? 'Add your bio here...'
                              : _bioCtrl.text,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B52C6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Profile',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Email: $_email | Role: ${_role.toUpperCase()}',
                          style: const TextStyle(color: Colors.black54),
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Professional Field',
              style: TextStyle(
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
