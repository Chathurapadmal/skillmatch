import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common_widgets.dart';

class GitHubIntegrationScreen extends StatefulWidget {
  const GitHubIntegrationScreen({super.key});

  @override
  State<GitHubIntegrationScreen> createState() =>
      _GitHubIntegrationScreenState();
}

class _GitHubIntegrationScreenState extends State<GitHubIntegrationScreen> {
  final _usernameCtrl = TextEditingController();
  bool _connecting = false;
  bool _connected = false;
  bool _allowedForIndustry = true;
  String _industry = '';
  Map<String, dynamic>? _githubData;

  bool _isTechIndustry(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return normalized == 'it & software' ||
        normalized.contains('software') ||
        normalized.contains('it');
  }

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await FirestoreService.getUserProfile(uid);
    if (mounted && profile != null) {
      _industry = ((profile['industry'] ?? profile['field']) as String?) ?? '';
      _allowedForIndustry = _isTechIndustry(_industry);
      setState(() {
        _connected = profile['githubConnected'] as bool? ?? false;
        if (_connected) {
          _usernameCtrl.text = profile['githubUsername'] as String? ?? '';
          _githubData = {
            'username': profile['githubUsername'] ?? '',
            'repos': profile['githubRepos'] ?? 0,
            'followers': profile['githubFollowers'] ?? 0,
            'stars': profile['githubStars'] ?? 0,
            'languageCount': profile['githubLanguageCount'] ?? 0,
            'skills': profile['githubSkills'] ?? [],
            'languages': profile['githubLanguages'] ?? [],
          };
        }
      });
    }
  }

  Future<void> _connect() async {
    if (!_allowedForIndustry) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'GitHub connect is available only for IT & Software industry.'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter your GitHub username'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _connecting = true);
    await Future.delayed(const Duration(seconds: 2));

    // Simulated GitHub analysis
    final simulatedData = {
      'username': username,
      'repos': 10,
      'followers': 1,
      'stars': 9,
      'languageCount': 4,
      'skills': ['Java', 'JavaScript', 'PHP', 'Python'],
      'languages': [
        {'name': 'Java', 'percent': 50, 'repos': 4, 'emoji': '☕'},
        {'name': 'JavaScript', 'percent': 25, 'repos': 2, 'emoji': '📜'},
        {'name': 'PHP', 'percent': 13, 'repos': 1, 'emoji': '🐘'},
        {'name': 'Python', 'percent': 13, 'repos': 1, 'emoji': '🐍'},
      ],
      'topRepos': [
        {'name': 'skillmatch-pro', 'stars': 6, 'language': 'Java'},
        {'name': 'portfolio-site', 'stars': 2, 'language': 'JavaScript'},
        {'name': 'data-tools', 'stars': 1, 'language': 'Python'},
      ],
    };

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirestoreService.updateUserProfile(uid, {
        'githubConnected': true,
        'githubUsername': username,
        'githubRepos': simulatedData['repos'],
        'githubFollowers': simulatedData['followers'],
        'githubStars': simulatedData['stars'],
        'githubLanguageCount': simulatedData['languageCount'],
        'githubSkills': simulatedData['skills'],
        'githubLanguages': simulatedData['languages'],
      });
    }

    if (mounted) {
      setState(() {
        _connected = true;
        _githubData = simulatedData;
        _connecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('GitHub account connected successfully! 🎉'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Disconnect GitHub?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will remove GitHub skills from your profile.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Disconnect')),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirestoreService.updateUserProfile(uid, {
          'githubConnected': false,
          'githubUsername': '',
        });
      }
      if (mounted) {
        setState(() {
          _connected = false;
          _githubData = null;
          _usernameCtrl.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('GitHub Integration'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_connected)
            TextButton(
              onPressed: _disconnect,
              child: const Text(
                'Disconnect',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_allowedForIndustry)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _industry.isEmpty
                      ? 'GitHub integration is only available for IT & Software users.'
                      : 'Your industry is "$_industry". GitHub integration is only available for IT & Software users.',
                  style: const TextStyle(color: AppTheme.warning, fontSize: 14),
                ),
              ),
            if (!_connected) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDCE3F0)),
                ),
                child: Row(children: [
                  const Text('🐙', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Connect your GitHub profile to auto-detect skills from your public repositories.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ]),
              ).animate().fade(),
              const SizedBox(height: 20),
              const Text('Your GitHub Username',
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameCtrl,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. rasindu-perera',
                  hintStyle:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.alternate_email,
                      color: AppTheme.textMuted, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFDCE3F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryLight),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _connecting
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary))
                  : GradientButton(
                      label: _allowedForIndustry
                          ? 'Connect & Analyze'
                          : 'Unavailable for this Industry',
                      onTap: _allowedForIndustry ? () => _connect() : () {},
                      icon: Icons.link,
                    ),
            ] else ...[
              // Profile banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFDCE3F0)),
                ),
                child: Row(
                  children: [
                    const Text('🐙', style: TextStyle(fontSize: 40)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${_githubData?['username'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'GitHub Connected ✓',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Live',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(),
              const SizedBox(height: 16),

              Row(children: [
                _miniStatCard('Repos', '${_githubData?['repos'] ?? 0}',
                    Icons.folder_outlined),
                const SizedBox(width: 10),
                _miniStatCard('Followers', '${_githubData?['followers'] ?? 0}',
                    Icons.groups_2_outlined),
                const SizedBox(width: 10),
                _miniStatCard('Stars', '${_githubData?['stars'] ?? 0}',
                    Icons.star_border_rounded,
                    highlight: AppTheme.warning),
                const SizedBox(width: 10),
                _miniStatCard(
                    'Languages',
                    '${_githubData?['languageCount'] ?? ((_githubData?['languages'] as List?)?.length ?? 0)}',
                    Icons.code_rounded),
              ]),
              const SizedBox(height: 24),

              const Text(
                'Language Analysis',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 42 / 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Based on your public repositories',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 14),

              ...(_githubData?['languages'] as List? ?? []).map((lang) {
                final l = lang as Map;
                return _languageCard(
                  emoji: l['emoji']?.toString() ?? '•',
                  name: l['name']?.toString() ?? 'Unknown',
                  repos: (l['repos'] as int?) ?? 0,
                  percent: (l['percent'] as int?) ?? 0,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(String label, String value, IconData icon,
          {Color? highlight}) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE3F0)),
          ),
          child: Column(children: [
            Icon(icon, color: AppTheme.textMuted, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  color: highlight ?? Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ]),
        ),
      );

  Widget _languageCard({
    required String emoji,
    required String name,
    required int repos,
    required int percent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE3F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$repos repos',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE6EAF2),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryLight),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$percent%',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
