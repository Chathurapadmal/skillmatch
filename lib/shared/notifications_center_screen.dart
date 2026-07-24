import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationsCenterScreen extends StatelessWidget {
  const NotificationsCenterScreen({super.key});

  String _formatDateTime(Timestamp? ts) {
    if (ts == null) return 'Just now';
    final dt = ts.toDate();
    final date =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString();
    final minute = dt.minute.toString().padLeft(2, '0');
    final meridiem = dt.hour >= 12 ? 'PM' : 'AM';
    return '$date $hour:$minute $meridiem';
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'application_submitted':
        return Icons.assignment_turned_in_outlined;
      case 'application_status':
        return Icons.fact_check_outlined;
      case 'interview_scheduled':
        return Icons.video_call_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1565C0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: uid == null
          ? const Center(
              child: Text(
                'Please login again.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipientId', isEqualTo: uid)
                  .limit(200)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                docs.sort((a, b) {
                  final at = a.data()['createdAt'] as Timestamp?;
                  final bt = b.data()['createdAt'] as Timestamp?;
                  final aMs = at?.millisecondsSinceEpoch ?? 0;
                  final bMs = bt?.millisecondsSinceEpoch ?? 0;
                  return bMs.compareTo(aMs);
                });

                final unreadCount = docs.where((doc) {
                  final data = doc.data();
                  return data['read'] != true;
                }).length;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                    ),
                  );
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: [
                    if (unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              '$unreadCount unread',
                              style: const TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                await NotificationService.instance
                                    .markAllAsReadForUser(uid);
                              },
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Mark all as read'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final title =
                              (data['title'] as String?) ?? 'Notification';
                          final body = (data['body'] as String?) ?? '';
                          final createdAt = data['createdAt'] as Timestamp?;
                          final read = data['read'] == true;
                          final type = (data['type'] as String?) ?? 'general';

                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              if (!read) {
                                await NotificationService.instance
                                    .markAsRead(doc.id);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: read ? Colors.white : Colors.grey[50],
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: read
                                      ? Colors.grey[300]!
                                      : const Color(0xFF1565C0)
                                          .withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1565C0)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(_iconForType(type),
                                        size: 20,
                                        color: const Color(0xFF1565C0)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: read
                                                      ? FontWeight.w600
                                                      : FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (!read)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF1565C0),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          body,
                                          style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                              height: 1.35),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _formatDateTime(createdAt),
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
