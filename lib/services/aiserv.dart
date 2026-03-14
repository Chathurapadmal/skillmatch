import 'package:firebase_ai/firebase_ai.dart';

class AIService {
  static Future<String?> testAI() async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-lite',
    );

    final response = await model.generateContent([
      Content.text('Say hello for my SkillMatch app'),
    ]);

    return response.text;
  }
}