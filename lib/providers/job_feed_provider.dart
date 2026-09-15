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
  final location = prefs.remote
      ? null // omit location to widen results when remote is preferred
      : (prefs.cities.isNotEmpty ? prefs.cities.first : prefs.country);

  debugPrint(
    '🔍 Fetching jobs with keywords="$keywords" and location="$location"',
  );

  final jobs = await service.fetchJobs(keywords: keywords, location: location);
  return MatchingEngine.scoreAndSort(jobs, prefs);
});
