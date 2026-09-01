import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobpulse/core/utils/app_snackbar.dart';
import 'package:jobpulse/core/utils/error_mapper.dart';
import 'package:jobpulse/widgets/butons/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/inputs/app_text_field.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authServiceProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final hasPrefs = await ref.read(preferencesSetProvider.future);
      if (!mounted) return;

      context.go(hasPrefs ? '/home' : '/preferences/opportunity-type');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      if (credential != null) {
        await ref
            .read(firestoreServiceProvider)
            .ensureUserDocExists(credential.user!);

        final hasPrefs = await ref.read(preferencesSetProvider.future);
        if (!mounted) return;

        context.go(hasPrefs ? '/home' : '/preferences/opportunity-type');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Welcome back', style: AppTypography.pageTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Find your next opportunity.',
                  style: AppTypography.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.xl),

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),

                if (_errorText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorText!,
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Sign In',
                  isLoading: _isLoading,
                  onPressed: _handleSignIn,
                ),

                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text('OR', style: AppTypography.metadata),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Continue with Google'),
                ),

                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Wrap(
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTypography.bodySecondary,
                      ),
                      GestureDetector(
                        onTap: () => context.push('/sign-up'),
                        child: Text(
                          'Sign Up',
                          style: AppTypography.bodySecondary.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
