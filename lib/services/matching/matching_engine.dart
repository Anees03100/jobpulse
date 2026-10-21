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
    final jobLocLower = job.location.toLowerCase();
    if (prefs.remote && job.isRemote) {
      points += 20;
    } else if (prefs.cities.isNotEmpty) {
      // Direct city match (e.g. Rawalpindi)
      final directCityMatch = prefs.cities.any(
        (c) => jobLocLower.contains(c.toLowerCase()),
      );
      if (directCityMatch) {
        points += 20;
      } else {
        // Twin-city check (Rawalpindi <-> Islamabad)
        final isTwinCityMatch = prefs.cities.any((c) {
          final cl = c.toLowerCase();
          return (cl == 'rawalpindi' && jobLocLower.contains('islamabad')) ||
              (cl == 'islamabad' && jobLocLower.contains('rawalpindi'));
        });
        if (isTwinCityMatch) {
          points += 18;
        } else if (jobLocLower.contains('pakistan')) {
          points += 14;
        }
      }
    } else if (prefs.country != null &&
        jobLocLower.contains(prefs.country!.toLowerCase())) {
      points += 16;
    }

    // Recency bonus (10%) — newer postings score slightly higher
    maxPoints += 10;
    final daysOld = DateTime.now().difference(job.postedAt).inDays;
    if (daysOld <= 1) {
      points += 10;
    } else if (daysOld <= 7) {
      points += 7;
    } else if (daysOld <= 14) {
      points += 5;
    } else if (daysOld <= 30) {
      points += 2;
    }

    final finalScore = maxPoints == 0
        ? 0
        : ((points / maxPoints) * 100).round();
    return ScoredJob(job: job, score: finalScore.clamp(0, 100));
  }

  /// Validates whether a job matches the user's location preferences (e.g. Pakistan / Rawalpindi).
  static bool isLocationEligible(JobModel job, UserPreferences prefs) {
    final jobLoc = job.location.toLowerCase();
    final prefCountry = (prefs.country ?? 'Pakistan').toLowerCase();

    // 1. Foreign location rejection (reject US states/cities, UK, etc. unless explicitly in Pakistan)
    const foreignIndicators = [
      ', ca',
      ', va',
      ', nj',
      ', ny',
      ', tx',
      ', fl',
      ', wa',
      ', il',
      ', oh',
      ', pa',
      ', ga',
      ', nc',
      ', mi',
      'united states',
      'usa',
      'united kingdom',
      'london, uk',
      'australia',
      'canada',
      'germany',
      'india',
    ];

    final isForeign = foreignIndicators.any((f) => jobLoc.contains(f));
    if (isForeign && !jobLoc.contains(prefCountry)) {
      return false;
    }

    // 2. If it's a remote job:
    if (job.isRemote) {
      return prefs.remote;
    }

    // 3. In-person location check
    // If the job location contains the user's preferred country
    final matchesCountry = jobLoc.contains(prefCountry);

    if (prefs.cities.isNotEmpty) {
      final matchesCity = prefs.cities.any((c) => jobLoc.contains(c.toLowerCase()));
      if (matchesCity) return true;

      // Twin city compatibility (Rawalpindi <-> Islamabad)
      final hasTwinCity = prefs.cities.any((c) {
        final cl = c.toLowerCase();
        return cl == 'rawalpindi' || cl == 'islamabad';
      });
      if (hasTwinCity &&
          (jobLoc.contains('rawalpindi') || jobLoc.contains('islamabad'))) {
        return true;
      }

      // If city didn't directly match, but it's in Pakistan
      return matchesCountry;
    }

    return matchesCountry;
  }

  /// Filters by location and max age, scores, and sorts newest/recent first.
  static List<ScoredJob> scoreAndSort(
    List<JobModel> jobs,
    UserPreferences prefs,
  ) {
    final now = DateTime.now();

    // 1. Filter: Location must be eligible AND job must not be stale (max 45 days old)
    final eligibleJobs = jobs.where((job) {
      if (!isLocationEligible(job, prefs)) return false;

      final ageDays = now.difference(job.postedAt).inDays;
      // Filter out stale jobs older than 45 days
      if (ageDays > 45) return false;

      return true;
    }).toList();

    // 2. Score jobs
    final scored = eligibleJobs.map((job) => score(job, prefs)).toList();

    // 3. Sort: RECENT LISTED JOBS ON TOP (newest postedAt first),
    // and if posted on the same day, by match score.
    scored.sort((a, b) {
      final dateCompare = b.job.postedAt.compareTo(a.job.postedAt);
      if (dateCompare != 0) return dateCompare;
      return b.score.compareTo(a.score);
    });

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
