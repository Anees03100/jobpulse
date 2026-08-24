import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/providers/user_preferences_provider.dart';
import 'package:jobpulse/screens/home/home_shell.dart';
import 'package:jobpulse/screens/preferences_setup/location_preferences_screen.dart';
import 'package:jobpulse/screens/preferences_setup/opportunity_type_screen.dart';
import 'package:jobpulse/screens/preferences_setup/skills_selection_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import 'go_router_refresh_stream.dart';

const _authRoutes = ['/sign-in', '/sign-up', '/forgot-password'];

final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.read(authServiceProvider);
  const prefRoutes = [
    '/preferences/opportunity-type',
    '/preferences/skills',
    '/preferences/location',
  ];

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeShell()),
      GoRoute(
        path: '/preferences/opportunity-type',
        builder: (_, _) => const OpportunityTypeScreen(),
      ),
      GoRoute(
        path: '/preferences/skills',
        builder: (_, _) => const SkillsSelectionScreen(),
      ),
      GoRoute(
        path: '/preferences/location',
        builder: (_, _) => const LocationPreferencesScreen(),
      ),
    ],
    redirect: (context, state) async {
      final isLoggedIn = authService.currentUser != null;
      final loc = state.matchedLocation;

      if (loc == '/splash' || loc == '/onboarding') return null;
      if (!isLoggedIn && !_authRoutes.contains(loc)) return '/sign-in';
      if (isLoggedIn && _authRoutes.contains(loc)) {
        final hasPrefs = await ref.read(preferencesSetProvider.future);
        return hasPrefs ? '/home' : '/preferences/opportunity-type';
      }
      if (isLoggedIn && loc == '/home') {
        final hasPrefs = await ref.read(preferencesSetProvider.future);
        if (!hasPrefs) return '/preferences/opportunity-type';
      }
      if (isLoggedIn && prefRoutes.contains(loc))
        return null; // let them proceed through setup
      return null;
    },
  );
});
