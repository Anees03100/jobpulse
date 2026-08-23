import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/error_mapper.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/opportunity_card.dart';
import '../../widgets/indicators/match_score_badge.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, ErrorMapper.map(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authStateProvider).value?.displayName ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            100, // bottom pad for floating nav
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

            // ── Featured opportunity ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
            const OpportunityCard(
              title: 'Flutter Developer Intern',
              company: 'TechNova Solutions',
              location: 'Islamabad, Pakistan',
              type: 'Internship',
              matchScore: 94,
              postedTime: '18 min ago',
              skills: ['Flutter', 'Dart', 'Firebase'],
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── New opportunities feed ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New for you', style: AppTypography.sectionHeading),
                TextButton(onPressed: () {}, child: const Text('Filter')),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const OpportunityCard(
              title: 'Junior Flutter Developer',
              company: 'XYZ Technologies',
              location: 'Rawalpindi · Remote',
              type: 'Full-time',
              matchScore: 89,
              postedTime: '2h ago',
              skills: ['Flutter', 'Riverpod'],
            ),
            const SizedBox(height: AppSpacing.sm),
            const OpportunityCard(
              title: 'Frontend Developer Intern',
              company: 'Systems Limited',
              location: 'Islamabad · On-site',
              type: 'Internship',
              matchScore: 81,
              postedTime: '5h ago',
              skills: ['React', 'JavaScript'],
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
