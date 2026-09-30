import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nav_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/navigation/app_bottom_nav.dart';
import 'home_dashboard_screen.dart';
import '../discover/discover_screen.dart';
import '../saved/saved_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _screens = [
    HomeDashboardScreen(),
    DiscoverScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) =>
            ref.read(currentTabIndexProvider.notifier).state = index,
      ),
    );
  }
}
