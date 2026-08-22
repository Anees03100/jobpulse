import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Compact badge, e.g. "94% Match" — used on cards and detail screens.
class MatchScoreBadge extends StatelessWidget {
  const MatchScoreBadge({super.key, required this.score, this.compact = true});

  final int score; // 0-100
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        compact ? '$score% Match' : '$score%',
        style: AppTypography.matchScore.copyWith(fontSize: compact ? 12 : 20),
      ),
    );
  }
}

/// Larger circular version for the Opportunity Details screen.
class MatchScoreCircle extends StatelessWidget {
  const MatchScoreCircle({
    super.key,
    required this.score,
    this.label = 'Excellent Match',
  });

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 96,
          width: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 96,
                width: 96,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              Text(
                '$score%',
                style: AppTypography.pageTitle.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: AppTypography.bodySecondary),
      ],
    );
  }
}
