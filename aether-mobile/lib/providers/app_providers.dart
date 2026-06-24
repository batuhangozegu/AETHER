// lib/providers/app_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Global bottom-nav index — 0:Cüzdan 1:İşlem 2:Geçmiş 3:Risk 4:Profil
final navIndexProvider = StateProvider<int>((_) => 0);

/// Uygulama dili — 'tr' veya 'en'
final languageProvider = StateProvider<Locale>((_) => const Locale('tr'));

/// Auth flow durumu
enum AuthState { onboarding, auth, app }

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState.onboarding) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authenticated = await _apiService.isAuthenticated();
    if (authenticated) {
      state = AuthState.app;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_done') ?? false;
      if (onboardingDone) {
        state = AuthState.auth;
      } else {
        state = AuthState.onboarding;
      }
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    state = AuthState.auth;
  }

  void setAuthState(AuthState newState) {
    state = newState;
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});
