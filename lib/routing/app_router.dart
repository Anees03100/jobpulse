import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/screens/home/home_shell.dart';
import '../providers/auth_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_dashboard_screen.dart';
import 'go_router_refresh_stream.dart';

const _authRoutes = ['/sign-in', '/sign-up', '/forgot-password'];

final appRouterProvider = Provider<GoRouter>((ref) {
  // read, not watch — the router is built ONCE per app lifetime.
  // Auth changes are handled via refreshListenable below, not by
  // recreating this provider.
  final authService = ref.read(authServiceProvider);

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
    ],
    redirect: (context, state) {
      final isLoggedIn = authService.currentUser != null;
      final loc = state.matchedLocation;

      if (loc == '/splash') return null; // splash handles its own navigation
      if (loc == '/onboarding') return null;

      // Signed in but still sitting on an auth screen → go home.
      // (This also fixes sign-in never actually navigating before —
      // it was relying on the accidental full-router-reset too.)
      if (isLoggedIn && _authRoutes.contains(loc)) return '/home';

      // Not signed in but trying to reach a protected route → sign in.
      if (!isLoggedIn && !_authRoutes.contains(loc)) return '/sign-in';

      return null;
    },
  );
});
