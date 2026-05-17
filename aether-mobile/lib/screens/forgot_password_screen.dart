// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialStage;
  const ForgotPasswordScreen({super.key, this.initialStage = 'email'});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late String _step = widget.initialStage;
  String _email = '';
  final List<String> _code = ['', '', '', '', '', ''];
  String _pw = '';
  String _pw2 = '';
  bool _s1Visible = false;
  bool _s2Visible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_step == 'code') setState(() => _step = 'email');
                      else if (_step == 'new') setState(() => _step = 'code');
                      else Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.arrow_back, color: AppColors.text2, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Giriş Yap', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text3)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _step == 'email' ? 'ADIM 1/3' : _step == 'code' ? 'ADIM 2/3' : 'ADIM 3/3',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent, letterSpacing: 2.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == 'email' ? 'Parolanı sıfırla' : _step == 'code' ? 'E-postanı kontrol et' : 'Yeni parola belirle',
                      style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text1, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == 'email'
                          ? 'Hesabınla eşleşen e-postayı gir; sana 6 haneli kod göndereceğiz.'
                          : _step == 'code'
                              ? '$_email adresine gönderilen 6 haneli kodu gir.'
                              : 'Yeni parolanı oluştur. Eski parolanla aynı olamaz.',
                      style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    if (_step == 'email') _buildEmailStep(),
                    if (_step == 'code') _buildCodeStep(),
                    if (_step == 'new') _buildNewPasswordStep(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'E-posta',
          hint: 'ornek@aether.app',
          initialValue: _email,
          onChanged: (v) => _email = v,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Kodu Gönder',
          onPressed: () {
            if (_email.isNotEmpty) setState(() => _step = 'code');
          },
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            final c = _code[i];
            final filled = c.isNotEmpty;
            return Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filled ? const Color(0x0F4D9FFF) : const Color(0x09FFFFFF),
                border: Border.all(color: filled ? const Color(0x804D9FFF) : AppColors.hairline, width: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                c.isEmpty && i == 0 ? '|' : c,
                style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.text1),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text.rich(TextSpan(
            style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3),
            children: const [
              TextSpan(text: 'Kod gelmedi mi? '),
              TextSpan(text: 'Yeniden gönder (00:42)', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
            ],
          )),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Devam Et',
          onPressed: () {
            // For demo, we just go to next step
            setState(() => _step = 'new');
          },
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(
          label: 'Yeni Parola',
          hint: 'En az 8 karakter',
          obscureText: !_s1Visible,
          onChanged: (v) => setState(() => _pw = v),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _s1Visible = !_s1Visible),
            child: Icon(_s1Visible ? Icons.visibility : Icons.visibility_off, color: AppColors.text3, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        PasswordStrengthIndicator(password: _pw),
        const SizedBox(height: 14),
        AuthField(
          label: 'Parola (Tekrar)',
          hint: 'Parolayı tekrar gir',
          obscureText: !_s2Visible,
          onChanged: (v) => _pw2 = v,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _s2Visible = !_s2Visible),
            child: Icon(_s2Visible ? Icons.visibility : Icons.visibility_off, color: AppColors.text3, size: 20),
          ),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Parolayı Güncelle',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class AuthField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const AuthField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _focused = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: GoogleFonts.spaceGrotesk(
        fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.04, color: _focused ? AppColors.accent : AppColors.text3)),
      const SizedBox(height: 6),
      AnimatedContainer(duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _focused ? const Color(0x0A4D9FFF) : const Color(0x09FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _focused ? const Color(0x884D9FFF) : AppColors.hairline, width: 0.5)),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            onTap: () => setState(() => _focused = true),
            onTapOutside: (_) {
              setState(() => _focused = false);
              FocusScope.of(context).unfocus();
            },
            style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.spaceGrotesk(fontSize: 14, color: AppColors.text4),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
            ),
          )),
          if (widget.suffixIcon != null) Padding(padding: const EdgeInsets.only(right: 8), child: widget.suffixIcon!),
        ]),
      ),
    ]);
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const AuthPrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: AppColors.accentGradient),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x404D9FFF), blurRadius: 28, offset: Offset(0, 10))],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const PasswordStrengthIndicator({super.key, required this.password});

  int get _strength {
    int s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'[0-9]').hasMatch(password)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final s = _strength;
    final pwColors = [AppColors.loss, AppColors.loss, const Color(0xFFF5B969), AppColors.profit, AppColors.profit];
    final pwLabels = ['Çok zayıf', 'Zayıf', 'Orta', 'Güçlü', 'Çok güçlü'];
    
    return Row(children: [
      ...List.generate(4, (i) => Expanded(child: Container(
        height: 3, margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          color: i < s ? pwColors[s] : const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(999)),
      ))),
      const SizedBox(width: 8),
      Text(pwLabels[s], style: AppTheme.mono(fontSize: 10, color: pwColors[s])),
    ]);
  }
}
