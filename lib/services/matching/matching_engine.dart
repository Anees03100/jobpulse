import '../../models/job_model.dart';
import '../../models/user_preferences_model.dart';

class ScoredJob {
  const ScoredJob({required this.job, required this.score});
  final JobModel job;
  final int score; // 0-100
}

class MatchingEngine {
  MatchingEngine._();

  /// Simple weighted scoring — no AI/semantic matching yet (per the plan,
  /// this is the placeholder to upgrade later).
  static ScoredJob score(JobModel job, UserPreferences prefs) {
    double points = 0;
    double maxPoints = 0;

    // Skills overlap — biggest weight (50%)
    maxPoints += 50;
    if (prefs.skills.isNotEmpty) {
      final jobSkillsLower = job.skills.map((s) => s.toLowerCase()).toSet();
      final prefSkillsLower = prefs.skills.map((s) => s.toLowerCase()).toSet();
      final overlap = jobSkillsLower.intersection(prefSkillsLower).length;
      final ratio = overlap / prefSkillsLower.length;
      points += 50 * ratio.clamp(0, 1);
    }

    // Opportunity type match (20%)
    maxPoints += 20;
    if (prefs.opportunityTypes.isNotEmpty) {
      final typeMatches = prefs.opportunityTypes.any(
        (t) => job.type.toLowerCase().contains(t.toLowerCase()),
      );
      if (typeMatches) points += 20;
    }

    // Location match (20%)
    maxPoints += 20;
    if (prefs.remote && job.isRemote) {
      points += 20;
    } else if (prefs.cities.isNotEmpty) {
      final locationMatches = prefs.cities.any(
        (c) => job.location.toLowerCase().contains(c.toLowerCase()),
      );
      if (locationMatches) points += 20;
    }

    // Recency bonus (10%) — newer postings score slightly higher
    maxPoints += 10;
    final daysOld = DateTime.now().difference(job.postedAt).inDays;
    if (daysOld <= 1) {
      points += 10;
    } else if (daysOld <= 7) {
      points += 6;
    } else if (daysOld <= 30) {
      points += 3;
    }

    final finalScore = maxPoints == 0
        ? 0
        : ((points / maxPoints) * 100).round();
    return ScoredJob(job: job, score: finalScore.clamp(0, 100));
  }

  /// Scores and sorts a whole list, highest match first.
  static List<ScoredJob> scoreAndSort(
    List<JobModel> jobs,
    UserPreferences prefs,
  ) {
    final scored = jobs.map((job) => score(job, prefs)).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  /// Human-readable reasons for the "Why this matches you" section.
  static List<String> matchReasons(JobModel job, UserPreferences prefs) {
    final reasons = <String>[];

    final jobSkillsLower = job.skills.map((s) => s.toLowerCase()).toSet();
    final matchedSkills = prefs.skills
        .where((s) => jobSkillsLower.contains(s.toLowerCase()))
        .toList();
    if (matchedSkills.isNotEmpty) {
      reasons.add('${matchedSkills.join(', ')} matches your skills');
    }

    final matchedType = prefs.opportunityTypes
        .where((t) => job.type.toLowerCase().contains(t.toLowerCase()))
        .firstOrNull;
    if (matchedType != null) {
      reasons.add('$matchedType matches your preference');
    }

    if (prefs.remote && job.isRemote) {
      reasons.add('Remote matches your work preference');
    } else {
      final matchedCity = prefs.cities
          .where((c) => job.location.toLowerCase().contains(c.toLowerCase()))
          .firstOrNull;
      if (matchedCity != null) {
        reasons.add('$matchedCity matches your location');
      }
    }

    return reasons;
  }
}
