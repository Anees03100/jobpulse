import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobpulse/services/job_api/jooble_service.dart';
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

final jobFeedProvider = FutureProvider<List<ScoredJob>>((ref) async {
  final prefs = await ref.watch(savedPreferencesProvider.future);
  if (prefs == null || prefs.skills.isEmpty) return [];

  final service = ref.watch(joobleServiceProvider);
  final keywords = prefs.skills.take(3).join(' ');
  final city = prefs.remote
      ? null
      : (prefs.cities.isNotEmpty ? prefs.cities.first : prefs.country);

  var jobs = await service.fetchJobs(keywords: keywords, location: city);

  // Widen search if the city-specific query comes back empty
  if (jobs.isEmpty && city != null) {
    jobs = await service.fetchJobs(keywords: keywords, location: null);
  }

  return MatchingEngine.scoreAndSort(jobs, prefs);
});
