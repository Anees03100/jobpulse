import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/widgets/butons/primary_button.dart';
import 'package:jobpulse/widgets/cards/selectable_chip.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/error_mapper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

const _country = 'Pakistan';
const _cities = ['Islamabad', 'Rawalpindi', 'Lahore', 'Karachi', 'Peshawar'];

class LocationPreferencesScreen extends ConsumerStatefulWidget {
  const LocationPreferencesScreen({super.key});

  @override
  ConsumerState<LocationPreferencesScreen> createState() =>
      _LocationPreferencesScreenState();
}

class _LocationPreferencesScreenState
    extends ConsumerState<LocationPreferencesScreen> {
  final Set<String> _selectedCities = {};
  bool _remote = false;
  bool _hybrid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(preferencesDraftProvider);
    _selectedCities.addAll(draft.cities);
    _remote = draft.remote;
    _hybrid = draft.hybrid;
  }

  bool get _canContinue => _selectedCities.isNotEmpty || _remote;

  Future<void> _finish() async {
    if (!_canContinue) return;
    setState(() => _isSaving = true);

    ref
        .read(preferencesDraftProvider.notifier)
        .setLocation(
          country: _country,
          cities: _selectedCities.toList(),
          remote: _remote,
          hybrid: _hybrid,
        );

    try {
      final uid = ref.read(authServiceProvider).currentUser!.uid;
      await ref.read(preferencesDraftProvider.notifier).saveToFirestore(uid);
      // Invalidate so the router picks up preferencesSet = true immediately
      ref.invalidate(preferencesSetProvider);
      if (mounted) {
        AppSnackbar.success(
          context,
          'Preferences saved! Refreshing your matches.',
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where do you want to work?',
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Country', style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(_country, style: AppTypography.body),
              ),

              const SizedBox(height: AppSpacing.lg),
              Text('City', style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _cities.map((city) {
                  final isSelected = _selectedCities.contains(city);
                  return SelectableChip(
                    label: city,
                    selected: isSelected,
                    onTap: () => setState(() {
                      isSelected
                          ? _selectedCities.remove(city)
                          : _selectedCities.add(city);
                    }),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Remote opportunities', style: AppTypography.body),
                activeThumbColor: AppColors.primary,
                value: _remote,
                onChanged: (v) => setState(() => _remote = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Hybrid opportunities', style: AppTypography.body),
                activeThumbColor: AppColors.primary,
                value: _hybrid,
                onChanged: (v) => setState(() => _hybrid = v),
              ),

              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                isLoading: _isSaving,
                onPressed: _canContinue ? _finish : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
