import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder logo — swap for the real JobPulse mark
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text('JobPulse', style: AppTypography.pageTitle),
            const SizedBox(height: 4),
            Text(
              'Opportunities that match you.',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: 32),
            authState.when(
              // Still resolving auth state — show a small loader
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => const SizedBox.shrink(),
              // Once resolved, the router (see main.dart) redirects
              // automatically — nothing to render here.
              data: (_) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
