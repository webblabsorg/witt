/// Secure key-value storage backed by flutter_secure_storage.
///
/// Use for: auth tokens, session data, any PII that must not live in
/// plain-text Hive boxes or SharedPreferences.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Keys ──────────────────────────────────────────────────────────────────

  static const _kAccessToken = 'supabase_access_token';
  static const _kRefreshToken = 'supabase_refresh_token';
  static const _kUserId = 'user_id';
  static const _kCoppaConsent = 'coppa_consent_given';
  static const _kGdprConsent = 'gdpr_consent_given';

  // ── Auth tokens ───────────────────────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
    ]);
  }

  static Future<String?> readAccessToken() =>
      _storage.read(key: _kAccessToken);

  static Future<String?> readRefreshToken() =>
      _storage.read(key: _kRefreshToken);

  static Future<void> saveUserId(String userId) =>
      _storage.write(key: _kUserId, value: userId);

  static Future<String?> readUserId() => _storage.read(key: _kUserId);

  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kUserId),
    ]);
  }

  // ── Consent flags ─────────────────────────────────────────────────────────

  static Future<void> setCoppaConsent(bool given) =>
      _storage.write(key: _kCoppaConsent, value: given.toString());

  static Future<bool> getCoppaConsent() async {
    final v = await _storage.read(key: _kCoppaConsent);
    return v == 'true';
  }

  static Future<void> setGdprConsent(bool given) =>
      _storage.write(key: _kGdprConsent, value: given.toString());

  static Future<bool> getGdprConsent() async {
    final v = await _storage.read(key: _kGdprConsent);
    return v == 'true';
  }

  // ── Wipe all ──────────────────────────────────────────────────────────────

  /// Called on account deletion — removes all secure data for this device.
  static Future<void> deleteAll() => _storage.deleteAll();
}
