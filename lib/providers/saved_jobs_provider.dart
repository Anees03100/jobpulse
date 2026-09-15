import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../models/saved_job_entry.dart';
import '../services/firebase/saved_jobs_service.dart';
import 'auth_provider.dart';

final savedJobsServiceProvider = Provider<SavedJobsService>(
  (ref) => SavedJobsService(),
);

final savedJobIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(<String>{});
  return ref.watch(savedJobsServiceProvider).savedJobIds(user.uid);
});

/// Full saved job entries (job data + status) for the Saved screen.
final savedJobEntriesProvider = StreamProvider<List<SavedJobEntry>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(<SavedJobEntry>[]);
  return ref
      .watch(savedJobsServiceProvider)
      .savedJobsStream(user.uid)
      .map((docs) => docs.map((d) => SavedJobEntry.fromMap(d)).toList());
});

Future<void> toggleSaveJob({
  required String uid,
  required JobModel job,
  required bool isSaved,
  required SavedJobsService service,
}) {
  return isSaved ? service.removeJob(uid, job.id) : service.saveJob(uid, job);
}
