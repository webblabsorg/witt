/// Currency localization service.
///
/// Strategy:
/// 1. GeoIP via ip-api.com (free, no key) → country code + currency code
/// 2. Open Exchange Rates (OXR) → rates relative to USD base
/// 3. Rule: 1 USD = 1 EUR = 1 GBP (parity pricing — no conversion for these)
/// 4. All other currencies: convert from USD using live OXR rate
/// 5. Cache rates for 24 h in Hive to avoid hammering the API
library;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ── Constants ─────────────────────────────────────────────────────────────

/// Currencies that use parity pricing with USD (1 USD = 1 of these).
const _paritySet = {'USD', 'EUR', 'GBP'};

/// OXR base is always USD.
const _baseCurrency = 'USD';

/// Cache TTL: 24 hours in milliseconds.
const _rateCacheTtlMs = 24 * 60 * 60 * 1000;

const _kBoxRates = 'oxr_rates';
const _kKeyRates = 'rates';
const _kKeyRatesTs = 'rates_ts';
const _kKeyUserCurrency = 'user_currency';
const _kKeyUserCountry = 'user_country';

// ── Currency metadata ─────────────────────────────────────────────────────

/// Display metadata for supported currencies.
const currencyMeta = <String, _CurrencyMeta>{
  'USD': _CurrencyMeta(symbol: '\$', name: 'US Dollar', decimals: 2),
  'EUR': _CurrencyMeta(symbol: '€', name: 'Euro', decimals: 2),
  'GBP': _CurrencyMeta(symbol: '£', name: 'British Pound', decimals: 2),
  'NGN': _CurrencyMeta(symbol: '₦', name: 'Nigerian Naira', decimals: 0),
  'GHS': _CurrencyMeta(symbol: 'GH₵', name: 'Ghanaian Cedi', decimals: 2),
  'KES': _CurrencyMeta(symbol: 'KSh', name: 'Kenyan Shilling', decimals: 0),
  'ZAR': _CurrencyMeta(symbol: 'R', name: 'South African Rand', decimals: 2),
  'INR': _CurrencyMeta(symbol: '₹', name: 'Indian Rupee', decimals: 0),
  'BRL': _CurrencyMeta(symbol: 'R\$', name: 'Brazilian Real', decimals: 2),
  'MXN': _CurrencyMeta(symbol: 'MX\$', name: 'Mexican Peso', decimals: 2),
  'CAD': _CurrencyMeta(symbol: 'CA\$', name: 'Canadian Dollar', decimals: 2),
  'AUD': _CurrencyMeta(symbol: 'A\$', name: 'Australian Dollar', decimals: 2),
  'EGP': _CurrencyMeta(symbol: 'E£', name: 'Egyptian Pound', decimals: 2),
  'PKR': _CurrencyMeta(symbol: '₨', name: 'Pakistani Rupee', decimals: 0),
  'BDT': _CurrencyMeta(symbol: '৳', name: 'Bangladeshi Taka', decimals: 0),
  'PHP': _CurrencyMeta(symbol: '₱', name: 'Philippine Peso', decimals: 2),
  'IDR': _CurrencyMeta(symbol: 'Rp', name: 'Indonesian Rupiah', decimals: 0),
  'TZS': _CurrencyMeta(symbol: 'TSh', name: 'Tanzanian Shilling', decimals: 0),
  'UGX': _CurrencyMeta(symbol: 'USh', name: 'Ugandan Shilling', decimals: 0),
  'XOF': _CurrencyMeta(symbol: 'CFA', name: 'West African CFA', decimals: 0),
};

class _CurrencyMeta {
  const _CurrencyMeta({
    required this.symbol,
    required this.name,
    required this.decimals,
  });
  final String symbol;
  final String name;
  final int decimals;
}

// ── Localized price ───────────────────────────────────────────────────────

class LocalizedPrice {
  const LocalizedPrice({
    required this.currencyCode,
    required this.amount,
    required this.formatted,
  });

  final String currencyCode;
  final double amount;
  final String formatted;

  @override
  String toString() => formatted;
}

// ── Currency service ──────────────────────────────────────────────────────

class CurrencyService {
  CurrencyService._()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  static final instance = CurrencyService._();

  final Dio _dio;
  late Box<dynamic> _box;

  String _currencyCode = 'USD';
  String _countryCode = 'US';
  Map<String, double> _rates = {};

  String get currencyCode => _currencyCode;
  String get countryCode => _countryCode;

  /// Initialize: open Hive box, restore cached data, then refresh async.
  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_kBoxRates);

    // Restore cached currency preference
    _currencyCode = _box.get(_kKeyUserCurrency, defaultValue: 'USD') as String;
    _countryCode = _box.get(_kKeyUserCountry, defaultValue: 'US') as String;

    // Restore cached rates
    final rawRates = _box.get(_kKeyRates);
    if (rawRates is Map) {
      _rates = Map<String, double>.from(
        rawRates.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      );
    }

    // Refresh in background (non-blocking)
    _refreshAsync();
  }

  Future<void> _refreshAsync() async {
    try {
      await _detectCurrency();
      await _fetchRates();
    } catch (_) {
      // Silent — use cached data
    }
  }

  /// Detect user's country and currency via GeoIP (ip-api.com — free, no key).
  Future<void> _detectCurrency() async {
    final response = await _dio.get(
      'http://ip-api.com/json/?fields=countryCode,currency',
    );
    final data = response.data as Map;
    final country = data['countryCode'] as String? ?? 'US';
    final currency = data['currency'] as String? ?? 'USD';

    _countryCode = country;
    _currencyCode = currency.toUpperCase();

    await _box.put(_kKeyUserCountry, _countryCode);
    await _box.put(_kKeyUserCurrency, _currencyCode);
  }

  /// Fetch exchange rates from Open Exchange Rates (USD base).
  Future<void> _fetchRates() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastFetch = _box.get(_kKeyRatesTs, defaultValue: 0) as int;

    // Use cached rates if fresh
    if (_rates.isNotEmpty && (now - lastFetch) < _rateCacheTtlMs) return;

    final apiKey = dotenv.env['OPEN_EXCHANGE_RATES_API_KEY'] ?? '';
    if (apiKey.isEmpty) return;

    final response = await _dio.get(
      'https://openexchangerates.org/api/latest.json',
      queryParameters: {'app_id': apiKey, 'base': _baseCurrency},
    );

    final data = response.data as Map;
    final rawRates = data['rates'] as Map;
    _rates = Map<String, double>.from(
      rawRates.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );

    await _box.put(_kKeyRates, _rates);
    await _box.put(_kKeyRatesTs, now);
  }

  /// Convert a USD amount to the user's local currency.
  /// Applies parity rule: 1 USD = 1 EUR = 1 GBP.
  LocalizedPrice localize(double usdAmount, {String? overrideCurrency}) {
    final code = (overrideCurrency ?? _currencyCode).toUpperCase();

    // Parity currencies — no conversion
    if (_paritySet.contains(code)) {
      return _format(usdAmount, code);
    }

    // Convert using live rate
    final rate = _rates[code];
    if (rate == null || rate == 0) {
      // Fallback to USD if rate unknown
      return _format(usdAmount, 'USD');
    }

    return _format(usdAmount * rate, code);
  }

  LocalizedPrice _format(double amount, String code) {
    final meta = currencyMeta[code];
    final symbol = meta?.symbol ?? code;
    final decimals = meta?.decimals ?? 2;
    final rounded = decimals == 0
        ? amount.round().toString()
        : amount.toStringAsFixed(decimals);
    return LocalizedPrice(
      currencyCode: code,
      amount: amount,
      formatted: '$symbol$rounded',
    );
  }

  /// Force a specific currency (user override from settings).
  Future<void> setCurrency(String code) async {
    _currencyCode = code.toUpperCase();
    await _box.put(_kKeyUserCurrency, _currencyCode);
  }
}
