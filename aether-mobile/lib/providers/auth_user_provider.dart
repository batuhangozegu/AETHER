// lib/providers/auth_user_provider.dart
//
// Stores the logged-in user's display name and email in SharedPreferences
// so that the profile screen always shows real registration data.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUserState {
  final String username;
  final String email;

  const AuthUserState({this.username = '', this.email = ''});

  AuthUserState copyWith({String? username, String? email}) =>
      AuthUserState(
        username: username ?? this.username,
        email: email ?? this.email,
      );
}

class AuthUserNotifier extends AsyncNotifier<AuthUserState> {
  @override
  Future<AuthUserState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AuthUserState(
      username: prefs.getString('auth_username') ?? '',
      email: prefs.getString('auth_email') ?? '',
    );
  }

  Future<void> saveUser({required String username, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_username', username);
    await prefs.setString('auth_email', email);
    state = AsyncData(AuthUserState(username: username, email: email));
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_username');
    await prefs.remove('auth_email');
    state = const AsyncData(AuthUserState());
  }
}

final authUserProvider =
    AsyncNotifierProvider<AuthUserNotifier, AuthUserState>(
  AuthUserNotifier.new,
);
