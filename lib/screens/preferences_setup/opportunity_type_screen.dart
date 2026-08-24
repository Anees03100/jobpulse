import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/widgets/butons/primary_button.dart';
import 'package:jobpulse/widgets/cards/selectable_chip.dart';
import '../../providers/user_preferences_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

const _opportunityTypes = [
  'Internship',
  'Full-time',
  'Part-time',
  'Freelance',
  'Contract',
  'Remote',
];

class OpportunityTypeScreen extends ConsumerStatefulWidget {
  const OpportunityTypeScreen({super.key});

  @override
  ConsumerState<OpportunityTypeScreen> createState() =>
      _OpportunityTypeScreenState();
}

class _OpportunityTypeScreenState extends ConsumerState<OpportunityTypeScreen> {
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    // Restore any prior selection if the user is coming back to this step
    _selected.addAll(ref.read(preferencesDraftProvider).opportunityTypes);
  }

  void _continue() {
    if (_selected.isEmpty) return;
    ref
        .read(preferencesDraftProvider.notifier)
        .setOpportunityTypes(_selected.toList());
    context.push('/preferences/skills');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Let's personalize your opportunities",
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Step 1 of 4', style: AppTypography.metadata),
              const SizedBox(height: AppSpacing.lg),
              Text('Opportunity Type', style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _opportunityTypes.map((type) {
                  final isSelected = _selected.contains(type);
                  return SelectableChip(
                    label: type,
                    selected: isSelected,
                    onTap: () => setState(() {
                      isSelected ? _selected.remove(type) : _selected.add(type);
                    }),
                  );
                }).toList(),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                onPressed: _selected.isEmpty ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
