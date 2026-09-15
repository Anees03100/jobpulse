import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/discover_provider.dart';
import '../../providers/saved_jobs_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/opportunity_card.dart';
import '../../widgets/inputs/app_text_field.dart';

const _categories = [
  'Flutter Development',
  'Web Development',
  'Mobile Development',
  'UI/UX',
  'AI & Machine Learning',
  'Data Science',
  'Backend Development',
  'Graphic Design',
];

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    ref.read(discoverQueryProvider.notifier).state = query;
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(discoverQueryProvider);
    final resultsAsync = ref.watch(discoverResultsProvider);
    final savedIds = ref.watch(savedJobIdsProvider).value ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover', style: AppTypography.pageTitle),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _searchController,
                    hint: 'Search jobs, companies or skills',
                    prefixIcon: Icons.search,
                    onChanged:
                        (_) {}, // debounced via submit instead of live-typing
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _runSearch(_searchController.text),
                      child: const Text('Search'),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: query.isEmpty
                  ? _CategoryGrid(
                      onCategoryTap: (category) {
                        _searchController.text = category;
                        _runSearch(category);
                      },
                    )
                  : resultsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Something went wrong',
                                style: AppTypography.sectionHeading,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              OutlinedButton(
                                onPressed: () =>
                                    ref.invalidate(discoverResultsProvider),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (results) {
                        if (results.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'No results found',
                                    style: AppTypography.sectionHeading,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Try another keyword or adjust your filters.',
                                    style: AppTypography.bodySecondary,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: results.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final scored = results[index];
                            return OpportunityCard(
                              title: scored.job.title,
                              company: scored.job.company,
                              location: scored.job.location,
                              type: scored.job.type,
                              matchScore: scored.score,
                              postedTime: _timeAgo(scored.job.postedAt),
                              skills: scored.job.skills,
                              isSaved: savedIds.contains(scored.job.id),
                              onTap: () => context.push(
                                '/opportunity-details',
                                extra: {
                                  'job': scored.job,
                                  'score': scored.score,
                                },
                              ),
                              onSaveToggle: () async {
                                final uid = ref
                                    .read(authServiceProvider)
                                    .currentUser!
                                    .uid;
                                final service = ref.read(
                                  savedJobsServiceProvider,
                                );
                                final isSaved = savedIds.contains(
                                  scored.job.id,
                                );
                                await toggleSaveJob(
                                  uid: uid,
                                  job: scored.job,
                                  isSaved: isSaved,
                                  service: service,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onCategoryTap});
  final void Function(String category) onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.2,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return GestureDetector(
          onTap: () => onCategoryTap(category),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Center(
              child: Text(
                category,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
