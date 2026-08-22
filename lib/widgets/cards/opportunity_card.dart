import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_card.dart';
import '../indicators/match_score_badge.dart';

class OpportunityCard extends StatelessWidget {
  const OpportunityCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.matchScore,
    required this.postedTime,
    this.skills = const [],
    this.isSaved = false,
    this.onTap,
    this.onSaveToggle,
  });

  final String title;
  final String company;
  final String location;
  final String type;
  final int matchScore;
  final String postedTime;
  final List<String> skills;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onSaveToggle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Company logo placeholder
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.business,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      company,
                      style: AppTypography.bodySecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSaveToggle,
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(location, style: AppTypography.metadata),
              const SizedBox(width: AppSpacing.sm),
              Text('· $type', style: AppTypography.metadata),
            ],
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(skills.join(' · '), style: AppTypography.metadata),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MatchScoreBadge(score: matchScore),
              Text(postedTime, style: AppTypography.metadata),
            ],
          ),
        ],
      ),
    );
  }
}
