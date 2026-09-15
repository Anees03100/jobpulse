import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../services/firebase/saved_jobs_service.dart';
import 'auth_provider.dart';

final savedJobsServiceProvider = Provider<SavedJobsService>(
  (ref) => SavedJobsService(),
);

/// Live set of saved job IDs for the current user — drives the
/// bookmark icon's filled/unfilled state across every card.
final savedJobIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(<String>{});
  return ref.watch(savedJobsServiceProvider).savedJobIds(user.uid);
});

/// Toggles save state for a job, given its current saved status.
Future<void> toggleSaveJob({
  required String uid,
  required JobModel job,
  required bool isSaved,
  required SavedJobsService service,
}) {
  return isSaved ? service.removeJob(uid, job.id) : service.saveJob(uid, job);
}
