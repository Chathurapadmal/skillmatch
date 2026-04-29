import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/notifications_center_screen.dart';
import '../../../shared/notification_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, bool> _prefs = {};
  bool _loading = true;

  static const Color _primary = Color(0xFF1565C0);
  static const Color _navy = Color(0xFF1E3A5F);
  static const Color _accent = Color(0xFF2E86AB);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _cardBorder = Color(0xFFDCE3F0);
  static const Color _textMuted = Color(0xFF64748B);

  static const _keys = [
    'notif_job_matches',
    'notif_application_updates',
    'notif_skill_reminders',
    'notif_new_internships',
    'notif_messages',
    'notif_email_digest',
    'notif_weekly_report',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      for (final k in _keys) {
        _prefs[k] = sp.getBool(k) ?? true;
      }
      _loading = false;
    });
  }

  Future<void> _toggle(String key, bool val) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(key, val);
    setState(() => _prefs[key] = val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: _background,
          foregroundColor: _navy,
          elevation: 0,
          actions: const [ApplicantNotificationButton(iconColor: _navy)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('recipientId',
                          isEqualTo:
                              FirebaseAuth.instance.currentUser?.uid ?? '')
                      .limit(200)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final unread = (snapshot.data?.docs ?? []).where((doc) {
                      final data = doc.data();
                      return data['read'] != true;
                    }).length;

                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsCenterScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.inbox_outlined),
                        label: Text(unread > 0
                            ? 'Open App Notification Inbox ($unread)'
                            : 'Open App Notification Inbox'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _section('Push Notifications', [
                  _tile('notif_job_matches', Icons.work_outline, 'Job Matches',
                      'Alerts when new internships match your skills'),
                  _tile(
                      'notif_application_updates',
                      Icons.assignment_outlined,
                      'Application Updates',
                      'Status changes on submitted applications'),
                  _tile(
                      'notif_skill_reminders',
                      Icons.lightbulb_outline,
                      'Skill Reminders',
                      'Reminders to complete skill verifications'),
                  _tile(
                      'notif_new_internships',
                      Icons.new_releases_outlined,
                      'New Internships',
                      'Newly posted roles from followed companies'),
                  _tile('notif_messages', Icons.chat_bubble_outline, 'Messages',
                      'Direct messages from recruiters'),
                ]),
                const SizedBox(height: 20),
                _section('Email Notifications', [
                  _tile(
                      'notif_email_digest',
                      Icons.email_outlined,
                      'Daily Email Digest',
                      'Summary of activity sent each morning'),
                  _tile(
                      'notif_weekly_report',
                      Icons.bar_chart_outlined,
                      'Weekly Progress Report',
                      'Your profile views and match stats'),
                ]),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent.withOpacity(0.2)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: _accent, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'You can manage device-level permissions in your phone settings.',
                          style: TextStyle(color: _accent, fontSize: 12)),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
              children: tiles
                  .asMap()
                  .entries
                  .map((e) => Column(children: [
                        if (e.key > 0)
                          Divider(
                              height: 1, color: _cardBorder.withOpacity(0.8)),
                        e.value,
                      ]))
                  .toList()),
        ),
      ],
    ).animate().fade(delay: 60.ms);
  }

  Widget _tile(String key, IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: _accent, size: 22),
      title: Text(title, style: const TextStyle(color: _navy, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: _textMuted, fontSize: 11)),
      trailing: Switch(
        value: _prefs[key] ?? true,
        activeColor: _primary,
        onChanged: (v) => _toggle(key, v),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
