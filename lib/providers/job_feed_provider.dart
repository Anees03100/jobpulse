import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobpulse/services/job_api/jooble_service.dart';
import 'package:jobpulse/services/job_api/pakistan_jobs_service.dart';
import '../models/job_model.dart';
import '../models/user_preferences_model.dart';
import '../services/matching/matching_engine.dart';
import 'auth_provider.dart';

/// Fetches the current user's saved preferences from Firestore.
final savedPreferencesProvider = FutureProvider<UserPreferences?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  final data = doc.data();
  if (data == null || data['preferencesSet'] != true) return null;

  return UserPreferences(
    opportunityTypes: List<String>.from(data['opportunityTypes'] ?? []),
    skills: List<String>.from(data['skills'] ?? []),
    country: data['country'],
    cities: List<String>.from(data['cities'] ?? []),
    remote: data['remote'] ?? false,
    hybrid: data['hybrid'] ?? false,
  );
});

final joobleServiceProvider = Provider<JoobleService>((ref) => JoobleService());
final pakistanJobsServiceProvider =
    Provider<PakistanJobsService>((ref) => PakistanJobsService());

final jobFeedProvider = FutureProvider<List<ScoredJob>>((ref) async {
  final prefs = await ref.watch(savedPreferencesProvider.future);
  if (prefs == null || prefs.skills.isEmpty) return [];

  final pkService = ref.watch(pakistanJobsServiceProvider);
  final joobleService = ref.watch(joobleServiceProvider);

  final allJobs = <JobModel>[];
  final seenIds = <String>{};

  // 1. Fetch live and curated Pakistan jobs (with Rawalpindi / Islamabad focus)
  try {
    final pkJobs = await pkService.fetchJobs(
      skills: prefs.skills,
      cities: prefs.cities,
      remote: prefs.remote,
    );
    for (final job in pkJobs) {
      if (seenIds.add(job.id)) {
        allJobs.add(job);
      }
    }
  } catch (e) {
    debugPrint('Error fetching Pakistan jobs: $e');
  }

  // 2. Fetch from Jooble with location restricted to user's city/country
  final city = prefs.cities.isNotEmpty ? prefs.cities.first : prefs.country;
  if (city != null) {
    try {
      final keywords = prefs.skills.take(2).join(' ');
      final locationQuery = '$city, Pakistan';
      final joobleJobs = await joobleService.fetchJobs(
        keywords: keywords,
        location: locationQuery,
      );
      for (final job in joobleJobs) {
        if (seenIds.add(job.id)) {
          allJobs.add(job);
        }
      }
    } catch (e) {
      debugPrint('Error fetching Jooble jobs: $e');
    }
  }

  // MatchingEngine filters out foreign/ineligible locations, removes stale
  // postings older than 45 days, and places recent listings on top.
  return MatchingEngine.scoreAndSort(allJobs, prefs);
});
