// lib/providers/app_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global bottom-nav index — 0:Cüzdan 1:İşlem 2:Geçmiş 3:Risk 4:Profil
final navIndexProvider = StateProvider<int>((_) => 0);

/// Uygulama dili — 'tr' veya 'en'
final languageProvider = StateProvider<Locale>((_) => const Locale('tr'));

/// Auth flow durumu
enum AuthState { onboarding, auth, app }
final authStateProvider = StateProvider<AuthState>((_) => AuthState.onboarding);
