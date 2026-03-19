import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class AIService {
  static Future<String?> testAI() async {
    try {
      final ai = FirebaseAI.googleAI();

      final model = ai.generativeModel(model: 'gemini-2.5-flash-lite');

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

  static Future<Map<String, dynamic>> extractCvProfile(String cvText) async {
    try {
      final ai = FirebaseAI.googleAI();
      final model = ai.generativeModel(model: 'gemini-2.5-flash-lite');

      final response = await model.generateContent([
        Content.text('''
Extract skills and certifications from the CV text below.
Return ONLY valid JSON in this exact shape:
{
  "skills": ["skill1", "skill2"],
  "certifications": [
    {"title": "...", "issuer": "...", "date": "..."}
  ]
}

Rules:
- Include only technical/professional skills.
- Keep skills unique and short.
- Certifications should include title, issuer, and date when available.
- If missing, use empty string for issuer/date.
- Do not include markdown fences.

CV:
$cvText
'''),
      ]);

      final raw = (response.text ?? '').trim();
      final cleaned = _stripJsonFences(raw);
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      return _normalizeCvPayload(decoded);
    } catch (e, stack) {
      debugPrint('AIService extractCvProfile error: $e');
      debugPrint('$stack');
      return _heuristicExtract(cvText);
    }
  }

  static String _stripJsonFences(String input) {
    var output = input.trim();
    if (output.startsWith('```')) {
      output = output
          .replaceFirst(RegExp(r'^```[a-zA-Z]*'), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }
    return output;
  }

  static Map<String, dynamic> _normalizeCvPayload(Map<String, dynamic> data) {
    final skills = ((data['skills'] as List?) ?? const <dynamic>[])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final certifications =
        ((data['certifications'] as List?) ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) {
              final map = Map<String, dynamic>.from(item);
              return <String, dynamic>{
                'title': (map['title'] ?? '').toString().trim(),
                'issuer': (map['issuer'] ?? '').toString().trim(),
                'date': (map['date'] ?? '').toString().trim(),
              };
            })
            .where((c) => (c['title'] as String).isNotEmpty)
            .toList();

    return {'skills': skills, 'certifications': certifications};
  }

  static Map<String, dynamic> _heuristicExtract(String cvText) {
    final lines = cvText.split(RegExp(r'\r?\n'));

    const knownSkills = <String>[
      'flutter',
      'dart',
      'java',
      'kotlin',
      'python',
      'javascript',
      'typescript',
      'react',
      'node.js',
      'firebase',
      'sql',
      'aws',
      'docker',
      'git',
    ];

    final lowerCv = cvText.toLowerCase();
    final skills = knownSkills
        .where((skill) => lowerCv.contains(skill))
        .map(
          (skill) => skill.toUpperCase() == skill
              ? skill
              : skill[0].toUpperCase() + skill.substring(1),
        )
        .toList();

    final certifications = <Map<String, dynamic>>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (RegExp(
        r'certification|certified|certificate',
        caseSensitive: false,
      ).hasMatch(trimmed)) {
        certifications.add({'title': trimmed, 'issuer': '', 'date': ''});
      }
    }

    return {'skills': skills, 'certifications': certifications};
  }
}
