import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/job_model.dart';

class SavedJobsService {
  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('savedJobs');
  }

  Future<void> saveJob(String uid, JobModel job) {
    return _collection(uid).doc(job.id).set({
      ...job.toMap(),
      'savedAt': FieldValue.serverTimestamp(),
      'status': 'Saved', // Saved | Applied | Interview | Rejected | Offer
    });
  }

  Future<void> removeJob(String uid, String jobId) {
    return _collection(uid).doc(jobId).delete();
  }

  Stream<Set<String>> savedJobIds(String uid) {
    return _collection(
      uid,
    ).snapshots().map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  /// Streams full saved job entries (not just IDs) — used by the Saved screen.
  Stream<List<Map<String, dynamic>>> savedJobsStream(String uid) {
    return _collection(uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
        );
  }

  Future<void> updateStatus(String uid, String jobId, String status) {
    return _collection(uid).doc(jobId).update({'status': status});
  }
}
