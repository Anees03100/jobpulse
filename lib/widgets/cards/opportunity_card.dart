import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_card.dart';
import '../indicators/match_score_badge.dart';

const _avatarColors = [
  Color(0xFFF57D0A),
  Color(0xFF2E8B57),
  Color(0xFF4A6FA5),
  Color(0xFF9B59B6),
  Color(0xFFD64545),
];

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

  Color get _avatarColor {
    final hash = company.hashCode.abs();
    return _avatarColors[hash % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _avatarColor.withValues(alpha: 0.15),
                child: Text(
                  company.isNotEmpty ? company[0].toUpperCase() : '?',
                  style: AppTypography.body.copyWith(
                    color: _avatarColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  company,
                  style: AppTypography.bodySecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onSaveToggle,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 16,
                    color: isSaved
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.cardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: AppTypography.metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(type, style: AppTypography.metadata),
              ),
              const Spacer(),
              MatchScoreBadge(score: matchScore),
            ],
          ),
          if (postedTime.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(postedTime, style: AppTypography.metadata),
          ],
        ],
      ),
    );
  }
}
