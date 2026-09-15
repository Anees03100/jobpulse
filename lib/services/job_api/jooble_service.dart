import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/job_model.dart';

class JoobleService {
  static const _baseUrl = 'https://jooble.org/api';

  Future<List<JobModel>> fetchJobs({
    required String keywords,
    String? location,
    int page = 1,
  }) async {
    final apiKey = dotenv.env['JOOBLE_API_KEY'];
    debugPrint(
      '🔑 Jooble API key loaded: ${apiKey != null && apiKey.isNotEmpty}',
    );

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'JOOBLE_API_KEY is missing — check .env file and pubspec assets.',
      );
    }

    final uri = Uri.parse('$_baseUrl/$apiKey');
    debugPrint(
      '🌐 Requesting: $uri with keywords="$keywords" location="$location"',
    );

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'keywords': keywords,
            if (location != null && location.isNotEmpty) 'location': location,
            'page': '$page',
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () =>
              throw Exception('Jooble request timed out after 15s'),
        );

    debugPrint('📩 Jooble response status: ${response.statusCode}');
    debugPrint(
      '📩 Jooble response body (first 300 chars): ${response.body.substring(0, response.body.length < 300 ? response.body.length : 300)}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Jooble API error: ${response.statusCode} — ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final jobs = (data['jobs'] as List<dynamic>? ?? []);
    debugPrint('✅ Parsed ${jobs.length} jobs from Jooble');

    return jobs
        .map((json) => JobModel.fromJooble(json as Map<String, dynamic>))
        .toList();
  }
}
