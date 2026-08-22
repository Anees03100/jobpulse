import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onRemove,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onRemove; // shows an "x" when provided (e.g. skill chips)

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.background,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected && onRemove == null) ...[
              const Icon(Icons.check, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.metadata.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.close,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
