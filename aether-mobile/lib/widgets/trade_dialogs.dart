// lib/widgets/trade_dialogs.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'coin_avatar.dart';
import 'delta_pill.dart';

void showOrderConfirmSheet(BuildContext context, {required bool isBuy, required double entry, required double stop, required double target}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _OrderConfirmSheet(),
  );
}

class _OrderConfirmSheet extends StatelessWidget {
  const _OrderConfirmSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xF2141A3A), Color(0xFC080B1C)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: AppColors.hairlineStrong, width: 0.5)),
      ),
      child: Column(children: [
        // Handle
        Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 36, height: 4, decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(999)))),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 4, 22, 24), child: Column(children: [
          Text('EMİR ONAYI', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent, letterSpacing: 0.11)),
          const SizedBox(height: 4),
          Text('Emir özetini gözden geçir', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text1, letterSpacing: -0.4)),
          const SizedBox(height: 16),

          // Big numbers card
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(color: AppColors.profitSoft,
              border: Border.all(color: const Color(0x3D5FD49B), width: 0.5),
              borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.profit.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text('ALIŞ', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.profit, letterSpacing: 0.06))),
                const SizedBox(width: 10),
                const CoinAvatar(symbol: 'BTC', size: 26),
                const SizedBox(width: 6),
                Text('Bitcoin', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1)),
                const Spacer(),
                Text('BTC/USD', style: AppTheme.mono(fontSize: 11, color: AppColors.text3)),
              ]),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text('0.4321', style: AppTheme.mono(fontSize: 32, fontWeight: FontWeight.w500, letterSpacing: -0.5)),
                const SizedBox(width: 6),
                Text('BTC', style: GoogleFonts.spaceGrotesk(fontSize: 16, color: AppColors.text2)),
              ]),
              Text('≈ \$29,051.00', style: AppTheme.mono(fontSize: 13, color: AppColors.text2)),
            ]),
          ),
          const SizedBox(height: 14),

          // Detail rows
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: const Color(0x07FFFFFF),
              border: Border.all(color: AppColors.hairline, width: 0.5),
              borderRadius: BorderRadius.circular(14)),
            child: const Column(children: [
              _Row('Emir tipi', 'Piyasa'),
              _Row('Giriş fiyatı', '\$67,234.12', mono: true),
              _Row('Zarar kes (SL)', '\$65,800.00', mono: true, valColor: AppColors.loss),
              _Row('Kâr al (TP)', '\$70,820.40', mono: true, valColor: AppColors.profit),
              _Row('Risk / Ödül', '1:2.5'),
              _Row('Komisyon', '\$29.05 (0.10%)', mono: true),
              _Row('Toplam tutar', '\$29,080.05', mono: true, isLast: true, bold: true),
            ]),
          ),
          const SizedBox(height: 16),

          // Risk badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.accentSoft,
              border: Border.all(color: AppColors.hairlineAccent, width: 0.5),
              borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.shield_outlined, color: AppColors.accent, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text.rich(TextSpan(
                style: GoogleFonts.spaceGrotesk(fontSize: 11.5, color: AppColors.text2, height: 1.5),
                children: const [
                  TextSpan(text: 'Risk profiline uygun: kasanın '),
                  TextSpan(text: '%2.0', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                  TextSpan(text: '\'i, pozisyon '),
                  TextSpan(text: '%34.5', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                  TextSpan(text: '.'),
                ],
              ))),
            ]),
          ),
          const SizedBox(height: 16),

          // Slide to confirm (simplified as button for now)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5FD49B), Color(0xFF3A9C70)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x665FD49B), blurRadius: 28, offset: Offset(0, 8))],
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderSuccessScreen()));
              },
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text('Onaylamak için dokun', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
            ),
          ),
          const SizedBox(height: 8),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3)),
          ),
        ]))),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool mono, isLast, bold;
  final Color? valColor;
  const _Row(this.label, this.value, {this.mono = false, this.isLast = false, this.bold = false, this.valColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: isLast ? BorderSide.none : const BorderSide(color: AppColors.hairline, width: 0.5))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
        Text(value, style: (mono ? AppTheme.mono : GoogleFonts.spaceGrotesk)(
          fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.w500, color: valColor ?? AppColors.text1)),
      ]),
    );
  }
}

// ── Order Success Screen ──────────────────────────────────────────────
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 90, 28, 44),
            child: Column(children: [
              // Success orb
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1A5FD49B)),
                alignment: Alignment.center,
                child: Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5FD49B), Color(0xFF3A9C70)]),
                    boxShadow: [BoxShadow(color: Color(0x995FD49B), blurRadius: 30, spreadRadius: -6)],
                  ),
                  child: const Icon(Icons.check, color: AppColors.bg0, size: 32),
                ),
              ),
              const SizedBox(height: 28),

              Text('Emir gerçekleşti.', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text1, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              Text('0.4321 BTC pozisyonun açıldı. Risk kuralları aktif.', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3)),
              const SizedBox(height: 22),

              // Receipt
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: const Color(0x07FFFFFF),
                  border: Border.all(color: AppColors.hairline, width: 0.5),
                  borderRadius: BorderRadius.circular(16)),
                child: const Column(children: [
                  _Row('İşlem ID', 'TX-2026-A8F2C1', mono: true),
                  _Row('Tarih', '16 May, 14:32', mono: true),
                  _Row('Yön', 'ALIŞ', valColor: AppColors.profit, bold: true),
                  _Row('Coin', '0.4321 BTC', mono: true),
                  _Row('Fiyat', '\$67,234.12', mono: true),
                  _Row('Toplam', '\$29,080.05', mono: true, isLast: true, bold: true),
                ]),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: AppColors.accentGradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x404D9FFF), blurRadius: 28, offset: Offset(0, 10))],
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text('Geçmişe Git', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0x0AFFFFFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.hairline, width: 0.5)),
                ),
                child: Text('Panele dön', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1)),
              )),
            ]),
          )),
        ],
      ),
    );
  }
}

// ── Stop-Loss Triggered Alert ─────────────────────────────────────────
void showStopLossTriggeredSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xF2141A3A), Color(0xFC080B1C)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: AppColors.hairlineStrong, width: 0.5)),
      ),
      child: Column(children: [
        Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 36, height: 4, decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(999)))),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 4, 22, 24), child: Column(children: [
          // Warning hero
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF5A07A), Color(0xFFF08080)]),
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: [BoxShadow(color: Color(0x1AF08080), spreadRadius: 6), BoxShadow(color: Color(0x66F08080), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -8)],
            ),
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 18),
            child: const Icon(Icons.warning_rounded, color: AppColors.bg0, size: 32),
          ),
          Text('STOP-LOSS TETİKLENDİ', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.loss, letterSpacing: 0.11)),
          const SizedBox(height: 6),
          Text('Pozisyon kapatıldı', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.text1, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Text('AVAX pozisyonun risk profilinde belirlenen stop seviyesine ulaştı ve otomatik olarak kapatıldı.', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3, height: 1.5)),
          const SizedBox(height: 18),

          // Position summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.lossSoft,
              border: Border.all(color: const Color(0x3DF08080), width: 0.5),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const CoinAvatar(symbol: 'AVAX', size: 36),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Avalanche', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text1)),
                const SizedBox(height: 2),
                Text('24.0 AVAX', style: AppTheme.mono(fontSize: 11, color: AppColors.text3)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('−\$152.40', style: AppTheme.mono(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.loss)),
                const SizedBox(height: 3),
                const DeltaPill(value: -6.20),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // Detail rows
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: const Color(0x07FFFFFF),
              border: Border.all(color: AppColors.hairline, width: 0.5),
              borderRadius: BorderRadius.circular(14)),
            child: const Column(children: [
              _Row('Giriş fiyatı', '\$33.10', mono: true),
              _Row('Stop fiyatı', '\$31.05', mono: true, valColor: AppColors.loss),
              _Row('Tetikleme saati', '14:31:08', mono: true),
              _Row('Risk kullanımı', '%2.0 / %2.0', isLast: true),
            ]),
          ),
          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: AppColors.accentGradient),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x404D9FFF), blurRadius: 28, offset: Offset(0, 10))],
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('Detayları Gör', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0x0AFFFFFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.hairline, width: 0.5)),
            ),
            child: Text('Tamam', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text1)),
          )),
        ]))),
      ]),
    ),
  );
}
