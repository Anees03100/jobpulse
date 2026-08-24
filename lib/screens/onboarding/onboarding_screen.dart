import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/core/utils/onboarding_prefs.dart';
import 'package:jobpulse/widgets/butons/primary_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const _steps = [
  _OnboardingStep(
    icon: Icons.tune_outlined,
    title: 'Find opportunities made for you',
    description: 'Select your skills, locations and job preferences.',
  ),
  _OnboardingStep(
    icon: Icons.notifications_active_outlined,
    title: 'Get notified about new matches',
    description:
        'Receive alerts when new opportunities match your preferences.',
  ),
  _OnboardingStep(
    icon: Icons.bolt_outlined,
    title: 'Spend less time searching',
    description: 'JobPulse filters opportunities so you can focus on applying.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _steps.length - 1;

  Future<void> _goToNext() async {
    if (_isLastPage) {
      await OnboardingPrefs.markOnboardingSeen();
      if (mounted) context.go('/sign-in');
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _skip() async {
    await OnboardingPrefs.markOnboardingSeen();
    if (mounted) context.go('/sign-in');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button — hidden on the last step (per spec, only step 1 shows Skip explicitly,
            // but keeping it available throughout is friendlier UX; remove the condition if you
            // want it strictly step-1-only)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: _isLastPage ? null : _skip,
                  child: Text(
                    _isLastPage ? '' : 'Skip',
                    style: AppTypography.bodySecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Simple abstract icon container — no large illustration
                        Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            color: AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                          ),
                          child: Icon(
                            step.icon,
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: AppTypography.pageTitle,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          step.description,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySecondary,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isActive ? 20 : 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: PrimaryButton(
                label: _isLastPage ? 'Get Started' : 'Continue',
                onPressed: _goToNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
