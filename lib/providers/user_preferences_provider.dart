import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_preferences_model.dart';
import 'auth_provider.dart';

/// Draft preferences being built across Opportunity Type → Skills → Location.
/// Only written to Firestore once, on the final screen.
class PreferencesDraftNotifier extends Notifier<UserPreferences> {
  @override
  UserPreferences build() => const UserPreferences();

  void setOpportunityTypes(List<String> types) {
    state = state.copyWith(opportunityTypes: types);
  }

  void setSkills(List<String> skills) {
    state = state.copyWith(skills: skills);
  }

  void setLocation({
    required String country,
    required List<String> cities,
    required bool remote,
    required bool hybrid,
  }) {
    state = state.copyWith(
      country: country,
      cities: cities,
      remote: remote,
      hybrid: hybrid,
    );
  }

  Future<void> saveToFirestore(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {...state.toMap(), 'preferencesSet': true},
      SetOptions(
        merge: true,
      ), // creates the doc if missing, updates if it exists
    );
  }
}

final preferencesDraftProvider =
    NotifierProvider<PreferencesDraftNotifier, UserPreferences>(
      PreferencesDraftNotifier.new,
    );

/// Reads whether the current user has completed preferences setup.
/// Used by the router to decide whether to send them to /preferences
/// or straight to /home. Refreshed on every auth state change.
final preferencesSetProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  return doc.data()?['preferencesSet'] == true;
});
