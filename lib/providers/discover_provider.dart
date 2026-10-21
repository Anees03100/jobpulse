import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/job_model.dart';
import '../models/user_preferences_model.dart';
import '../services/matching/matching_engine.dart';
import 'job_feed_provider.dart';

final discoverQueryProvider = StateProvider<String>((ref) => '');

final discoverResultsProvider = FutureProvider<List<ScoredJob>>((ref) async {
  final query = ref.watch(discoverQueryProvider).trim();
  if (query.isEmpty) return [];

  final prefs = await ref.watch(savedPreferencesProvider.future);
  final pkService = ref.watch(pakistanJobsServiceProvider);
  final joobleService = ref.watch(joobleServiceProvider);

  final allJobs = <JobModel>[];
  final seenIds = <String>{};

  // 1. Fetch from Pakistan jobs service using search query
  try {
    final pkJobs = await pkService.fetchJobs(
      skills: prefs?.skills ?? [query],
      cities: prefs?.cities ?? ['Rawalpindi', 'Islamabad'],
      remote: prefs?.remote ?? false,
      query: query,
    );
    for (final job in pkJobs) {
      if (seenIds.add(job.id)) {
        allJobs.add(job);
      }
    }
  } catch (e) {
    debugPrint('Discover PakistanJobsService error: $e');
  }

  // 2. Fetch from Jooble with location restricted to user's city
  final city = prefs?.cities.isNotEmpty == true
      ? prefs!.cities.first
      : (prefs?.country ?? 'Pakistan');
  try {
    final joobleJobs = await joobleService.fetchJobs(
      keywords: query,
      location: '$city, Pakistan',
    );
    for (final job in joobleJobs) {
      if (seenIds.add(job.id)) {
        allJobs.add(job);
      }
    }
  } catch (e) {
    debugPrint('Discover JoobleService error: $e');
  }

  final effectivePrefs = prefs ??
      const UserPreferences(
        country: 'Pakistan',
        cities: ['Rawalpindi'],
      );

  return MatchingEngine.scoreAndSort(allJobs, effectivePrefs);
});
