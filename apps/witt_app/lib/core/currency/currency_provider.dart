/// Riverpod providers for currency localization.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'currency_service.dart';

// ── Currency state ────────────────────────────────────────────────────────

class CurrencyState {
  const CurrencyState({
    this.currencyCode = 'USD',
    this.countryCode = 'US',
    this.isLoaded = false,
  });

  final String currencyCode;
  final String countryCode;
  final bool isLoaded;

  CurrencyState copyWith({
    String? currencyCode,
    String? countryCode,
    bool? isLoaded,
  }) =>
      CurrencyState(
        currencyCode: currencyCode ?? this.currencyCode,
        countryCode: countryCode ?? this.countryCode,
        isLoaded: isLoaded ?? this.isLoaded,
      );
}

// ── Currency notifier ─────────────────────────────────────────────────────

class CurrencyNotifier extends AsyncNotifier<CurrencyState> {
  @override
  Future<CurrencyState> build() async {
    final svc = CurrencyService.instance;
    await svc.init();
    return CurrencyState(
      currencyCode: svc.currencyCode,
      countryCode: svc.countryCode,
      isLoaded: true,
    );
  }

  Future<void> setCurrency(String code) async {
    await CurrencyService.instance.setCurrency(code);
    state = AsyncData(
      state.valueOrNull?.copyWith(currencyCode: code.toUpperCase()) ??
          CurrencyState(currencyCode: code.toUpperCase(), isLoaded: true),
    );
  }
}

final currencyProvider =
    AsyncNotifierProvider<CurrencyNotifier, CurrencyState>(
  CurrencyNotifier.new,
);

// ── Convenience: localize a USD price ────────────────────────────────────

/// Returns a [LocalizedPrice] for [usdAmount] in the user's detected currency.
/// Falls back to USD if currency data isn't loaded yet.
final localizedPriceProvider = Provider.family<LocalizedPrice, double>((
  ref,
  usdAmount,
) {
  ref.watch(currencyProvider); // re-run when currency changes
  return CurrencyService.instance.localize(usdAmount);
});

/// The user's current currency code (e.g. 'NGN', 'USD').
final currencyCodeProvider = Provider<String>((ref) {
  return ref.watch(currencyProvider).valueOrNull?.currencyCode ?? 'USD';
});

/// The user's detected country code (e.g. 'NG', 'US').
final countryCodeProvider = Provider<String>((ref) {
  return ref.watch(currencyProvider).valueOrNull?.countryCode ?? 'US';
});
