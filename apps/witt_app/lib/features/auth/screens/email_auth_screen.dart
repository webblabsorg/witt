import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../auth_state.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key, this.isLogin = false});
  final bool isLogin;

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (widget.isLogin) {
        await ref
            .read(authNotifierProvider.notifier)
            .signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await ref
            .read(authNotifierProvider.notifier)
            .signUpWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      }
      if (mounted) context.go('/onboarding/paywall');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLogin ? 'Log in' : 'Create account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WittSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: WittSpacing.lg),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(WittSpacing.md),
                    decoration: BoxDecoration(
                      color: WittColors.errorContainer,
                      borderRadius: WittSpacing.borderRadiusMd,
                    ),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: WittColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: WittSpacing.lg),
                ],
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: WittSpacing.lg),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (!widget.isLogin && v.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: WittSpacing.xxxl),
                WittButton(
                  label: widget.isLogin ? 'Log in' : 'Create account',
                  onPressed: _submit,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  size: WittButtonSize.lg,
                ),
                const SizedBox(height: WittSpacing.lg),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (widget.isLogin) {
                        context.pushReplacement('/onboarding/auth/email');
                      } else {
                        context.pushReplacement('/onboarding/auth/login');
                      }
                    },
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: widget.isLogin
                                ? "Don't have an account? "
                                : 'Already have an account? ',
                          ),
                          TextSpan(
                            text: widget.isLogin ? 'Sign up' : 'Log in',
                            style: const TextStyle(
                              color: WittColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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
