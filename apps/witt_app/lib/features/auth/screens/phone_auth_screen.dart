import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:witt_ui/witt_ui.dart';

import '../auth_state.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _error;
  String _phone = '';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _phone = _phoneCtrl.text.trim();
      await ref.read(authNotifierProvider.notifier).sendPhoneOtp(_phone);
      if (mounted) setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length < 6) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).verifyPhoneOtp(
            _phone,
            _otpCtrl.text.trim(),
          );
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
        title: const Text('Phone verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WittSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: WittSpacing.lg),
              Text(
                _otpSent
                    ? 'Enter the code we sent to $_phone'
                    : 'Enter your phone number',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: WittSpacing.sm),
              Text(
                _otpSent
                    ? 'Check your SMS for a 6-digit verification code.'
                    : 'Include your country code, e.g. +1 555 000 0000',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: WittColors.textSecondary,
                ),
              ),
              const SizedBox(height: WittSpacing.xxxl),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(WittSpacing.md),
                  decoration: BoxDecoration(
                    color: WittColors.errorContainer,
                    borderRadius: WittSpacing.borderRadiusMd,
                  ),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: WittColors.error),
                  ),
                ),
                const SizedBox(height: WittSpacing.lg),
              ],
              if (!_otpSent) ...[
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendOtp(),
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+1 555 000 0000',
                  ),
                ),
                const SizedBox(height: WittSpacing.xxxl),
                WittButton(
                  label: 'Send code',
                  onPressed: _sendOtp,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  size: WittButtonSize.lg,
                ),
              ] else ...[
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  onSubmitted: (_) => _verifyOtp(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: WittSpacing.xxxl),
                WittButton(
                  label: 'Verify',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  size: WittButtonSize.lg,
                ),
                const SizedBox(height: WittSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _otpSent = false),
                    child: const Text('Change phone number'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
