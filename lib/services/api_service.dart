import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class JobItem {
  final String title;
  final String company;
  final String location;
  final String description;
  final String salary;
  final String url;
  final String source;

  const JobItem({
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.salary,
    required this.url,
    required this.source,
  });

  factory JobItem.fromJson(Map<String, dynamic> json) {
    return JobItem(
      title: (json['title'] ?? '').toString(),
      company: (json['company'] ?? 'Unknown company').toString(),
      location: (json['location'] ?? 'Unknown location').toString(),
      description: (json['description'] ?? '').toString(),
      salary: (json['salary'] ?? 'Not specified').toString(),
      url: (json['url'] ?? '').toString(),
      source: (json['source'] ?? 'Adzuna').toString(),
    );
  }
}

class JobSearchResponse {
  final int count;
  final List<JobItem> jobs;

  const JobSearchResponse({required this.count, required this.jobs});
}

class ApiService {
  static String? _resolvedBaseUrl;
  static String? _manualBackendUrl; // User can set this manually

  static const String _defaultLocalBaseUrl = 'http://localhost:5000';
  
  // Production backend (Vercel) - this is now the primary URL
  static const String _vercelBackendUrl = 'https://skillmatch-ed2u.vercel.app';

  static const List<String> _androidCandidates = <String>[
    _vercelBackendUrl, // Try Vercel first  
    'http://10.0.2.2:5000',
    'http://192.168.240.1:5000',
    'http://192.168.1.103:5000',
    'http://127.0.0.1:5000',
    'http://localhost:5000',
  ];

  static Future<bool> _isHealthy(String baseUrl) async {
    try {
      // Try /health first (local development)
      var response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) return true;

      // Try /api/health (Vercel deployment)
      response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Manually set the backend URL (useful when auto-detection fails)
  static void setBackendUrl(String url) {
    _manualBackendUrl = url;
    _resolvedBaseUrl = url;
    debugPrint('Backend URL manually set to: $url');
  }

  /// Reset the backend URL to auto-detection mode
  static void resetBackendUrl() {
    _manualBackendUrl = null;
    _resolvedBaseUrl = null;
  }

  /// Get the currently configured backend URL (for display/settings)
  static Future<String> getCurrentBackendUrl() async {
    return _resolveBaseUrl();
  }

  static Future<String> _resolveBaseUrl() async {
    // 1. Check if user manually set a URL
    if (_manualBackendUrl != null) {
      return _manualBackendUrl!;
    }

    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;

    // 2. Check environment variable
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      _resolvedBaseUrl = configuredBaseUrl;
      return configuredBaseUrl;
    }

    // 3. Auto-detect by testing candidates
    final candidates = <String>[
      if (kIsWeb)
        _defaultLocalBaseUrl
      else
        ...switch (defaultTargetPlatform) {
          TargetPlatform.android || TargetPlatform.iOS => _androidCandidates,
          _ => <String>[_defaultLocalBaseUrl],
        },
    ];

    for (final candidate in candidates) {
      if (await _isHealthy(candidate)) {
        _resolvedBaseUrl = candidate;
        return candidate;
      }
    }

    // 4. Fallback to first candidate if none are healthy
    _resolvedBaseUrl = candidates.first;
    return _resolvedBaseUrl!;
  }

  /// Public resolver for other services to get the resolved backend base URL.
  static Future<String> getBaseUrl() async {
    return _resolveBaseUrl();
  }

  /// Get base URL depending on platform
  static Future<String> get _baseUrl async {
    return _resolveBaseUrl();
  }

  /// Send a message to the AI backend
  static Future<String> sendMessage(
    String message, {
    List<String> recentMessages = const [],
  }) async {
    final url = Uri.parse('${await _baseUrl}/api/generate');

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "prompt": message,
              "history": recentMessages,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["text"] as String? ?? '';
      } else {
        throw Exception(
            'Failed to get response (${response.statusCode})\n${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to API: $e');
    }
  }

  static Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('${await _baseUrl}$path');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));

      final decoded = jsonDecode(response.body);
      final body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};

      if (response.statusCode != 200) {
        throw Exception(
          (body['error'] ?? 'Request failed (${response.statusCode})')
              .toString(),
        );
      }

      return body;
    } catch (e) {
      throw Exception('Error calling $path: $e');
    }
  }

  /// Public generic POST helper for backend APIs.
  static Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> payload,
  ) {
    return _postJson(path, payload);
  }

  static Future<Map<String, dynamic>> generateRoadmap({
    required String field,
    List<String> skills = const [],
  }) {
    return _postJson('/api/roadmap', {
      'field': field,
      'skills': skills,
    });
  }

  static Future<Map<String, dynamic>> generateTrends({
    required String field,
    List<String> skills = const [],
  }) {
    return _postJson('/api/trends', {
      'field': field,
      'skills': skills,
    });
  }

  static Future<Map<String, dynamic>> generateSkillQuiz({
    required String field,
    required String skill,
    int questionCount = 5,
    List<String> skills = const [],
  }) {
    return _postJson('/api/skill-quiz', {
      'field': field,
      'skill': skill,
      'questionCount': questionCount,
      'skills': skills,
    });
  }

  static Future<JobSearchResponse> fetchJobs({
    required String query,
    String location = 'remote',
    int page = 1,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      throw Exception('Search query cannot be empty.');
    }

    final uri = Uri.parse('${await _baseUrl}/api/jobs').replace(
      queryParameters: {
        'query': trimmedQuery,
        'location': location.trim().isEmpty ? 'remote' : location.trim(),
        'page': '$page',
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      final payload = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        final message = (payload['error'] ?? 'Failed to fetch jobs').toString();
        throw Exception(message);
      }

      final jobsJson = (payload['jobs'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final jobs = jobsJson.map(JobItem.fromJson).toList();
      final count = (payload['count'] as num?)?.toInt() ?? jobs.length;

      return JobSearchResponse(count: count, jobs: jobs);
    } catch (e) {
      throw Exception('Error fetching jobs: $e');
    }
  }
}
