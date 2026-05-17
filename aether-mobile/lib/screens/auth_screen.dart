// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  @override
  Widget build(BuildContext context) => _isLogin
      ? _LoginView(onSwitch: () => setState(() => _isLogin = false))
      : _RegisterView(onSwitch: () => setState(() => _isLogin = true));
}

// ── Login ──────────────────────────────────────────────────────────────
class _LoginView extends StatefulWidget {
  final VoidCallback onSwitch;
  const _LoginView({required this.onSwitch});
  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailCtrl = TextEditingController(text: 'mert.kaya@aether.app');
  final _pwCtrl    = TextEditingController(text: '••••••••');
  bool _showPw = false;

  @override
  void dispose() { _emailCtrl.dispose(); _pwCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (ctx, ref, _) => Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(children: [
        // Aurora background
        Positioned.fill(child: DecoratedBox(decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.6), radius: 1.4,
            colors: [Color(0x1A4D9FFF), Colors.transparent]),
        ))),
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 78),
            // AETHER mark
            const _AetherMark(size: 72),
            const SizedBox(height: 22),
            Text('AETHER', style: GoogleFonts.spaceGrotesk(
              fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.32, color: AppColors.accent)),
            const SizedBox(height: 12),
            Text("AETHER'a Hoş Geldiniz", style: GoogleFonts.spaceGrotesk(
              fontSize: 24, fontWeight: FontWeight.w600,
              letterSpacing: -0.02 * 24, color: AppColors.text1)),
            const SizedBox(height: 6),
            Text('Akıllı risk yönetimi ile portföyünüze devam edin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3, height: 1.5)),
            const SizedBox(height: 36),
            // Form
            _AuthField(label: 'E-POSTA', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _AuthField(label: 'PAROLA', controller: _pwCtrl,
              obscureText: !_showPw,
              suffix: IconButton(
                icon: Icon(_showPw ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.text3, size: 18),
                onPressed: () => setState(() => _showPw = !_showPw),
              )),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                child: Text('Şifremi Unuttum?', style: GoogleFonts.spaceGrotesk(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text2)))),
            const SizedBox(height: 10),
            _PrimaryButton(label: 'Giriş Yap', onTap: () {
              ref.read(authStateProvider.notifier).state = AuthState.app;
            }),
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(child: Divider(color: AppColors.hairline, thickness: 0.5)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('VEYA', style: AppTheme.mono(fontSize: 10, color: AppColors.text4, letterSpacing: 0.08))),
              const Expanded(child: Divider(color: AppColors.hairline, thickness: 0.5)),
            ]),
            const SizedBox(height: 14),
            // Face ID button
            _SecondaryButton(
              icon: const Icon(Icons.face_retouching_natural, size: 18, color: AppColors.text1),
              label: 'Face ID ile devam et',
              onTap: () {},
            ),
            const SizedBox(height: 48),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Hesabınız yok mu? ', style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3)),
              GestureDetector(onTap: widget.onSwitch,
                child: Text('Kayıt Olun', style: GoogleFonts.spaceGrotesk(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent))),
            ]),
            const SizedBox(height: 32),
          ]),
        )),
      ]),
    ));
  }
}

// ── Register ────────────────────────────────────────────────────────────
class _RegisterView extends StatefulWidget {
  final VoidCallback onSwitch;
  const _RegisterView({required this.onSwitch});
  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _userCtrl = TextEditingController();
  final _mailCtrl = TextEditingController();
  final _pw1Ctrl  = TextEditingController();
  final _pw2Ctrl  = TextEditingController();
  bool _showPw1 = false, _showPw2 = false, _agree = true;

  int get _strength {
    final p = _pw1Ctrl.text;
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength;
    final pwColors = [AppColors.loss, AppColors.loss, const Color(0xFFF5B969), AppColors.profit, AppColors.profit];
    final pwLabels = ['Çok zayıf', 'Zayıf', 'Orta', 'Güçlü', 'Çok güçlü'];

    return Consumer(builder: (ctx, ref, _) => Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(children: [
        Positioned.fill(child: const DecoratedBox(decoration: BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.6), radius: 1.4,
            colors: [Color(0x1A7C5CFF), Colors.transparent]),
        ))),
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 60),
            const _AetherMark(size: 60),
            const SizedBox(height: 18),
            Text('AETHER', style: GoogleFonts.spaceGrotesk(
              fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.32, color: AppColors.accent)),
            const SizedBox(height: 10),
            Text('Yeni Hesap Oluştur', style: GoogleFonts.spaceGrotesk(
              fontSize: 23, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: AppColors.text1)),
            const SizedBox(height: 4),
            Text('30 saniyede başla — KYC sonradan tamamlanabilir.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3, height: 1.5)),
            const SizedBox(height: 24),
            _AuthField(label: 'KULLANICI ADI', controller: _userCtrl, hint: 'aether_trader'),
            const SizedBox(height: 12),
            _AuthField(label: 'E-POSTA', controller: _mailCtrl, hint: 'ornek@aether.app',
              keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _AuthField(label: 'PAROLA', controller: _pw1Ctrl, hint: 'En az 8 karakter',
              obscureText: !_showPw1,
              suffix: IconButton(
                icon: Icon(_showPw1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.text3, size: 18),
                onPressed: () => setState(() => _showPw1 = !_showPw1))),
            const SizedBox(height: 6),
            // Password strength
            if (_pw1Ctrl.text.isNotEmpty) ...[
              Row(children: [
                ...List.generate(4, (i) => Expanded(child: Container(
                  height: 3, margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: i < s ? pwColors[s] : const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(999)),
                ))),
                const SizedBox(width: 8),
                Text(pwLabels[s], style: AppTheme.mono(fontSize: 10, color: pwColors[s])),
              ]),
              const SizedBox(height: 6),
            ],
            _AuthField(label: 'PAROLA (TEKRAR)', controller: _pw2Ctrl, hint: 'Parolayı tekrar girin',
              obscureText: !_showPw2,
              suffix: IconButton(
                icon: Icon(_showPw2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.text3, size: 18),
                onPressed: () => setState(() => _showPw2 = !_showPw2))),
            const SizedBox(height: 14),
            // Terms
            GestureDetector(
              onTap: () => setState(() => _agree = !_agree),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedContainer(duration: const Duration(milliseconds: 150),
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: _agree ? AppColors.accent : const Color(0x07FFFFFF),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _agree ? AppColors.accent : AppColors.hairlineStrong, width: 0.5),
                    boxShadow: _agree ? [const BoxShadow(color: Color(0x404D9FFF), blurRadius: 12)] : null,
                  ),
                  child: _agree ? const Icon(Icons.check, color: Colors.white, size: 12) : null),
                const SizedBox(width: 10),
                Expanded(child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Kullanım Şartları', style: GoogleFonts.spaceGrotesk(color: AppColors.text2, fontSize: 11.5)),
                  TextSpan(text: "'nı ve ", style: GoogleFonts.spaceGrotesk(color: AppColors.text3, fontSize: 11.5)),
                  TextSpan(text: 'Gizlilik Politikası', style: GoogleFonts.spaceGrotesk(color: AppColors.text2, fontSize: 11.5)),
                  TextSpan(text: "'nı kabul ediyorum.", style: GoogleFonts.spaceGrotesk(color: AppColors.text3, fontSize: 11.5)),
                ]))),
              ]),
            ),
            const SizedBox(height: 20),
            _PrimaryButton(label: 'Kayıt Ol', onTap: () {
              ref.read(authStateProvider.notifier).state = AuthState.app;
            }),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Zaten hesabınız var mı? ', style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3)),
              GestureDetector(onTap: widget.onSwitch,
                child: Text('Giriş Yapın', style: GoogleFonts.spaceGrotesk(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent))),
            ]),
            const SizedBox(height: 38),
          ]),
        )),
      ]),
    ));
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────

class _AetherMark extends StatelessWidget {
  final double size;
  const _AetherMark({required this.size});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _AetherPainter()));
  }
}

class _AetherPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.42;
    final grad = const LinearGradient(colors: AppColors.accentGradient)
      .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final ringPaint = Paint()..shader = grad..style = PaintingStyle.stroke..strokeWidth = size.width * 0.02..color = const Color(0xFF4D9FFF);

    // 3 orbits
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(i * 3.14159 / 3);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 0.76), ringPaint..color = const Color(0xFF4D9FFF).withValues(alpha: 0.85));
      canvas.restore();
    }

    // Nucleus
    final corePaint = Paint()..shader = const RadialGradient(
      colors: [Color(0xFFE8ECF6), Color(0xFF4D9FFF), Color(0xFF7C5CFF)],
      stops: [0, 0.6, 1],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.14));
    canvas.drawCircle(Offset(cx, cy), size.width * 0.14, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _AuthField({
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: GoogleFonts.spaceGrotesk(
        fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.04,
        color: _focused ? AppColors.accent : AppColors.text3)),
      const SizedBox(height: 6),
      AnimatedContainer(duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _focused ? const Color(0x0A4D9FFF) : const Color(0x09FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? const Color(0x884D9FFF) : AppColors.hairline,
            width: 0.5),
          boxShadow: _focused ? [const BoxShadow(color: Color(0x1A4D9FFF), blurRadius: 12)] : null,
        ),
        child: Row(children: [
          Expanded(child: TextField(
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onTap: () => setState(() => _focused = true),
            onTapOutside: (_) => setState(() => _focused = false),
            style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text1),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.spaceGrotesk(fontSize: 15, color: AppColors.text4),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              isDense: true,
            ),
          )),
          if (widget.suffix != null) widget.suffix!,
        ]),
      ),
    ]);
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF5AAAFF), Color(0xFF4D9FFF), Color(0xFF6A78FF)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0xB34D9FFF), blurRadius: 28, offset: Offset(0, 10)),
            BoxShadow(color: Color(0x667C5CFF), blurRadius: 28),
          ],
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairline, width: 0.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon, const SizedBox(width: 10),
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text1)),
        ]),
      ),
    );
  }
}
