import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final payload = <String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(uid).set(payload, SetOptions(merge: true));
  }
}
