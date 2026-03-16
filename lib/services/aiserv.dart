import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class AIService {
  static Future<String?> testAI() async {
    try {
      final ai = FirebaseAI.googleAI();

      final model = ai.generativeModel(
          model: 'gemini-2.5-flash-lite',
      );

      final response = await model.generateContent([
        Content.text('Say hello for my SkillMatch app'),
      ]);

      return response.text;
    } catch (e, stack) {
      debugPrint('AIService error: $e');
      debugPrint('$stack');
      rethrow;
    }
  }
}