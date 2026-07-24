import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createInAppNotification({
    required String recipientId,
    String? senderId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (recipientId.trim().isEmpty) return;

    await _db.collection('notifications').add({
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type,
      'title': title,
      'body': body,
      'data': data ?? <String, dynamic>{},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;
    await _db.collection('notifications').doc(notificationId).set({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllAsReadForUser(String userId) async {
    if (userId.trim().isEmpty) return;

    final unread = await _db
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
