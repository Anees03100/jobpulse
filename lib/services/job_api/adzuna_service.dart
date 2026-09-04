import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/job_model.dart';

class AdzunaService {
  static const _country = 'gb'; // Adzuna doesn't cover Pakistan directly;
  // 'gb' or 'us' gives the broadest remote/tech listings. Swap if you find
  // a better-covered country code for your target audience.
  static const _baseUrl = 'https://api.adzuna.com/v1/api/jobs';

  Future<List<JobModel>> fetchJobs({
    required String query, // e.g. "Flutter Developer"
    String? location,
    int page = 1,
    int resultsPerPage = 20,
  }) async {
    final appId = dotenv.env['ADZUNA_APP_ID'];
    final appKey = dotenv.env['ADZUNA_APP_KEY'];

    final uri = Uri.parse('$_baseUrl/$_country/search/$page').replace(
      queryParameters: {
        'app_id': appId,
        'app_key': appKey,
        'results_per_page': '$resultsPerPage',
        'what': query,
        if (location != null && location.isNotEmpty) 'where': location,
        'content-type': 'application/json',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Adzuna API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>? ?? []);

    return results
        .map((json) => JobModel.fromAdzuna(json as Map<String, dynamic>))
        .toList();
  }
}
