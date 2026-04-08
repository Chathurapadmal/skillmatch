import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import '../../../theme/app_theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _profileVisible = true;
  bool _showSkills = true;
  bool _showCredentials = true;
  bool _dataAnalytics = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _profileVisible = sp.getBool('priv_profile_visible') ?? true;
      _showSkills = sp.getBool('priv_show_skills') ?? true;
      _showCredentials = sp.getBool('priv_show_credentials') ?? true;
      _dataAnalytics = sp.getBool('priv_data_analytics') ?? true;
      _loading = false;
    });
  }

  Future<void> _save(String key, bool val) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(key, val);
  }

  void _showChangePassword() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
            'A password reset email will be sent to your registered email address.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
            onPressed: () async {
              final email = FirebaseAuth.instance.currentUser?.email ?? '';
              if (email.isNotEmpty) {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
              }
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password reset email sent!'),
                      backgroundColor: AppTheme.success),
                );
              }
            },
            child: const Text('Send Email',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account',
            style: TextStyle(color: AppTheme.error)),
        content: const Text(
            'This will permanently delete your account and all associated data. This action cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppTheme.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
          title: const Text('Privacy & Security'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionTitle('Profile Visibility'),
                _card([
                  _switchTile(
                    Icons.person_outline,
                    'Public Profile',
                    'Allow companies to discover your profile',
                    _profileVisible,
                    (v) {
                      setState(() => _profileVisible = v);
                      _save('priv_profile_visible', v);
                    },
                  ),
                  _switchTile(
                    Icons.verified_outlined,
                    'Show Skills',
                    'Display verified skills on your public profile',
                    _showSkills,
                    (v) {
                      setState(() => _showSkills = v);
                      _save('priv_show_skills', v);
                    },
                  ),
                  _switchTile(
                    Icons.badge_outlined,
                    'Show Credentials',
                    'Show blockchain credentials to viewers',
                    _showCredentials,
                    (v) {
                      setState(() => _showCredentials = v);
                      _save('priv_show_credentials', v);
                    },
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('Data & Analytics'),
                _card([
                  _switchTile(
                    Icons.analytics_outlined,
                    'Usage Analytics',
                    'Help improve SkillMatch Pro with anonymous data',
                    _dataAnalytics,
                    (v) {
                      setState(() => _dataAnalytics = v);
                      _save('priv_data_analytics', v);
                    },
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('Account Security'),
                _card([
                  _actionTile(
                    Icons.lock_outline,
                    'Change Password',
                    'Send a password reset email',
                    _showChangePassword,
                    AppTheme.primaryLight,
                  ),
                  _actionTile(
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    'View our full privacy policy',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                    AppTheme.info,
                  ),
                  _actionTile(
                    Icons.description_outlined,
                    'Terms of Service',
                    'Review terms and conditions',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TermsOfServiceScreen(),
                      ),
                    ),
                    AppTheme.info,
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('Danger Zone'),
                _card([
                  _actionTile(
                    Icons.delete_forever_outlined,
                    'Delete Account',
                    'Permanently remove your account and data',
                    _showDeleteAccount,
                    AppTheme.error,
                  ),
                ]),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );

  Widget _card(List<Widget> tiles) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE3F0)),
        ),
        child: Column(
            children: tiles
                .asMap()
                .entries
                .map((e) => Column(children: [
                      if (e.key > 0)
                        Divider(
                            height: 1,
                            color: const Color(0xFFDCE3F0).withOpacity(0.8)),
                      e.value,
                    ]))
                .toList()),
      ).animate().fade(delay: 60.ms);

  Widget _switchTile(IconData icon, String title, String sub, bool val,
      ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryLight, size: 22),
      title: Text(title,
          style: const TextStyle(color: Colors.black87, fontSize: 14)),
      subtitle: Text(sub,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      trailing: Switch(
        value: val,
        activeColor: AppTheme.primary,
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _actionTile(IconData icon, String title, String sub,
      VoidCallback onTap, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title,
          style: TextStyle(
              color: color == AppTheme.error ? AppTheme.error : Colors.black87,
              fontSize: 14)),
      subtitle: Text(sub,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      trailing:
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
