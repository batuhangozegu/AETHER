// lib/screens/two_factor_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  String? _secret;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSecret();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSecret() async {
    try {
      final (secret, _) = await ref.read(apiServiceProvider).setup2fa();
      setState(() {
        _secret = secret;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _enable() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('6 haneli kodu girin')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(apiServiceProvider).enable2fa(code);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Doğrulama başarısız: $e'), backgroundColor: AppColors.loss),
        );
      }
    }
  }

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
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.arrow_back, color: AppColors.text2, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Güvenlik', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text3)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('Kurulum başlatılamadı: $_error',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceGrotesk(color: AppColors.loss)),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'İKİ FAKTÖRLÜ DOĞRULAMA',
                                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent, letterSpacing: 2.2),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hesabını koru.',
                                style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text1, letterSpacing: -0.4),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Google Authenticator veya Authy\'de aşağıdaki anahtarı manuel olarak ekle, sonra uygulamanın gösterdiği 6 haneli kodu gir.',
                                style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: AppColors.text3, height: 1.5),
                              ),
                              const SizedBox(height: 22),

                              // Secret card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x0AFFFFFF), Color(0x04FFFFFF)]),
                                  border: Border.all(color: AppColors.hairline, width: 0.5),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0x4D000000),
                                        border: Border.all(color: AppColors.hairline, width: 0.5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _secret ?? '',
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTheme.mono(fontSize: 13, color: AppColors.text2, letterSpacing: 0.4),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              if (_secret != null) {
                                                Clipboard.setData(ClipboardData(text: _secret!));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Anahtar kopyalandı')),
                                                );
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(7)),
                                              child: Text('Kopyala', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              Text('Doğrulama Kodu', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.text3, letterSpacing: 0.4)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _codeCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: AppTheme.mono(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 6),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '000000',
                                  filled: true,
                                  fillColor: const Color(0x09FFFFFF),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.hairline, width: 0.5)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.hairline, width: 0.5)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.accent, width: 1)),
                                ),
                              ),
                              const SizedBox(height: 22),
                              AuthPrimaryButton2FA(
                                label: _submitting ? 'Doğrulanıyor...' : '2FA\'yı Etkinleştir',
                                onPressed: _submitting ? null : _enable,
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPrimaryButton2FA extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const AuthPrimaryButton2FA({super.key, required this.label, required this.onPressed});

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
