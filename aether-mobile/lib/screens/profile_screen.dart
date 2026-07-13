// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../providers/api_keys_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/delta_pill.dart';
import '../widgets/glass_card.dart';
import '../widgets/profile_dialogs.dart';
import '../widgets/settings_toggle_row.dart';
import 'add_api_key_screen.dart';
import 'two_factor_setup_screen.dart';

// ── User provider ───────────────────────────────────────────────────────
final _profileApiProvider = Provider((_) => ApiService());
final userProvider = FutureProvider((ref) => ref.watch(_profileApiProvider).getUser());

// ── Local display name (editable until backend ready) ───────────────────
final _localNameProvider  = StateProvider<String?>((_) => null);
final _localEmailProvider = StateProvider<String?>((_) => null);

// ── Prefs ───────────────────────────────────────────────────────────────
class _Prefs {
  final bool twoFA, biometric, priceAlerts, riskAlerts;
  const _Prefs({this.twoFA=true, this.biometric=true, this.priceAlerts=true, this.riskAlerts=true});
  _Prefs cw({bool? twoFA, bool? biometric, bool? priceAlerts, bool? riskAlerts}) => _Prefs(
    twoFA: twoFA??this.twoFA, biometric: biometric??this.biometric,
    priceAlerts: priceAlerts??this.priceAlerts, riskAlerts: riskAlerts??this.riskAlerts);
}
class _PrefsN extends StateNotifier<_Prefs> {
  _PrefsN() : super(const _Prefs());
  void set({bool? twoFA, bool? biometric, bool? priceAlerts, bool? riskAlerts}) =>
      state = state.cw(twoFA: twoFA, biometric: biometric, priceAlerts: priceAlerts, riskAlerts: riskAlerts);
}
final prefsProvider = StateNotifierProvider<_PrefsN, _Prefs>((_) => _PrefsN());

// ── Screen ──────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync    = ref.watch(userProvider);
    final prefs        = ref.watch(prefsProvider);
    final prefsN       = ref.read(prefsProvider.notifier);
    final locale       = ref.watch(languageProvider);
    final apiKeysAsync = ref.watch(apiKeysProvider);
    final apiKeysN     = ref.read(apiKeysProvider.notifier);
    final localName    = ref.watch(_localNameProvider);
    final localEmail   = ref.watch(_localEmailProvider);
    final apiKeys      = apiKeysAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [SliverToBoxAdapter(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Top bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
              child: Row(children: [
                Text('Profil', style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3)),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final user = userAsync.valueOrNull;
                    if (user == null) return;
                    final result = await showProfileEditSheet(
                      context,
                      name: localName ?? user.name,
                      email: localEmail ?? user.email,
                    );
                    if (result != null) {
                      ref.read(_localNameProvider.notifier).state  = result['name'];
                      ref.read(_localEmailProvider.notifier).state = result['email'];
                    }
                  },
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: AppColors.hairline, width: 0.5),
                    ),
                    child: const Icon(Icons.edit_outlined, color: AppColors.text2, size: 16),
                  ),
                ),
              ]),
            ),

            // ── Avatar + name ──────────────────────────────────────────
            userAsync.when(
              data: (user) {
                final name  = localName  ?? user.name;
                final email = localEmail ?? user.email;
                final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
                return _ProfileHeader(initials: initials, name: name, email: email, kycVerified: user.kycVerified);
              },
              loading: () => const Padding(padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent))),
              error: (_, __) => const SizedBox(height: 120),
            ),

            // ── Asset card ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: userAsync.when(
                data: (u) => _AssetCard(balance: u.totalBalance, pnl: u.pnlPercent),
                loading: () => const SizedBox(height: 80),
                error: (_, __) => const SizedBox(height: 80),
              ),
            ),

            // ── Güvenlik ───────────────────────────────────────────────
            const _Label('Güvenlik'),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: GlassCard(child: Column(children: [
              SettingsToggleRow(icon: const Icon(Icons.security, color: AppColors.text2, size: 16),
                  title: 'İki Faktörlü Doğrulama', subtitle: 'Authenticator · son: 2 gün önce',
                  value: prefs.twoFA, onChanged: (v) {
                    if (v) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoFactorSetupScreen()));
                    }
                    prefsN.set(twoFA: v);
                  }),
              const Divider(color: AppColors.hairline, height: 0.5, indent: 56),
              SettingsToggleRow(icon: const Icon(Icons.face, color: AppColors.text2, size: 16),
                  title: 'Biyometrik Giriş', subtitle: 'Face ID / Parmak izi',
                  value: prefs.biometric, onChanged: (v) => prefsN.set(biometric: v)),
              const Divider(color: AppColors.hairline, height: 0.5, indent: 56),
              const SettingsLinkRow(icon: Icon(Icons.lock_outline, color: AppColors.text2, size: 16),
                  title: 'Parolayı Değiştir', subtitle: 'Son değişiklik 64 gün önce'),
            ]))),

            // ── API Yönetimi ───────────────────────────────────────────
            const _Label('API Yönetimi'),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: GlassCard(child: Column(children: [
              // Yükleniyor / hata durumu
              if (apiKeysAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
                )
              else if (apiKeysAsync.hasError)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('API anahtarları yüklenemedi.',
                      style: GoogleFonts.spaceGrotesk(color: AppColors.text3, fontSize: 13)),
                )
              else
                ...apiKeys.asMap().entries.expand((e) {
                  final k = e.value;
                  return [
                    if (e.key > 0) const Divider(color: AppColors.hairline, height: 0.5, indent: 56),
                    _ApiKeyRow(
                      key: ValueKey(k.id),
                      apiKey: k,
                      onEdit: () => showApiKeyDialog(context, existing: k,
                          onSave: (ex, mask) => apiKeysN.editLocal(k.id, ex, mask)),
                      onDelete: () => apiKeysN.removeKey(k.id),
                    ),
                  ];
                }),
              const Divider(color: AppColors.hairline, height: 0.5, indent: 0),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddApiKeyScreen())),
                child: Padding(padding: const EdgeInsets.fromLTRB(16, 13, 16, 13), child: Row(children: [
                  Container(width: 32, height: 32,
                      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.add, color: AppColors.accent, size: 16)),
                  const SizedBox(width: 12),
                  Text('Yeni API anahtarı ekle', style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.accent)),
                ])),
              ),
            ]))),

            // ── Uygulama ───────────────────────────────────────────────
            const _Label('Uygulama'),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: GlassCard(child: Column(children: [
              SettingsToggleRow(icon: const Icon(Icons.notifications_outlined, color: AppColors.text2, size: 16),
                  title: 'Fiyat Alarmları', subtitle: 'Hedef fiyat & anlık değişim',
                  value: prefs.priceAlerts, onChanged: (v) => prefsN.set(priceAlerts: v)),
              const Divider(color: AppColors.hairline, height: 0.5, indent: 56),
              SettingsToggleRow(icon: const Icon(Icons.warning_amber_outlined, color: AppColors.text2, size: 16),
                  title: 'Risk Uyarıları', subtitle: 'Stop-loss tetiklendiğinde',
                  value: prefs.riskAlerts, onChanged: (v) => prefsN.set(riskAlerts: v)),
              const Divider(color: AppColors.hairline, height: 0.5, indent: 56),
              _LanguageRow(locale: locale,
                  onChanged: (l) => ref.read(languageProvider.notifier).state = l),
            ]))),

            // ── Çıkış ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0x0FF08080),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x33F08080), width: 0.5)),
                child: TextButton.icon(
                  onPressed: () async {
                    final apiService = ref.read(apiServiceProvider);
                    await apiService.logout();
                    ref.read(authStateProvider.notifier).setAuthState(AuthState.auth);
                  },
                  icon: const Icon(Icons.logout, color: AppColors.loss, size: 17),
                  label: Text('Oturumu Kapat', style: GoogleFonts.spaceGrotesk(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.loss)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(0, 18, 0, 32),
              child: Center(child: Text('BORSA · v1.0.0 · build 2026.05.16',
                  style: TextStyle(fontSize: 10, color: AppColors.text4,
                      letterSpacing: 0.06, fontFamily: 'JetBrains Mono'))),
            ),
          ],
        ))],
      ),
    );
  }
}

// ── Widgets ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String initials, name, email;
  final bool kycVerified;
  const _ProfileHeader({required this.initials, required this.name, required this.email, required this.kycVerified});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      child: Center(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Stack(alignment: Alignment.center, children: [
          Container(width: 100, height: 100, decoration: BoxDecoration(
              shape: BoxShape.circle, border: Border.all(color: const Color(0x404D9FFF), width: 0.5))),
          Container(width: 92, height: 92,
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.accentGradient),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x734D9FFF), blurRadius: 40, offset: Offset(0, 14))],
              ),
              alignment: Alignment.center,
              child: Text(initials, style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white))),
          Positioned(bottom: 4, right: 4, child: Container(width: 16, height: 16,
              decoration: const BoxDecoration(color: AppColors.profit, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0xFF050816), spreadRadius: 3)]))),
        ]),
        const SizedBox(height: 14),
        Text(name, textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(
            fontSize: 21, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: AppColors.text1)),
        const SizedBox(height: 4),
        Text(email, textAlign: TextAlign.center, style: AppTheme.mono(fontSize: 12, color: AppColors.text3)),
        const SizedBox(height: 12),
        if (kycVerified) Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
          decoration: BoxDecoration(color: const Color(0x1A5FD49B), borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x475FD49B), width: 0.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 18, height: 18, decoration: const BoxDecoration(color: AppColors.profit, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Color(0xFF0A1320), size: 11)),
            const SizedBox(width: 6),
            Text('Hesap Onaylı · KYC', style: GoogleFonts.spaceGrotesk(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.profit)),
          ]),
        ),
      ])),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final double balance, pnl;
  const _AssetCard({required this.balance, required this.pnl});
  @override
  Widget build(BuildContext context) => GlassCard(child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16,14,16,14), child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accent, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TOPLAM VARLIK', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.text3, letterSpacing: 0.06)),
        const SizedBox(height: 2),
        RichText(text: TextSpan(children: [
          TextSpan(text: '\$84,273', style: AppTheme.mono(fontSize: 17, fontWeight: FontWeight.w500)),
          TextSpan(text: '.52', style: AppTheme.mono(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.text3)),
        ])),
      ])),
      DeltaPill(value: pnl),
    ])),
    const Divider(color: AppColors.hairline, height: 0.5, thickness: 0.5),
    Padding(padding: const EdgeInsets.fromLTRB(16,12,16,12), child: Row(children: [
      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.profit, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.profit, blurRadius: 8)])),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bağlı borsa', style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
        Text('Binance Sim API', style: AppTheme.mono(fontSize: 12, fontWeight: FontWeight.w500)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.profitSoft, borderRadius: BorderRadius.circular(6)),
          child: Text('CANLI', style: AppTheme.mono(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.profit))),
    ])),
  ]));
}

class _ApiKeyRow extends StatelessWidget {
  final ApiKey apiKey;
  final VoidCallback onEdit, onDelete;
  const _ApiKeyRow({super.key, required this.apiKey, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: Row(children: [
      Container(width: 32, height: 32,
          decoration: BoxDecoration(color: const Color(0x1A7C5CFF), borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.key_outlined, color: Color(0xFFA78BFA), size: 16)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(apiKey.exchange, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1)),
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(color: AppColors.profitSoft, borderRadius: BorderRadius.circular(4)),
              child: Text('aktif', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.profit))),
        ]),
        Text('API Key · ${apiKey.mask}', style: AppTheme.mono(fontSize: 12, color: AppColors.text3)),
      ])),
      GestureDetector(onTap: onEdit, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.hairline, width: 0.5)),
          child: Text('Düzenle', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)))),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF111828),
          title: Text('Sil', style: GoogleFonts.spaceGrotesk(color: AppColors.text1)),
          content: Text('${apiKey.exchange} anahtarını silmek istiyor musun?',
              style: GoogleFonts.spaceGrotesk(color: AppColors.text3)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text('İptal', style: GoogleFonts.spaceGrotesk(color: AppColors.text3))),
            TextButton(onPressed: () { Navigator.pop(ctx); onDelete(); },
                child: Text('Sil', style: GoogleFonts.spaceGrotesk(color: AppColors.loss, fontWeight: FontWeight.w600))),
          ],
        )),
        child: Container(width: 30, height: 30,
            decoration: BoxDecoration(color: const Color(0x0FF08080),
                borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0x22F08080), width: 0.5)),
            child: const Icon(Icons.delete_outline, color: AppColors.loss, size: 15)),
      ),
    ]));
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
    child: Text(text.toUpperCase(), style: GoogleFonts.spaceGrotesk(
        fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.11, color: AppColors.text3)),
  );
}

class _LanguageRow extends StatelessWidget {
  final Locale locale;
  final ValueChanged<Locale> onChanged;
  const _LanguageRow({required this.locale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 13, 16, 13), child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.language, color: AppColors.text2, size: 16)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Uygulama Dili', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1)),
        Text('Arayüz dilini seç', style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
      ])),
      Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.hairline, width: 0.5)),
        child: Row(children: ['tr', 'en'].map((code) {
          final sel = locale.languageCode == code;
          return GestureDetector(
            onTap: () => onChanged(Locale(code)),
            child: AnimatedContainer(duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: sel ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(7)),
              child: Text(code.toUpperCase(), style: AppTheme.mono(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.text2, letterSpacing: 0.04)),
            ),
          );
        }).toList()),
      ),
    ]));
  }
}
