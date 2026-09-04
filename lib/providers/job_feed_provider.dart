import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_preferences_model.dart';
import '../services/job_api/adzuna_service.dart';
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

final adzunaServiceProvider = Provider<AdzunaService>((ref) => AdzunaService());

/// Fetches jobs matching the user's preferences and returns them
/// scored + sorted, highest match first.
final jobFeedProvider = FutureProvider<List<ScoredJob>>((ref) async {
  final prefs = await ref.watch(savedPreferencesProvider.future);
  if (prefs == null || prefs.skills.isEmpty) return [];

  final service = ref.watch(adzunaServiceProvider);

  // Adzuna's "what" param works best as a simple keyword string —
  // joining top skills gives a reasonably relevant query.
  final query = prefs.skills.take(3).join(' ');
  final location = prefs.cities.isNotEmpty ? prefs.cities.first : null;

  final jobs = await service.fetchJobs(query: query, location: location);
  return MatchingEngine.scoreAndSort(jobs, prefs);
});
