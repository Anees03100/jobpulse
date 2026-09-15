import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/matching/matching_engine.dart';
import 'job_feed_provider.dart';

final discoverQueryProvider = StateProvider<String>((ref) => '');

final discoverResultsProvider = FutureProvider<List<ScoredJob>>((ref) async {
  final query = ref.watch(discoverQueryProvider).trim();
  if (query.isEmpty) return [];

  final prefs = await ref.watch(savedPreferencesProvider.future);
  final service = ref.watch(joobleServiceProvider);

  final city = prefs?.cities.isNotEmpty == true ? prefs!.cities.first : null;

  // Try with the city filter first for relevance...
  var jobs = await service.fetchJobs(keywords: query, location: city);

  // ...but if that comes back empty, widen the search rather than
  // showing a dead end. Real job data is sparse for narrow city+keyword
  // combos, so a country-wide (or unfiltered) retry gives a much better
  // chance of showing something useful.
  if (jobs.isEmpty && city != null) {
    jobs = await service.fetchJobs(keywords: query, location: null);
  }

  return prefs != null
      ? MatchingEngine.scoreAndSort(jobs, prefs)
      : jobs.map((j) => ScoredJob(job: j, score: 0)).toList();
});
