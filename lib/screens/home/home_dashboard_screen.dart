import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobpulse/providers/job_feed_provider.dart';
import 'package:jobpulse/providers/user_preferences_provider.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/error_mapper.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/opportunity_card.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authServiceProvider).signOut();
      ref.invalidate(preferencesSetProvider);
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, ErrorMapper.map(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authStateProvider).value?.displayName ?? 'there';
    final jobFeed = ref.watch(jobFeedProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            100,
          ),
          children: [
            // ── Header ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good afternoon, $name 👋',
                        style: AppTypography.sectionHeading,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Here are your latest opportunities.',
                        style: AppTypography.bodySecondary,
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none, size: 26),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── TEMP: logout button — remove once Profile screen has its own ──
            OutlinedButton.icon(
              onPressed: () => _handleLogout(context, ref),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log out (temp)'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Match summary ──────────────────────────────────
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
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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

                final best = scoredJobs.first;
                final rest = scoredJobs.skip(1).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        'BEST MATCH',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OpportunityCard(
                      title: best.job.title,
                      company: best.job.company,
                      location: best.job.location,
                      type: best.job.type,
                      matchScore: best.score,
                      postedTime: _timeAgo(best.job.postedAt),
                      skills: best.job.skills,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New for you',
                          style: AppTypography.sectionHeading,
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Filter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...rest.map(
                      (scored) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: OpportunityCard(
                          title: scored.job.title,
                          company: scored.job.company,
                          location: scored.job.location,
                          type: scored.job.type,
                          matchScore: scored.score,
                          postedTime: _timeAgo(scored.job.postedAt),
                          skills: scored.job.skills,
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
