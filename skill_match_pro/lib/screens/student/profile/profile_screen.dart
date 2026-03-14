import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common_widgets.dart';
import '../advanced/skill_verification_screen.dart';
import '../advanced/credentials_screen.dart';
import '../advanced/github_integration_screen.dart';
import '../../auth/login_screen.dart';
import '../settings/notifications_screen.dart';
import '../settings/privacy_security_screen.dart';
import '../settings/help_support_screen.dart';
import '../../../services/seed_data_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await FirestoreService.getUserProfile(uid);

    final prefs = await SharedPreferences.getInstance();
    final localImage = prefs.getString('profilePic_$uid');

    if (mounted) {
      setState(() {
        _profile = profile;
        if (localImage != null) {
          _profile?['profilePicture'] = localImage;
        }
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) return;

      setState(() => _uploadingImage = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profilePic_$uid', base64String);

      await FirestoreService.updateUserProfile(
          uid, {'profilePicture': 'local'});

      if (mounted) {
        await _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile picture updated successfully!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out?',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Log Out')),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false);
      }
    }
  }

  Future<void> _editField() async {
    final currentField = _profile?['field'] as String? ?? 'IT & Software';
    String selectedField = currentField;
    final categories = [
      'IT & Software',
      'Business & Management',
      'Design & UX/UI',
      'Engineering',
      'Healthcare',
      'Teaching & Education',
      'Other'
    ];

    final newField = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Set Professional Field',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: categories.map((cat) {
                  return RadioListTile<String>(
                    title: Text(cat,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14)),
                    value: cat,
                    groupValue: selectedField,
                    activeColor: AppTheme.primary,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedField = val);
                      }
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppTheme.textMuted))),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, selectedField),
                    child: const Text('Save')),
              ],
            );
          },
        );
      },
    );

    if (newField != null && newField != currentField) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirestoreService.updateUserProfile(uid, {'field': newField});
        _loadProfile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // Real data from Firestore, with safe fallbacks
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final name = _profile?['name'] as String? ??
        firebaseUser?.email?.split('@').first ??
        'User';
    final university = _profile?['university'] as String? ?? 'Not set';
    final gpa = _profile?['gpa'];
    final educationLevel =
        _profile?['educationLevel'] as String? ?? 'Undergraduate';
    final githubConnected = _profile?['githubConnected'] as bool? ?? false;
    final cvAnalyzed = _profile?['cvAnalyzed'] as bool? ?? false;
    final String? field = _profile?['field'] as String?;
    final String? profilePic = _profile?['profilePicture'] as String?;
    final rawSkills = _profile?['skills'] as List?;
    final skills = rawSkills?.map((s) => s.toString()).toList() ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadProfile,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    24, MediaQuery.of(context).padding.top + 16, 24, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0D0D1A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Profile',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: AppTheme.bgCard,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFF2D2D5E))),
                            child: const Icon(Icons.refresh_outlined,
                                color: AppTheme.textSecondary, size: 16),
                          ),
                          onPressed: _loadProfile,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Avatar with initial
                    GestureDetector(
                      onTap: _uploadingImage ? null : _pickAndUploadImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        AppTheme.primary.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2)
                              ],
                              image: profilePic != null
                                  ? DecorationImage(
                                      image: profilePic == 'local' ||
                                              profilePic.length < 50
                                          ? const AssetImage(
                                                  'assets/images/google.png')
                                              as ImageProvider
                                          : MemoryImage(
                                              base64Decode(profilePic)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: profilePic == null
                                ? Center(
                                    child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold),
                                  ))
                                : null,
                          ),
                          if (_uploadingImage)
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.bgDark, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(),
                    const SizedBox(height: 12),
                    Text(name,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(university,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        if (gpa != null) _pill('GPA: $gpa', AppTheme.success),
                        _pill(educationLevel, AppTheme.primary),
                        GestureDetector(
                          onTap: _editField,
                          child: _pill(field ?? 'Set Field ✎', AppTheme.info),
                        ),
                        if (githubConnected && field == 'IT & Software')
                          _pill('GitHub ✓', const Color(0xFF6B717E)),
                        if (cvAnalyzed)
                          _pill('CV Analyzed ✓', AppTheme.success),
                      ],
                    ),
                  ].animate(interval: 80.ms).fade(),
                ),
              ),
            ),

            // Skills
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Skills',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const SkillVerificationScreen())),
                          child: const Text('Verify more ›',
                              style: TextStyle(
                                  color: AppTheme.primaryLight, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    skills.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: AppTheme.bgCard,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFF2D2D5E))),
                            child: Row(children: [
                              const Icon(Icons.upload_file_outlined,
                                  color: AppTheme.textMuted, size: 18),
                              const SizedBox(width: 10),
                              const Expanded(
                                  child: Text(
                                      'Upload your CV to extract skills automatically',
                                      style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 13))),
                            ]),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                skills.map((s) => SkillChip(skill: s)).toList(),
                          ),
                  ],
                ).animate(delay: 200.ms).fade(),
              ),
            ),

            // Advanced features
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Advanced Features',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _featureTile(
                        context,
                        Icons.verified_outlined,
                        'Verifiable Credentials',
                        'Blockchain-verified qualifications',
                        AppTheme.success,
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CredentialsScreen()))),
                    if (field == 'IT & Software')
                      _featureTile(
                          context,
                          Icons.code,
                          'GitHub Integration',
                          'Verify skills via commit history',
                          const Color(0xFF6B717E),
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const GitHubIntegrationScreen()))),
                  ],
                ).animate(delay: 300.ms).fade(),
              ),
            ),

            // Account
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    // Email display
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D2D5E))),
                      child: Row(children: [
                        const Icon(Icons.email_outlined,
                            color: AppTheme.textMuted, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(firebaseUser?.email ?? '',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13))),
                      ]),
                    ),
                    _settingTile(Icons.notifications_outlined, 'Notifications',
                        AppTheme.textSecondary,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen()))),
                    _settingTile(Icons.security_outlined, 'Privacy & Security',
                        AppTheme.textSecondary,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const PrivacySecurityScreen()))),
                    _settingTile(Icons.help_outline, 'Help & Support',
                        AppTheme.textSecondary,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HelpSupportScreen()))),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      tileColor: AppTheme.bgCard,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF2D2D5E))),
                      leading: const Icon(Icons.logout,
                          color: AppTheme.error, size: 20),
                      title: const Text('Log Out',
                          style:
                              TextStyle(color: AppTheme.error, fontSize: 14)),
                      onTap: _logout,
                    ),
                    const SizedBox(height: 20),
                    // ── Dev Tool ─────────────────────────────────────────
                    _SeedDataTile(),
                  ],
                ).animate(delay: 400.ms).fade(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      );

  Widget _featureTile(BuildContext context, IconData icon, String title,
      String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text(sub,
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ]),
          const Spacer(),
          Icon(Icons.chevron_right, color: color.withValues(alpha: 0.7)),
        ]),
      ),
    );
  }

  Widget _settingTile(IconData icon, String label, Color color,
      {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        tileColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2D2D5E))),
        leading: Icon(icon, color: color, size: 20),
        title: Text(label, style: TextStyle(color: color, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right,
            color: AppTheme.textMuted, size: 18),
        onTap: onTap ?? () {},
      ),
    );
  }
}

// ── Dev Tool: Seed Sample Data ─────────────────────────────────────────────
class _SeedDataTile extends StatefulWidget {
  @override
  State<_SeedDataTile> createState() => _SeedDataTileState();
}

class _SeedDataTileState extends State<_SeedDataTile> {
  bool _seeding = false;

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await SeedDataService.seedAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Sample data loaded into Firebase!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error seeding data: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _seeding = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: _seeding
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.warning))
            : const Icon(Icons.science_outlined,
                color: AppTheme.warning, size: 20),
        title: const Text('Load Sample Data',
            style: TextStyle(
                color: AppTheme.warning,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        subtitle: const Text('Seeds demo companies, students & internships',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        trailing: const Icon(Icons.upload_outlined,
            color: AppTheme.warning, size: 16),
        onTap: _seeding ? null : _seed,
      ),
    );
  }
}
