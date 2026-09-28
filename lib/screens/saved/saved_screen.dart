import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/error_mapper.dart';
import '../../models/saved_job_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/saved_jobs_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/opportunity_card.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String jobId, String status) async {
    try {
      final uid = ref.read(authServiceProvider).currentUser!.uid;
      await ref.read(savedJobsServiceProvider).updateStatus(uid, jobId, status);
      if (mounted) AppSnackbar.success(context, 'Moved to $status');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, ErrorMapper.map(e));
    }
  }

  Future<void> _remove(String jobId) async {
    try {
      final uid = ref.read(authServiceProvider).currentUser!.uid;
      await ref.read(savedJobsServiceProvider).removeJob(uid, jobId);
      if (mounted) AppSnackbar.success(context, 'Removed from saved');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, ErrorMapper.map(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(savedJobEntriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Saved', style: AppTypography.sectionHeading),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Saved'),
            Tab(text: 'Applied'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load saved opportunities.',
            style: AppTypography.bodySecondary,
          ),
        ),
        data: (entries) {
          final saved = entries.where((e) => e.status == 'Saved').toList();
          final applied = entries
              .where(
                (e) => [
                  'Applied',
                  'Interview',
                  'Rejected',
                  'Offer',
                ].contains(e.status),
              )
              .toList();
          final archived = entries
              .where((e) => e.status == 'Archived')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _SavedList(
                entries: saved,
                emptyMessage: 'Nothing saved yet',
                onUpdateStatus: _updateStatus,
                onRemove: _remove,
              ),
              _SavedList(
                entries: applied,
                emptyMessage: 'No applications tracked yet',
                onUpdateStatus: _updateStatus,
                onRemove: _remove,
              ),
              _SavedList(
                entries: archived,
                emptyMessage: 'Nothing archived',
                onUpdateStatus: _updateStatus,
                onRemove: _remove,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SavedList extends StatelessWidget {
  const _SavedList({
    required this.entries,
    required this.emptyMessage,
    required this.onUpdateStatus,
    required this.onRemove,
  });

  final List<SavedJobEntry> entries;
  final String emptyMessage;
  final void Function(String jobId, String status) onUpdateStatus;
  final void Function(String jobId) onRemove;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            emptyMessage,
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OpportunityCard(
              title: entry.job.title,
              company: entry.job.company,
              location: entry.job.location,
              type: entry.job.type,
              matchScore:
                  0, // score isn't stored on saved docs — hide badge below instead
              postedTime: '',
              skills: entry.job.skills,
              isSaved: true,
              onTap: () => context.push(
                '/opportunity-details',
                extra: {'job': entry.job, 'score': 0},
              ),
              onSaveToggle: () => onRemove(entry.job.id),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _StatusChip(
                  label: entry.status,
                  onTap: () => _showStatusMenu(context, entry.job.id),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showStatusMenu(BuildContext context, String jobId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final status in [
                'Saved',
                'Applied',
                'Interview',
                'Rejected',
                'Offer',
                'Archived',
              ])
                ListTile(
                  title: Text(status, style: AppTypography.body),
                  onTap: () {
                    Navigator.pop(context);
                    onUpdateStatus(jobId, status);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.metadata),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
