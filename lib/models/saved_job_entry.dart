import 'job_model.dart';

class SavedJobEntry {
  const SavedJobEntry({required this.job, required this.status});

  final JobModel job;
  final String
  status; // Saved | Applied | Interview | Rejected | Offer | Archived

  factory SavedJobEntry.fromMap(Map<String, dynamic> map) {
    return SavedJobEntry(
      job: JobModel.fromMap(map),
      status: map['status'] ?? 'Saved',
    );
  }
}
