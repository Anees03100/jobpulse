import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/providers/job_feed_provider.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/error_mapper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out of JobPulse?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authServiceProvider).signOut();
      ref.invalidate(preferencesSetProvider);
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, ErrorMapper.map(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final prefsAsync = ref.watch(savedPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile', style: AppTypography.sectionHeading),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Header ──────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0]
                            : '?')
                        .toUpperCase(),
                    style: AppTypography.pageTitle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'JobPulse User',
                        style: AppTypography.sectionHeading,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.bodySecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── My Preferences summary ──────────────────────────────────
            Text('My Preferences', style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            prefsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Text(
                'Could not load preferences.',
                style: AppTypography.bodySecondary,
              ),
              data: (prefs) {
                if (prefs == null) {
                  return Text(
                    'No preferences set yet.',
                    style: AppTypography.bodySecondary,
                  );
                }
                return _PreferencesCard(prefs: prefs);
              },
            ),

            const SizedBox(height: AppSpacing.lg),
            _SectionTile(
              icon: Icons.tune,
              label: 'Edit Preferences',
              onTap: () => context.push('/preferences/opportunity-type'),
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Account', style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            _SectionTile(
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () {},
            ),
            _SectionTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy',
              onTap: () {},
            ),
            _SectionTile(
              icon: Icons.description_outlined,
              label: 'Terms',
              onTap: () {},
            ),
            _SectionTile(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () {},
            ),

            const SizedBox(height: AppSpacing.lg),
            _SectionTile(
              icon: Icons.logout,
              label: 'Log Out',
              isDestructive: true,
              onTap: () => _handleLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.prefs});
  final dynamic prefs; // UserPreferences

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      ...prefs.opportunityTypes,
      ...prefs.skills.take(4),
      ...prefs.cities,
      if (prefs.remote) 'Remote',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: chips
            .map(
              (c) => Chip(
                label: Text(c, style: AppTypography.metadata),
                backgroundColor: AppColors.lightBackground,
                side: const BorderSide(color: AppColors.border),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: AppTypography.body.copyWith(color: color)),
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
