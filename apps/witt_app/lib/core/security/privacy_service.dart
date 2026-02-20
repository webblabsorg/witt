/// GDPR / COPPA privacy service.
///
/// Provides:
///  - Data export (calls export_my_data RPC → JSON download)
///  - Account deletion (calls delete-account Edge Function)
///  - COPPA age-gate check
library;

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_storage.dart';

class PrivacyService {
  PrivacyService._();

  static SupabaseClient get _db => Supabase.instance.client;

  // ── GDPR: data export ─────────────────────────────────────────────────────

  /// Fetches all personal data for the current user as a JSON string.
  /// The caller is responsible for sharing/saving the file.
  static Future<String> exportMyData() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Not authenticated');

    final result = await _db.rpc(
      'export_my_data',
      params: {'p_user_id': uid},
    );

    return const JsonEncoder.withIndent('  ').convert(result);
  }

  // ── GDPR: account deletion ────────────────────────────────────────────────

  /// Permanently deletes all user data and the auth account.
  /// Clears local secure storage after server deletion succeeds.
  static Future<void> deleteAccount() async {
    final response = await _db.functions.invoke('delete-account');
    if (response.status != 200) {
      final msg = (response.data as Map?)?['error'] ?? 'Deletion failed';
      throw Exception(msg);
    }
    // Wipe local secure storage
    await SecureStorage.deleteAll();
    // Sign out locally
    await _db.auth.signOut();
  }

  // ── COPPA age-gate ────────────────────────────────────────────────────────

  /// Returns true if the user is under 13 based on their birth year.
  static bool isUnder13(int birthYear) {
    final currentYear = DateTime.now().year;
    return (currentYear - birthYear) < 13;
  }

  /// Persists parental consent flag to secure storage.
  static Future<void> recordParentalConsent() =>
      SecureStorage.setCoppaConsent(true);

  static Future<bool> hasParentalConsent() => SecureStorage.getCoppaConsent();

  // ── GDPR consent ──────────────────────────────────────────────────────────

  static Future<void> recordGdprConsent() =>
      SecureStorage.setGdprConsent(true);

  static Future<bool> hasGdprConsent() => SecureStorage.getGdprConsent();
}
