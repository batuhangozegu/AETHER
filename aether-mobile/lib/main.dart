// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/app_providers.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/trade_screen.dart';
import 'screens/history_screen.dart';
import 'screens/risk_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: BorsaApp()));
}

class BorsaApp extends ConsumerWidget {
  const BorsaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale    = ref.watch(languageProvider);
    final authState = ref.watch(authStateProvider);
    return MaterialApp(
      title: 'Borsa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: locale,
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: switch (authState) {
        AuthState.onboarding => const OnboardingScreen(),
        AuthState.auth       => const AuthScreen(),
        AuthState.app        => const MainShell(),
      },
    );
  }
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    DashboardScreen(),
    TradeScreen(),
    HistoryScreen(),
    RiskScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: IndexedStack(
        index: index,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: index,
        onTap: (i) => ref.read(navIndexProvider.notifier).state = i,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _tabs = [
    _TabItem(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        label: 'Cüzdan'),
    _TabItem(
        icon: Icons.show_chart_outlined,
        activeIcon: Icons.show_chart,
        label: 'İşlem'),
    _TabItem(
        icon: Icons.history_outlined,
        activeIcon: Icons.history,
        label: 'Geçmiş'),
    _TabItem(
        icon: Icons.shield_outlined,
        activeIcon: Icons.shield,
        label: 'Risk'),
    _TabItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99080C1E), Color(0xF2040610)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _tabs.asMap().entries.map((e) {
            final i = e.key;
            final tab = e.value;
            final active = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: const BoxDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? tab.activeIcon : tab.icon,
                        color: active ? AppColors.accent : AppColors.text3,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: active ? AppColors.accent : AppColors.text3,
                          letterSpacing: 0.01,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon, activeIcon;
  final String label;
  const _TabItem(
      {required this.icon, required this.activeIcon, required this.label});
}
