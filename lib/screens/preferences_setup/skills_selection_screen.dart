import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/widgets/butons/primary_button.dart';
import 'package:jobpulse/widgets/cards/selectable_chip.dart';
import '../../providers/user_preferences_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/inputs/app_text_field.dart';

const _skillCategories = {
  'Development': [
    'Flutter',
    'Dart',
    'Web Development',
    'React',
    'Node.js',
    'Java',
    'Python',
    'PHP',
    'Android',
    'iOS',
  ],
  'Design': ['UI/UX', 'Graphic Design', 'Figma', 'Adobe XD'],
  'Data & AI': ['Artificial Intelligence', 'Machine Learning', 'Data Science'],
};

class SkillsSelectionScreen extends ConsumerStatefulWidget {
  const SkillsSelectionScreen({super.key});

  @override
  ConsumerState<SkillsSelectionScreen> createState() =>
      _SkillsSelectionScreenState();
}

class _SkillsSelectionScreenState extends ConsumerState<SkillsSelectionScreen> {
  final Set<String> _selected = {};
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected.addAll(ref.read(preferencesDraftProvider).skills);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_selected.isEmpty) return;
    ref.read(preferencesDraftProvider.notifier).setSkills(_selected.toList());
    context.push('/preferences/location');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What are you interested in?',
                    style: AppTypography.pageTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Select the skills and categories you want to track.',
                    style: AppTypography.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _searchController,
                    hint: 'Search skills',
                    prefixIcon: Icons.search,
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${_selected.length} skills selected',
                    style: AppTypography.metadata,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  100,
                ),
                children: _skillCategories.entries.map((entry) {
                  final visibleSkills = entry.value
                      .where((s) => s.toLowerCase().contains(_query))
                      .toList();
                  if (visibleSkills.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: AppTypography.sectionHeading),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: visibleSkills.map((skill) {
                            final isSelected = _selected.contains(skill);
                            return SelectableChip(
                              label: skill,
                              selected: isSelected,
                              onTap: () => setState(() {
                                isSelected
                                    ? _selected.remove(skill)
                                    : _selected.add(skill);
                              }),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        color: AppColors.background,
        child: PrimaryButton(
          label: 'Continue',
          onPressed: _selected.isEmpty ? null : _continue,
        ),
      ),
    );
  }
}
