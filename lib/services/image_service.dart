import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageService {
  static const _profileBucket = 'profile';
  static const _cvBucket = 'cv';
  static const _signedUrlExpiry = 60 * 60 * 24 * 30; // 30 days

  /// Generate a fresh signed URL for a profile image
  /// Pass the storage path (e.g., 'users/UID/avatar_timestamp.jpg')
  static Future<String?> getProfileImageUrl(String storagePath) async {
    try {
      if (storagePath.isEmpty) return null;

      final storage = Supabase.instance.client.storage.from(_profileBucket);
      final signedUrl =
          await storage.createSignedUrl(storagePath, _signedUrlExpiry);
      return signedUrl;
    } catch (e) {
      debugPrint('Error generating profile image URL: $e');
      return null;
    }
  }

  /// Generate a fresh signed URL for a CV file
  /// Pass the storage path (e.g., 'users/UID/cv_timestamp.pdf')
  static Future<String?> getCVUrl(String storagePath) async {
    try {
      if (storagePath.isEmpty) return null;

      final storage = Supabase.instance.client.storage.from(_cvBucket);
      final signedUrl =
          await storage.createSignedUrl(storagePath, _signedUrlExpiry);
      return signedUrl;
    } catch (e) {
      debugPrint('Error generating CV URL: $e');
      return null;
    }
  }

  /// Generate fresh URL for company logo
  static Future<String?> getCompanyLogoUrl(String storagePath) async {
    try {
      if (storagePath.isEmpty) return null;

      final storage = Supabase.instance.client.storage.from(_profileBucket);
      final signedUrl =
          await storage.createSignedUrl(storagePath, _signedUrlExpiry);
      return signedUrl;
    } catch (e) {
      debugPrint('Error generating company logo URL: $e');
      return null;
    }
  }
}
