import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/screens/auth/forgot_password_screen.dart';
import 'package:jobpulse/screens/auth/sign_up_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/home/home_dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeDashboardScreen()),
    ],
    // Only guards against unauthenticated users reaching /home directly —
    // no longer responsible for initial splash timing.
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAtSplash = state.matchedLocation == '/splash';
      final isAtOnboarding = state.matchedLocation == '/onboarding';

      if (isAtSplash || isAtOnboarding) return null;
      if (!isLoggedIn && state.matchedLocation == '/home') return '/sign-in';
      return null;
    },
  );
});
