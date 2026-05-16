// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/delta_pill.dart';
import '../widgets/glass_card.dart';
import '../widgets/settings_toggle_row.dart';

// ── Providers ──────────────────────────────────────────────────────────
final _profileApiProvider = Provider((_) => ApiService());
final userProvider = FutureProvider((ref) {
  return ref.watch(_profileApiProvider).getUser();
});

class _ProfilePrefs {
  final bool twoFA, biometric, priceAlerts, riskAlerts;
  final String currency;

  const _ProfilePrefs({
    this.twoFA = true,
    this.biometric = true,
    this.priceAlerts = true,
    this.riskAlerts = true,
    this.currency = 'USD',
  });

  _ProfilePrefs copyWith({
    bool? twoFA,
    bool? biometric,
    bool? priceAlerts,
    bool? riskAlerts,
    String? currency,
  }) =>
      _ProfilePrefs(
        twoFA: twoFA ?? this.twoFA,
        biometric: biometric ?? this.biometric,
        priceAlerts: priceAlerts ?? this.priceAlerts,
        riskAlerts: riskAlerts ?? this.riskAlerts,
        currency: currency ?? this.currency,
      );
}

final prefsProvider =
    StateNotifierProvider<_PrefsNotifier, _ProfilePrefs>(
        (_) => _PrefsNotifier());

class _PrefsNotifier extends StateNotifier<_ProfilePrefs> {
  _PrefsNotifier() : super(const _ProfilePrefs());
  void set(
          {bool? twoFA,
          bool? biometric,
          bool? priceAlerts,
          bool? riskAlerts,
          String? currency}) =>
      state = state.copyWith(
        twoFA: twoFA,
        biometric: biometric,
        priceAlerts: priceAlerts,
        riskAlerts: riskAlerts,
        currency: currency,
      );
}

// ── Screen ─────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final prefs = ref.watch(prefsProvider);
    final prefsNotifier = ref.read(prefsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
                  child: Row(
                    children: [
                      Text('Profil',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 13, color: AppColors.text3)),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0x0AFFFFFF),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                              color: AppColors.hairline, width: 0.5),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            color: AppColors.text2, size: 16),
                      ),
                    ],
                  ),
                ),

                // Avatar + name
                userAsync.when(
                  data: (user) => _buildProfileHeader(user.initials,
                      user.name, user.email, user.kycVerified),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent)),
                  ),
                  error: (_, __) => const SizedBox(height: 120),
                ),

                // Asset summary card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: userAsync.when(
                    data: (user) => _buildAssetCard(user.totalBalance,
                        user.pnlPercent),
                    loading: () => const SizedBox(height: 80),
                    error: (_, __) => const SizedBox(height: 80),
                  ),
                ),

                // Security
                const _SectionLabel('Güvenlik'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: GlassCard(
                    child: Column(
                      children: [
                        SettingsToggleRow(
                          icon: const Icon(Icons.security,
                              color: AppColors.text2, size: 16),
                          title: 'İki Faktörlü Doğrulama',
                          subtitle: 'Authenticator · son: 2 gün önce',
                          value: prefs.twoFA,
                          onChanged: (v) => prefsNotifier.set(twoFA: v),
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 0.5,
                            indent: 56),
                        SettingsToggleRow(
                          icon: const Icon(Icons.face,
                              color: AppColors.text2, size: 16),
                          title: 'Biyometrik Giriş',
                          subtitle: 'Face ID / Parmak izi',
                          value: prefs.biometric,
                          onChanged: (v) =>
                              prefsNotifier.set(biometric: v),
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 0.5,
                            indent: 56),
                        const SettingsLinkRow(
                          icon: Icon(Icons.lock_outline,
                              color: AppColors.text2, size: 16),
                          title: 'Parolayı Değiştir',
                          subtitle: 'Son değişiklik 64 gün önce',
                        ),
                      ],
                    ),
                  ),
                ),

                // API Management
                const _SectionLabel('API Yönetimi'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: GlassCard(
                    child: Column(
                      children: [
                        const _ApiKeyRow(exchange: 'Binance', mask: '****4291'),
                        const Divider(
                            color: AppColors.hairline,
                            height: 0.5,
                            indent: 56),
                        const _ApiKeyRow(exchange: 'Bybit', mask: '****8830'),
                        const Divider(
                            color: AppColors.hairline,
                            height: 0.5,
                            indent: 56),
                        InkWell(
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSoft,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: AppColors.accent, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Text('Yeni API anahtarı ekle',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.accent,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // App settings
                const _SectionLabel('Uygulama'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: GlassCard(
                    child: Column(
                      children: [
                        SettingsToggleRow(
                          icon: const Icon(Icons.notifications_outlined,
                              color: AppColors.text2, size: 16),
                          title: 'Fiyat Alarmları',
                          subtitle: 'Hedef fiyat & anlık değişim',
                          value: prefs.priceAlerts,
                          onChanged: (v) =>
                              prefsNotifier.set(priceAlerts: v),
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 0.5,
                            indent: 56),
                        SettingsToggleRow(
                          icon: const Icon(Icons.warning_amber_outlined,
                              color: AppColors.text2, size: 16),
                          title: 'Risk Uyarıları',
                          subtitle: 'Stop-loss tetiklendiğinde',
                          value: prefs.riskAlerts,
                          onChanged: (v) =>
                              prefsNotifier.set(riskAlerts: v),
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 0.5,
                            indent: 56),
                        _CurrencyRow(
                          value: prefs.currency,
                          onChanged: (c) =>
                              prefsNotifier.set(currency: c),
                        ),
                        const Divider(
                            color: AppColors.hairline,
                            height: 0.5,
                            indent: 56),
                        const SettingsLinkRow(
                          icon: Icon(Icons.language,
                              color: AppColors.text2, size: 16),
                          title: 'Dil',
                          subtitle: 'Türkçe',
                        ),
                      ],
                    ),
                  ),
                ),

                // Logout
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0x0FF08080),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0x33F08080), width: 0.5),
                    ),
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.logout,
                          color: AppColors.loss, size: 17),
                      label: Text('Oturumu Kapat',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.loss,
                            letterSpacing: -0.1,
                          )),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),

                // Version
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 18, 0, 32),
                  child: Center(
                    child: Text(
                      'BORSA · v1.0.0 · build 2026.05.16',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.text4,
                          letterSpacing: 0.06,
                          fontFamily: 'JetBrains Mono'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      String initials, String name, String email, bool kycVerified) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.accentGradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x734D9FFF),
                      blurRadius: 40,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              // Halo ring
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0x404D9FFF), width: 0.5),
                  ),
                ),
              ),
              // Online dot
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.profit,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0xFF050816),
                          spreadRadius: 3,
                          blurRadius: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: AppColors.text1,
              )),
          const SizedBox(height: 4),
          Text(email,
              style: AppTheme.mono(fontSize: 12, color: AppColors.text3)),
          const SizedBox(height: 12),
          if (kycVerified)
            Container(
              padding:
                  const EdgeInsets.fromLTRB(8, 5, 12, 5),
              decoration: BoxDecoration(
                color: const Color(0x1A5FD49B),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: const Color(0x475FD49B), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.profit,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Color(0xFF0A1320), size: 11),
                  ),
                  const SizedBox(width: 6),
                  Text('Hesap Onaylı · KYC',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.profit,
                        letterSpacing: 0.02,
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(double balance, double pnlPercent) {
    return GlassCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOPLAM VARLIK',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            color: AppColors.text3,
                            letterSpacing: 0.06,
                          )),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\$84,273',
                              style: AppTheme.mono(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500),
                            ),
                            TextSpan(
                              text: '.52',
                              style: AppTheme.mono(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.text3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                DeltaPill(value: pnlPercent),
              ],
            ),
          ),
          const Divider(
              color: AppColors.hairline, height: 0.5, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.profit,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.profit,
                          blurRadius: 8,
                          spreadRadius: 0),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bağlı borsa',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 11, color: AppColors.text3)),
                      Text('Binance Sim API',
                          style: AppTheme.mono(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.profitSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('CANLI',
                      style: AppTheme.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.profit)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.11,
          color: AppColors.text3,
        ),
      ),
    );
  }
}

class _ApiKeyRow extends StatelessWidget {
  final String exchange, mask;
  const _ApiKeyRow({required this.exchange, required this.mask});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0x1A7C5CFF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.key_outlined,
                color: Color(0xFFA78BFA), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(exchange,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text1,
                        )),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.profitSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('aktif',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.profit,
                            letterSpacing: 0.04,
                          )),
                    ),
                  ],
                ),
                Text('API Key · $mask',
                    style: AppTheme.mono(
                        fontSize: 12,
                        color: AppColors.text3,
                        letterSpacing: 0.04)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.hairline, width: 0.5),
            ),
            child: Text('Düzenle',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text2)),
          ),
        ],
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CurrencyRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.attach_money,
                color: AppColors.text2, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yerel Para Birimi',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text1,
                      letterSpacing: -0.01,
                    )),
                Text('Fiyatları bu birimde göster',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 11, color: AppColors.text3)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.hairline, width: 0.5),
            ),
            child: Row(
              children: ['USD', 'TRY'].map((c) {
                final selected = value == c;
                return GestureDetector(
                  onTap: () => onChanged(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: selected
                          ? [
                              const BoxShadow(
                                color: Color(0x404D9FFF),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      c,
                      style: AppTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.text2,
                        letterSpacing: 0.04,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
