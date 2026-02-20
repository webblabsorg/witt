import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/notifications/notification_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  anonymous,
  unauthenticated,
  error,
}

class AuthState {
  const AuthState({this.status = AuthStatus.initial, this.user, this.error});

  final AuthStatus status;
  final User? user;
  final String? error;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated || status == AuthStatus.anonymous;

  bool get isAnonymous => status == AuthStatus.anonymous;

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  AuthState build() {
    final session = _client.auth.currentSession;
    if (session != null) {
      final isAnon = session.user.isAnonymous;
      return AuthState(
        status: isAnon ? AuthStatus.anonymous : AuthStatus.authenticated,
        user: session.user,
      );
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      final user = _client.auth.currentUser;
      if (user != null) await NotificationService.identifyUser(user.id);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _client.auth.signInWithOAuth(OAuthProvider.apple);
      final user = _client.auth.currentUser;
      if (user != null) await NotificationService.identifyUser(user.id);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await NotificationService.identifyUser(response.user!.id);
      }
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await NotificationService.identifyUser(response.user!.id);
      }
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      rethrow;
    }
  }

  Future<void> sendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<void> verifyPhoneOtp(String phone, String token) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      if (response.user != null) {
        await NotificationService.identifyUser(response.user!.id);
      }
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _client.auth.signInAnonymously();
      state = AuthState(status: AuthStatus.anonymous, user: response.user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    NotificationService.clearUser();
    await _client.auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> linkEmailToAnonymous(String email, String password) async {
    await _client.auth.updateUser(
      UserAttributes(email: email, password: password),
    );
    final user = _client.auth.currentUser;
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});
