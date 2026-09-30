import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/providers/job_feed_provider.dart';
import 'package:jobpulse/providers/nav_provider.dart';
import 'package:jobpulse/screens/home/home_header.dart';
import '../../providers/auth_provider.dart';
import '../../providers/saved_jobs_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/opportunity_card.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        ref.watch(authStateProvider).value?.displayName?.split(' ').first ??
        'there';
    final jobFeed = ref.watch(jobFeedProvider);
    final savedIds = ref.watch(savedJobIdsProvider).value ?? {};

    return Scaffold(
      backgroundColor:
          AppColors.lightBackground, // light bg makes white cards pop
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          HomeHeader(name: name),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatBlock(value: '24', label: 'New Matches'),
                    _StatBlock(value: '92%', label: 'Best Match'),
                    _StatBlock(value: '8', label: 'Saved'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                jobFeed.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Something went wrong',
                          style: AppTypography.sectionHeading,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          "We couldn't load new opportunities.",
                          style: AppTypography.bodySecondary,
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
                              style: AppTypography.sectionHeading,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              "We're watching for opportunities that match your preferences.",
                              style: AppTypography.bodySecondary,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Popular Jobs',
                              style: AppTypography.sectionHeading,
                            ),
                            TextButton(
                              onPressed: () =>
                                  ref
                                          .read(
                                            currentTabIndexProvider.notifier,
                                          )
                                          .state =
                                      1,
                              child: const Text('See more'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...scoredJobs.map(
                          (scored) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: OpportunityCard(
                              title: scored.job.title,
                              company: scored.job.company,
                              location: scored.job.location,
                              type: scored.job.type,
                              matchScore: scored.score,
                              postedTime: _timeAgo(scored.job.postedAt),
                              skills: scored.job.skills,
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
                                final service = ref.read(
                                  savedJobsServiceProvider,
                                );
                                final isSaved = savedIds.contains(
                                  scored.job.id,
                                );
                                await toggleSaveJob(
                                  uid: uid,
                                  job: scored.job,
                                  isSaved: isSaved,
                                  service: service,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.pageTitle.copyWith(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.metadata,
            textAlign: TextAlign.center,
          ),
        ],
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
