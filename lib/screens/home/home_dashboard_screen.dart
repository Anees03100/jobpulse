import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jobpulse/providers/job_feed_provider.dart';
import 'package:jobpulse/providers/nav_provider.dart';
import 'package:jobpulse/screens/home/home_header.dart';
import '../../providers/auth_provider.dart';
import '../../providers/saved_jobs_provider.dart';
import '../../services/matching/matching_engine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        ref.watch(authStateProvider).value?.displayName?.split(' ').first ??
        'there';
    final jobFeed = ref.watch(jobFeedProvider);
    final savedIds = ref.watch(savedJobIdsProvider).value ?? {};

    final jobsList = jobFeed.value ?? [];
    final matchCount = jobsList.length;
    final bestScore = jobsList.isNotEmpty
        ? '${jobsList.map((j) => j.score).reduce((a, b) => a > b ? a : b)}%'
        : '--';

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── Header (greeting + stats + search) ──────────────────────
          HomeHeader(
            name: name,
            matchCount: matchCount,
            bestScore: bestScore,
            savedCount: savedIds.length,
          ),

          // ── Body content ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: jobFeed.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      'Something went wrong',
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "We couldn't load new opportunities.",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(jobFeedProvider),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
              data: (scoredJobs) {
                if (scoredJobs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'No matching opportunities yet',
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          "We're watching for opportunities that match your preferences.",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final topPick = scoredJobs.first;
                final latestJobs = scoredJobs.skip(1).take(8).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── TOP PICK orange card ───────────────────────
                    _TopPickCard(
                      scored: topPick,
                      isSaved: savedIds.contains(topPick.job.id),
                      onTap: () => context.push(
                        '/opportunity-details',
                        extra: {
                          'job': topPick.job,
                          'score': topPick.score,
                        },
                      ),
                      onSaveToggle: () async {
                        final uid = ref
                            .read(authServiceProvider)
                            .currentUser!
                            .uid;
                        final service = ref.read(savedJobsServiceProvider);
                        final isSaved = savedIds.contains(topPick.job.id);
                        await toggleSaveJob(
                          uid: uid,
                          job: topPick.job,
                          isSaved: isSaved,
                          service: service,
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── "Latest for you" section ───────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Latest for you',
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref
                              .read(currentTabIndexProvider.notifier)
                              .state = 1,
                          child: Text(
                            'See all',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Latest job list ────────────────────────────
                    ...latestJobs.map(
                      (scored) => _LatestJobRow(
                        scored: scored,
                        isSaved: savedIds.contains(scored.job.id),
                        onTap: () => context.push(
                          '/opportunity-details',
                          extra: {
                            'job': scored.job,
                            'score': scored.score,
                          },
                        ),
                        onSaveToggle: () async {
                          final uid = ref
                              .read(authServiceProvider)
                              .currentUser!
                              .uid;
                          final service = ref.read(savedJobsServiceProvider);
                          final isSaved = savedIds.contains(scored.job.id);
                          await toggleSaveJob(
                            uid: uid,
                            job: scored.job,
                            isSaved: isSaved,
                            service: service,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Pick Card ──────────────────────────────────────────────────────────
class _TopPickCard extends StatelessWidget {
  const _TopPickCard({
    required this.scored,
    required this.isSaved,
    required this.onTap,
    required this.onSaveToggle,
  });

  final ScoredJob scored;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;

  @override
  Widget build(BuildContext context) {
    final job = scored.job;
    final score = scored.score;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: TOP PICK badge + bookmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'TOP PICK',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onSaveToggle,
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Job title
            Text(
              job.title,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            // Company · location
            Text(
              '${job.company} · ${job.location}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),

            const SizedBox(height: 4),

            // Type · time ago
            Text(
              '${job.type} · ${_timeAgo(job.postedAt)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 16),

            // Progress bar + match label
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 5,
                      backgroundColor: Colors.black.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$score% match',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Latest Job Row ────────────────────────────────────────────────────────
const _avatarColors = [
  Color(0xFFF57D0A),
  Color(0xFF2E8B57),
  Color(0xFF4A6FA5),
  Color(0xFF9B59B6),
  Color(0xFFD64545),
];

class _LatestJobRow extends StatelessWidget {
  const _LatestJobRow({
    required this.scored,
    required this.isSaved,
    required this.onTap,
    required this.onSaveToggle,
  });

  final ScoredJob scored;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;

  Color get _avatarColor {
    final hash = scored.job.company.hashCode.abs();
    return _avatarColors[hash % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final job = scored.job;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Company letter avatar
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: _avatarColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  job.company.isNotEmpty ? job.company[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title + company · time ago
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${job.company} · ${_timeAgo(job.postedAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Bookmark icon
            GestureDetector(
              onTap: onSaveToggle,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                  color: isSaved
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

