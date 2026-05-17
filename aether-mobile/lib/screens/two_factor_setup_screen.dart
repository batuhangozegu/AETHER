// lib/screens/two_factor_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'forgot_password_screen.dart';

class TwoFactorSetupScreen extends StatelessWidget {
  const TwoFactorSetupScreen({super.key});

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
              child: SingleChildScrollView(
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
                      'Google Authenticator veya Authy\'de QR kodunu tara ya da aşağıdaki anahtarı kopyala.',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12.5, color: AppColors.text3, height: 1.5),
                    ),
                    const SizedBox(height: 22),

                    // QR Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x0AFFFFFF), Color(0x04FFFFFF)]),
                        border: Border.all(color: AppColors.hairline, width: 0.5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          _FakeQRCode(size: 170),
                          const SizedBox(height: 14),
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
                                    'JBSWY3DPEHPK3PXP·AETHER·MK',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.mono(fontSize: 11, color: AppColors.text2, letterSpacing: 0.4),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(7)),
                                  child: Text('Kopyala', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6-digit verify
                    Text('Doğrulama Kodu', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.text3, letterSpacing: 0.4)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['8', '2', '4', '0', '', ''].map((c) {
                        final filled = c.isNotEmpty;
                        return Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: filled ? const Color(0x0F4D9FFF) : const Color(0x09FFFFFF),
                            border: Border.all(color: filled ? const Color(0x804D9FFF) : AppColors.hairline, width: 0.5),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            c,
                            style: AppTheme.mono(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.text1),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    AuthPrimaryButton(
                      label: '2FA\'yı Etkinleştir',
                      onPressed: () {
                        Navigator.pop(context);
                      },
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

class _FakeQRCode extends StatelessWidget {
  final double size;
  const _FakeQRCode({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x804D9FFF), blurRadius: 30, spreadRadius: -10)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dummy QR grid visualization
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 25),
            itemCount: 25 * 25,
            itemBuilder: (context, i) {
              final r = i ~/ 25;
              final c = i % 25;
              final v = ((i * 1103515245 + 12345) % 100);
              bool fill = v < 48;
              
              // finders
              if ((r < 7 && c < 7) || (r < 7 && c >= 18) || (r >= 18 && c < 7)) {
                bool border = r == 0 || r == 6 || c == 0 || c == 6 || (r >= 18 && (r == 18 || r == 24)) || (c >= 18 && (c == 18 || c == 24));
                bool inner = (r >= 2 && r <= 4 && c >= 2 && c <= 4) ||
                             (r >= 2 && r <= 4 && c >= 20 && c <= 22) ||
                             (r >= 20 && r <= 22 && c >= 2 && c <= 4);
                fill = border || inner;
              }

              return fill ? Container(color: AppColors.bg0) : const SizedBox();
            },
          ),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white, width: 3)),
            child: const Icon(Icons.check, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}
