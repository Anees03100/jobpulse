import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nav_provider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 20, AppSpacing.lg, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171717), Color(0xFFF57D0A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleIconButton(
                  icon: Icons.grid_view_rounded,
                  onTap: () =>
                      ref.read(currentTabIndexProvider.notifier).state = 3,
                ),
                _CircleIconButton(
                  icon: Icons.notifications_none,
                  showDot: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Hi, $name 👋',
              style: AppTypography.body.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Discover Your\nBest Opportunity',
              style: AppTypography.pageTitle.copyWith(
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () => ref.read(currentTabIndexProvider.notifier).state =
                  1, // jump to Discover
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Search job',
                      style: AppTypography.body.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (showDot)
              const Positioned(
                right: 10,
                top: 10,
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Color(0xFFF57D0A),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
