import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../auth_state.dart';
import '../../onboarding/onboarding_state.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _error;

  /// Returns the post-auth destination: honours ?from= if present, otherwise
  /// falls through to the paywall so new users see the subscription offer.
  String _postAuthDestination() {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from != null && from.isNotEmpty) {
      return Uri.decodeComponent(from);
    }
    return '/onboarding/paywall';
  }

  String _roleDashboardDestination() {
    final role = ref.read(onboardingProvider).role;
    return switch (role) {
      'teacher' => '/profile/teacher',
      'parent' => '/profile/parent',
      _ => '/home',
    };
  }

  Future<void> _handleResult(
    Future<void> Function() action, {
    String? destination,
  }) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) context.go(destination ?? _postAuthDestination());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIOS =
        Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return Scaffold(
      body: SafeArea(
        child: WittLoadingOverlay(
          isLoading: _isLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              WittSpacing.lg,
              WittSpacing.massive,
              WittSpacing.lg,
              WittSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo / brand mark
                Image.asset(
                  isDark
                      ? 'assets/images/logo-white.png'
                      : 'assets/images/logo-black.png',
                  width: 94,
                  height: 94,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: WittSpacing.xxl),
                Text(
                  'Create your account',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WittSpacing.sm),
                Text(
                  'Save your progress and access Witt on any device.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? WittColors.textSecondaryDark
                        : WittColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WittSpacing.xxxl),

                // Error banner
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(WittSpacing.md),
                    decoration: BoxDecoration(
                      color: WittColors.errorContainer,
                      borderRadius: WittSpacing.borderRadiusMd,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: WittColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: WittSpacing.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: WittColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WittSpacing.lg),
                ],

                // Apple Sign-In (iOS/macOS first per App Store policy)
                if (isIOS) ...[
                  _SocialButton(
                    icon: Icons.apple_rounded,
                    label: 'Sign in with Apple',
                    onTap: () => _handleResult(
                      () => ref
                          .read(authNotifierProvider.notifier)
                          .signInWithApple(),
                    ),
                  ),
                  const SizedBox(height: WittSpacing.md),
                ],

                // Google
                _SocialButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Sign in with Google',
                  onTap: () => _handleResult(
                    () => ref
                        .read(authNotifierProvider.notifier)
                        .signInWithGoogle(),
                  ),
                ),
                const SizedBox(height: WittSpacing.md),

                // Email
                _SocialButton(
                  icon: Icons.email_outlined,
                  label: 'Continue with Email',
                  onTap: () => context.push('/onboarding/auth/email'),
                ),
                const SizedBox(height: WittSpacing.md),

                // Phone OTP
                _SocialButton(
                  icon: Icons.phone_outlined,
                  label: 'Continue with Phone',
                  onTap: () => context.push('/onboarding/auth/phone'),
                ),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: WittSpacing.xxl,
                  ),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WittSpacing.md,
                        ),
                        child: Text(
                          'or',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? WittColors.textTertiaryDark
                                : WittColors.textTertiary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),

                // Skip — no auth required
                WittButton(
                  label: 'Skip for now',
                  variant: WittButtonVariant.outline,
                  onPressed: () async {
                    final dest = _roleDashboardDestination();
                    await ref.read(onboardingProvider.notifier).complete();
                    // ignore: use_build_context_synchronously
                    if (mounted) context.go(dest);
                  },
                  isFullWidth: true,
                  size: WittButtonSize.lg,
                ),
                const SizedBox(height: WittSpacing.xxl),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.push('/onboarding/auth/login'),
                      child: Text(
                        'Log in',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: WittColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: WittSpacing.touchTarget + 8,
        decoration: BoxDecoration(
          color: isDark ? WittColors.surfaceVariantDark : WittColors.surface,
          borderRadius: WittSpacing.borderRadiusMd,
          border: Border.all(
            color: isDark ? WittColors.outlineDark : WittColors.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: WittSpacing.iconLg),
            const SizedBox(width: WittSpacing.md),
            Text(label, style: theme.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
