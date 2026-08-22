import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/delete.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const Delete()),
      // GoRoute(path: '/home', builder: (_, __) => const HomeDashboardScreen()),
    ],
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.value != null;
      final isAtSplash = state.matchedLocation == '/splash';

      if (isLoading) return isAtSplash ? null : '/splash';
      if (!isLoggedIn) return '/sign-in';
      if (isLoggedIn && (isAtSplash || state.matchedLocation == '/sign-in')) {
        return '/home';
      }
      return null;
    },
  );
});
