// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  int _step = 0;

  static const _slides = [
    _Slide(
      eyebrow: 'AKILLI RİSK YÖNETİMİ',
      title: 'Her işlemde\nsermayeni koru.',
      body: 'Profilini bir kez tanımla — AETHER ideal alım miktarını ve stop-loss seviyesini saniyeler içinde hesaplasın.',
      visual: _VisualKind.shield,
    ),
    _Slide(
      eyebrow: 'TEK TIKLA POZİSYON',
      title: 'Hesaplama yok,\nsadece işlem.',
      body: 'Giriş ve stop fiyatını gir — kasanın %2 riskine göre coin adedi otomatik gelsin.',
      visual: _VisualKind.calc,
    ),
    _Slide(
      eyebrow: 'TÜM BORSALAR',
      title: 'Tek panelde\ntüm portföyün.',
      body: 'Binance, Bybit ve daha fazlası tek arayüzde. Hesaplar API ile bağlı, varlıklar canlı senkron.',
      visual: _VisualKind.rings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = _slides[_step];
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.6), radius: 1.4,
            colors: [const Color(0x1A4D9FFF), Colors.transparent])))),
        SafeArea(child: Column(children: [
          // Skip
          Align(alignment: Alignment.topRight,
            child: Padding(padding: const EdgeInsets.fromLTRB(0, 16, 22, 0),
              child: TextButton(onPressed: () => _finish(),
                child: Text('Atla', style: GoogleFonts.spaceGrotesk(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text3))))),
          // Visual
          Expanded(child: _OnboardingVisual(kind: s.visual)),
          // Copy
          Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Column(children: [
            Text(s.eyebrow, style: GoogleFonts.spaceGrotesk(
              fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.22,
              color: AppColors.accent)),
            const SizedBox(height: 12),
            Text(s.title, textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontSize: 27, fontWeight: FontWeight.w600,
                letterSpacing: -0.025 * 27, color: AppColors.text1, height: 1.2)),
            const SizedBox(height: 12),
            Text(s.body, textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontSize: 13.5, color: AppColors.text3, height: 1.55)),
          ])),
          const SizedBox(height: 20),
          // Dots
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_slides.length, (i) =>
            GestureDetector(onTap: () => setState(() => _step = i),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                width: i == _step ? 22 : 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _step ? AppColors.accent : const Color(0x1FFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: i == _step ? [const BoxShadow(color: Color(0x404D9FFF), blurRadius: 10)] : null,
                ))))),
          // CTA
          Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 12), child: GestureDetector(
            onTap: () => _step < _slides.length - 1
              ? setState(() => _step++)
              : _finish(),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF5AAAFF), Color(0xFF4D9FFF), Color(0xFF6A78FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0xB34D9FFF), blurRadius: 28, offset: Offset(0, 10))],
              ),
              child: Text(_step < _slides.length - 1 ? 'Devam Et' : 'Başlayalım',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
          )),
          Padding(padding: const EdgeInsets.only(bottom: 38), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Hesabınız var mı? ', style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: AppColors.text3)),
            GestureDetector(
              onTap: () => _finish(),
              child: Text('Giriş Yapın', style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ),
          ])),
        ])),
      ]),
    );
  }

  void _finish() {
    ref.read(authStateProvider.notifier).completeOnboarding();
  }
}

// ── Visual ──────────────────────────────────────────────────────────────
enum _VisualKind { shield, calc, rings }

class _Slide {
  final String eyebrow, title, body;
  final _VisualKind visual;
  const _Slide({required this.eyebrow, required this.title, required this.body, required this.visual});
}

class _OnboardingVisual extends StatelessWidget {
  final _VisualKind kind;
  const _OnboardingVisual({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Center(child: SizedBox(width: 220, height: 200, child: Stack(alignment: Alignment.center, children: [
      // Halo
      Container(width: 200, height: 200, decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          (kind == _VisualKind.calc ? const Color(0x2E7C5CFF) : const Color(0x334D9FFF)),
          Colors.transparent], stops: const [0, 0.65]))),
      // Rings
      ...([180.0, 130.0, 90.0].asMap().entries.map((e) => Container(
        width: e.value, height: e.value,
        decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4D9FFF).withValues(alpha: 0.15 - e.key * 0.04), width: 0.5))))),
      // Main icon
      if (kind == _VisualKind.shield) _ShieldVisual()
      else if (kind == _VisualKind.calc) _CalcVisual()
      else _RingsVisual(),
    ])));
  }
}

class _ShieldVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(colors: AppColors.accentGradient).createShader(r),
      child: const Icon(Icons.shield_outlined, size: 80, color: Colors.white));
  }
}

class _CalcVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Container(width: 160, height: 100, decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF7C5CFF).withValues(alpha: 0.15), Colors.transparent]),
        borderRadius: BorderRadius.circular(12))),
      const Icon(Icons.calculate_outlined, size: 60, color: Color(0xFF7C5CFF)),
      Positioned(top: 0, right: 0, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xCC080B1C),
          border: Border.all(color: const Color(0x667C5CFF), width: 0.5),
          borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('İDEAL', style: AppTheme.mono(fontSize: 9, color: AppColors.text3, letterSpacing: 0.04)),
          Text('0.4321 BTC', style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w600)),
        ]))),
    ]);
  }
}

class _RingsVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chips = [
      _Chip('B', const Color(0xFFF7A13A), const Offset(0, -60)),
      _Chip('BY', const Color(0xFF7C5CFF), const Offset(60, 20)),
      _Chip('KU', const Color(0xFF5FD49B), const Offset(-60, 20)),
      _Chip('OK', const Color(0xFF4D9FFF), const Offset(0, 70)),
    ];
    return Stack(alignment: Alignment.center, children: [
      ...chips.map((c) => Transform.translate(offset: c.offset, child: Container(
        width: 44, height: 44, decoration: BoxDecoration(
          color: c.color.withValues(alpha: 0.13),
          border: Border.all(color: c.color.withValues(alpha: 0.4), width: 0.5),
          borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: Text(c.label, style: AppTheme.mono(fontSize: 13, fontWeight: FontWeight.w700, color: c.color))))),
      // Center AETHER mark
      Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(colors: AppColors.accentGradient)),
        child: const Icon(Icons.hub_outlined, color: Colors.white, size: 28)),
    ]);
  }
}

class _Chip {
  final String label;
  final Color color;
  final Offset offset;
  const _Chip(this.label, this.color, this.offset);
}
