import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobpulse/widgets/butons/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/error_mapper.dart';
import '../../models/job_model.dart';
import '../../models/user_preferences_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_feed_provider.dart';
import '../../providers/saved_jobs_provider.dart';
import '../../services/matching/matching_engine.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/indicators/match_score_badge.dart';

class OpportunityDetailsScreen extends ConsumerWidget {
  const OpportunityDetailsScreen({
    super.key,
    required this.job,
    required this.score,
  });

  final JobModel job;
  final int score;

  String get _matchLabel {
    if (score >= 90) return 'Excellent Match';
    if (score >= 75) return 'Great Match';
    if (score >= 50) return 'Good Match';
    return 'Fair Match';
  }

  Future<void> _handleSave(
    BuildContext context,
    WidgetRef ref,
    bool isSaved,
  ) async {
    try {
      final uid = ref.read(authServiceProvider).currentUser!.uid;
      final service = ref.read(savedJobsServiceProvider);
      await toggleSaveJob(
        uid: uid,
        job: job,
        isSaved: isSaved,
        service: service,
      );
      if (context.mounted) {
        AppSnackbar.success(
          context,
          isSaved ? 'Removed from saved' : 'Saved to your opportunities',
        );
      }
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, ErrorMapper.map(e));
    }
  }

  Future<void> _openOriginal(BuildContext context) async {
    if (job.url.isEmpty) {
      AppSnackbar.error(context, 'Original listing link is unavailable.');
      return;
    }
    final uri = Uri.parse(job.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted)
        AppSnackbar.error(context, 'Could not open the listing.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedJobIdsProvider).value ?? {};
    final isSaved = savedIds.contains(job.id);
    final prefsAsync = ref.watch(savedPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? AppColors.primary : AppColors.textPrimary,
            ),
            onPressed: () => _handleSave(context, ref, isSaved),
          ),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(job.title, style: AppTypography.pageTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              job.company,
              style: AppTypography.sectionHeading.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(job.location, style: AppTypography.bodySecondary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${job.type}${job.isRemote ? ' · Remote' : ''}',
              style: AppTypography.bodySecondary,
            ),

            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Column(
                children: [MatchScoreCircle(score: score, label: _matchLabel)],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Why this matches you', style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            prefsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (prefs) {
                if (prefs == null) return const SizedBox.shrink();
                final reasons = MatchingEngine.matchReasons(job, prefs);
                if (reasons.isEmpty) {
                  return Text(
                    'General match based on your profile.',
                    style: AppTypography.bodySecondary,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: reasons
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(r, style: AppTypography.body),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            if (job.skills.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Skills', style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: job.skills
                    .map(
                      (s) => Chip(
                        label: Text(s, style: AppTypography.metadata),
                        backgroundColor: AppColors.lightBackground,
                        side: const BorderSide(color: AppColors.border),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            Text('About the opportunity', style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            Text(
              job.description.isNotEmpty
                  ? job.description
                  : 'No description provided.',
              style: AppTypography.body,
            ),

            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Text('Source: ', style: AppTypography.metadata),
                Text(
                  job.source,
                  style: AppTypography.metadata.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100), // space for sticky button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        color: AppColors.background,
        child: PrimaryButton(
          label: 'View Original Opportunity',
          onPressed: () => _openOriginal(context),
        ),
      ),
    );
  }
}
