import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nav_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/navigation/app_bottom_nav.dart';
import '../discover/discover_screen.dart';
import '../profile/profile_screen.dart';
import '../saved/saved_screen.dart';
import 'home_dashboard_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _screens = [
    HomeDashboardScreen(),
    DiscoverScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;
      final router = GoRouter.of(context);

      try {
        // Tap handling first, so the permission dialog can't delay it
        await ref.read(notificationHandlerProvider).init(router);
        await ref.read(fcmServiceProvider).initAndSaveToken(user.uid);
      } catch (e) {
        debugPrint('Notification setup failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
