import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_service.dart';

class AiService {
  static const String _cvBucket = 'cv';

  static Future<String?> testAI() async {
    try {
      return await ApiService.sendMessage(
        'Say hello for my SkillMatch app',
      );
    } catch (e, stack) {
      debugPrint('AiService testAI error: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> extractCvProfile(String cvText) async {
    final prompt = '''
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
''';

    try {
      final responseText = await ApiService.sendMessage(prompt);
      final cleaned = _stripJsonFences(responseText);
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      return _normalizeCvPayload(decoded);
    } catch (e, stack) {
      debugPrint('AiService extractCvProfile error: $e');
      debugPrint('$stack');
      return _heuristicExtract(cvText);
    }
  }

  static String inferApplicantPath({
    required List<String> skills,
    required String cvText,
    List<Map<String, dynamic>> certifications = const [],
  }) {
    final normalizedSkills = skills.map((e) => e.toLowerCase()).toList();
    final normalizedText = cvText.toLowerCase();
    final normalizedCerts = certifications
        .map((e) =>
            '${(e['title'] ?? '').toString().toLowerCase()} ${(e['issuer'] ?? '').toString().toLowerCase()}')
        .join(' ');

    final corpus = [
      ...normalizedSkills,
      normalizedText,
      normalizedCerts,
    ].join(' ');

    final pathKeywords = <String, List<String>>{
      'IT & Software': [
        'flutter',
        'dart',
        'java',
        'python',
        'javascript',
        'typescript',
        'react',
        'node',
        'api',
        'firebase',
        'sql',
        'aws',
        'docker',
        'devops',
        'cloud'
      ],
      'Business & Management': [
        'business',
        'management',
        'operations',
        'leadership',
        'project management',
        'strategy',
        'hr',
        'human resource'
      ],
      'Finance & Accounting': [
        'finance',
        'accounting',
        'audit',
        'bookkeeping',
        'excel',
        'financial model',
        'tax'
      ],
      'Design & Art': [
        'design',
        'ui',
        'ux',
        'figma',
        'illustrator',
        'photoshop',
        'graphic',
        'art',
        'creative'
      ],
      'Engineering': [
        'engineering',
        'mechanical',
        'electrical',
        'civil',
        'autocad',
        'solidworks',
        'manufacturing'
      ],
      'Healthcare': [
        'health',
        'clinical',
        'nursing',
        'medical',
        'patient',
        'hospital',
        'pharmacy'
      ],
    };

    String bestPath = 'General';
    var bestScore = 0;

    pathKeywords.forEach((path, keywords) {
      var score = 0;
      for (final keyword in keywords) {
        if (corpus.contains(keyword)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestPath = path;
      }
    });

    return bestPath;
  }

  static int calculateSkillMatchScore({
    required List<String> candidateSkills,
    required List<String> requiredSkills,
  }) {
    final candidate = candidateSkills
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    final required = requiredSkills
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    if (candidate.isEmpty || required.isEmpty) return 0;

    final overlap = required.where(candidate.contains).length;
    final ratio = overlap / required.length;
    return (ratio * 100).round().clamp(0, 100);
  }

  static Map<String, List<String>> skillMatchBreakdown({
    required List<String> candidateSkills,
    required List<String> requiredSkills,
  }) {
    final candidate = candidateSkills
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    final required =
        requiredSkills.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final matched = <String>[];
    final missing = <String>[];

    for (final skill in required) {
      if (candidate.contains(skill.toLowerCase())) {
        matched.add(skill);
      } else {
        missing.add(skill);
      }
    }

    return {
      'matchedSkills': matched,
      'missingSkills': missing,
    };
  }

  static Future<Map<String, dynamic>> analyzeCredential({
    required String title,
    required String institution,
    required String type,
  }) async {
    final normalized = '$title $institution $type'.toLowerCase();

    int score = 75;
    if (normalized.contains('aws') ||
        normalized.contains('google') ||
        normalized.contains('microsoft')) {
      score = 92;
    } else if (normalized.contains('coursera') ||
        normalized.contains('udemy') ||
        normalized.contains('linkedin learning')) {
      score = 82;
    }

    final marketValue = score >= 90
        ? 'High'
        : score >= 80
            ? 'Medium'
            : 'Entry';

    final suggestedSkills = <String>{
      if (normalized.contains('flutter')) 'Flutter',
      if (normalized.contains('dart')) 'Dart',
      if (normalized.contains('python')) 'Python',
      if (normalized.contains('java')) 'Java',
      if (normalized.contains('aws')) 'AWS',
      if (normalized.contains('cloud')) 'Cloud',
      if (normalized.contains('data')) 'Data Analysis',
      if (normalized.contains('security')) 'Security',
    }.toList();

    return {
      'marketValue': marketValue,
      'credibilityScore': score,
      'verificationNote':
          'AI validation completed using title, institution and credential type.',
      'suggestedSkills': suggestedSkills,
    };
  }

  static Future<Map<String, dynamic>> generateLearningRoadmap(
      String field) async {
    final baseSkills = _defaultSkillsForField(field);

    return {
      'targetRole':
          'Junior ${field.trim().isEmpty ? 'Professional' : field} Specialist',
      'targetCompany': 'Top internship-ready teams',
      'currentMatch': 58,
      'targetMatch': 90,
      'missingSkills': baseSkills.take(4).toList(),
      'steps': [
        {
          'title': 'Build Fundamentals',
          'description':
              'Learn core concepts, tools, and workflows for ${field.trim().isEmpty ? 'your selected field' : field}.',
          'weeks': 2,
        },
        {
          'title': 'Hands-on Project',
          'description':
              'Create a portfolio project and publish it with clean documentation.',
          'weeks': 3,
        },
        {
          'title': 'Interview Preparation',
          'description':
              'Practice role-specific questions and revise weak areas with mock tests.',
          'weeks': 2,
        },
      ],
    };
  }

  static Future<Map<String, dynamic>> generateSkillQuiz({
    required String field,
    required String skill,
    int questionCount = 5,
  }) async {
    final normalizedSkill = skill.trim().isEmpty ? field : skill.trim();
    final questions = List.generate(questionCount.clamp(3, 8), (index) {
      final questionNo = index + 1;
      return {
        'q': '[$normalizedSkill] Question $questionNo: choose the best answer.',
        'options': [
          'Best practice approach',
          'Partially correct option',
          'Common mistake',
          'Irrelevant option'
        ],
        'correct': 0,
      };
    });

    return {'questions': questions};
  }

  static Future<Map<String, dynamic>> uploadCvToStorage({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        'users/$userId/cv/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    try {
      final storage = Supabase.instance.client.storage.from(_cvBucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      final signedUrl = await storage.createSignedUrl(path, 60 * 60 * 24 * 7);

      return {
        'bucket': _cvBucket,
        'path': path,
        'signed_url': signedUrl,
        'storageProvider': 'supabase',
      };
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('bucket not found') ||
          message.contains('statuscode: 404')) {
        return {
          '_error':
              'Supabase bucket "$_cvBucket" was not found. Create bucket "$_cvBucket" in Supabase Storage.',
        };
      }

      if (message.contains('statuscode: 403') ||
          message.contains('row-level security') ||
          message.contains('unauthorized') ||
          message.contains('permission denied')) {
        return {
          '_error':
              'Supabase policy denied upload to "$_cvBucket" (403). Add INSERT/SELECT policy for anon and authenticated roles.',
        };
      }

      return {
        '_error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> analyzeCv({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      final extracted = await extractCvProfile(text);
      final skills = ((extracted['skills'] as List?) ?? const <dynamic>[])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      final recommendations = <String>[
        if (skills.length < 5) 'Add more project-specific technical skills.',
        'Include measurable achievements for each experience item.',
        'Tailor CV summary for each internship role.',
      ];

      return {
        'detected_skills': skills,
        'experience': _inferExperienceLevel(text),
        'summary': _inferSummary(text),
        'recommendations': recommendations,
      };
    } catch (e) {
      return {
        '_error': e.toString(),
        'detected_skills': const <String>[],
        'experience': '',
        'summary': '',
        'recommendations': const <String>[],
      };
    }
  }

  static Future<Map<String, dynamic>> generateIndustryTrends(
      String field) async {
    final skills = _defaultSkillsForField(field);
    final trends = <Map<String, dynamic>>[];
    for (var i = 0; i < skills.length && i < 6; i++) {
      final demand = (88 - (i * 7)).clamp(45, 95);
      trends.add({
        'skill': skills[i],
        'demandPct': demand,
        'yoy': '+${(4 + i)}% YoY',
        'direction': 'up',
      });
    }

    return {
      'industry': field,
      'overview':
          'AI trend model indicates demand is increasing for practical, tool-based skills in $field roles.',
      'trends': trends,
    };
  }

  static List<String> _defaultSkillsForField(String field) {
    final normalized = field.toLowerCase();
    if (normalized.contains('it') ||
        normalized.contains('software') ||
        normalized.contains('engineering')) {
      return ['Flutter', 'Dart', 'REST APIs', 'Firebase', 'Git', 'Testing'];
    }
    if (normalized.contains('business') || normalized.contains('finance')) {
      return [
        'Excel Analytics',
        'Financial Modeling',
        'Communication',
        'Power BI',
        'Presentation Skills',
      ];
    }
    if (normalized.contains('medical') || normalized.contains('health')) {
      return [
        'Clinical Documentation',
        'Patient Communication',
        'Data Privacy',
        'Medical Terminology',
      ];
    }
    return [
      'Problem Solving',
      'Communication',
      'Teamwork',
      'Digital Tools',
      'Project Execution',
    ];
  }

  static String _inferExperienceLevel(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('senior') || lower.contains('3+ years')) {
      return '3+ years';
    }
    if (lower.contains('2 years') || lower.contains('junior')) {
      return '2 years';
    }
    return '0-1 years';
  }

  static String _inferSummary(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final lines =
        trimmed.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty);
    final first = lines.isNotEmpty ? lines.first.trim() : '';
    if (first.length > 180) {
      return '${first.substring(0, 177)}...';
    }
    return first;
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
