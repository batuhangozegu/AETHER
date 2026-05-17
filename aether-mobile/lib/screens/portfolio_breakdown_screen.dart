// lib/screens/portfolio_breakdown_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/delta_pill.dart';

class _Allocation {
  final String sym;
  final double pct;
  final Color color;
  final double usd;
  const _Allocation(this.sym, this.pct, this.color, this.usd);
}

const _kAllocation = [
  _Allocation('BTC', 38.5, Color(0xFFF7A13A), 32445),
  _Allocation('ETH', 23.7, Color(0xFF8B9EFF), 19972),
  _Allocation('SOL', 12.2, Color(0xFFB692FF), 10282),
  _Allocation('LINK', 8.6, Color(0xFF4D9FFF), 7247),
  _Allocation('AVAX', 4.7, Color(0xFFF08080), 3960),
  _Allocation('Nakit', 12.3, Color(0xFF5FD49B), 10367),
];

class PortfolioBreakdownScreen extends StatelessWidget {
  const PortfolioBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new, color: AppColors.text2, size: 18)),
                const SizedBox(width: 8),
                Text('Cüzdan', style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
              ]),
              const SizedBox(height: 18),
              Text('PORTFÖY DAĞILIMI', style: GoogleFonts.spaceGrotesk(
                fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.11, color: AppColors.text3)),
              const SizedBox(height: 4),
              Text('Risk Analizi', style: GoogleFonts.spaceGrotesk(
                fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: AppColors.text1)),
              const SizedBox(height: 24),
              
              // Donut Chart
              Center(child: _DonutChart(data: _kAllocation, size: 170)),
              const SizedBox(height: 24),

              // Concentration metric
              Container(
                decoration: BoxDecoration(color: const Color(0x07FFFFFF),
                  border: Border.all(color: AppColors.hairline, width: 0.5),
                  borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Expanded(child: _Stat(label: 'Yoğunlaşma', value: 'Orta', color: AppColors.warn)),
                  Container(width: 0.5, height: 40, color: AppColors.hairline),
                  Expanded(child: _Stat(label: 'Volatilite', value: 'Düşük', color: AppColors.profit)),
                  Container(width: 0.5, height: 40, color: AppColors.hairline),
                  const Expanded(child: _Stat(label: 'Korelasyon', value: '0.72')),
                ]),
              ),
              const SizedBox(height: 24),

              // Legend List
              Text('VARLIK DAĞILIMI', style: GoogleFonts.spaceGrotesk(
                fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.11, color: AppColors.text3)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: const Color(0x07FFFFFF),
                  border: Border.all(color: AppColors.hairline, width: 0.5),
                  borderRadius: BorderRadius.circular(14)),
                child: Column(children: _kAllocation.asMap().entries.map((e) {
                  final a = e.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(border: Border(
                      top: e.key > 0 ? const BorderSide(color: AppColors.hairline, width: 0.5) : BorderSide.none)),
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: a.color, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(a.sym, style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.text1))),
                      Text('\$${Formatters.money(a.usd, decimals: 0)}', style: AppTheme.mono(fontSize: 12, color: AppColors.text3)),
                      const SizedBox(width: 14),
                      SizedBox(width: 44, child: Text('%${a.pct.toStringAsFixed(1)}',
                        textAlign: TextAlign.right, style: AppTheme.mono(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.text1))),
                    ]),
                  );
                }).toList()),
              ),
              const SizedBox(height: 18),

              // Insight Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0x144D9FFF), Color(0x0A7C5CFF)]),
                  border: Border.all(color: AppColors.hairlineAccent, width: 0.5),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(top: 2, right: 10),
                    child: Icon(Icons.info_outline, color: AppColors.accent, size: 14)),
                  Expanded(child: Text.rich(TextSpan(
                    style: GoogleFonts.spaceGrotesk(fontSize: 11.5, color: AppColors.text2, height: 1.5),
                    children: const [
                      TextSpan(text: 'BTC payın %38.5', style: TextStyle(color: AppColors.text1, fontWeight: FontWeight.w500)),
                      TextSpan(text: ' — eşik %40. Daha dengeli portföy için '),
                      TextSpan(text: 'ETH veya stablecoin', style: TextStyle(color: AppColors.accent)),
                      TextSpan(text: ' ekle.'),
                    ],
                  ))),
                ]),
              ),
              const SizedBox(height: 44),
            ]),
          )),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.text3)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: color ?? AppColors.text1)),
      ]),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final List<_Allocation> data;
  final double size;
  const _DonutChart({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    final total = data.fold(0.0, (s, a) => s + a.usd);
    return SizedBox(width: size, height: size, child: Stack(alignment: Alignment.center, children: [
      Transform.rotate(angle: -pi / 2, child: CustomPaint(
        size: Size(size, size), painter: _DonutPainter(data: data),
      )),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text('TOPLAM', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.text3, letterSpacing: 0.1)),
        const SizedBox(height: 2),
        Text('\$${Formatters.money(total, decimals: 0)}', style: AppTheme.mono(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const DeltaPill(value: 2.23),
      ]),
    ]));
  }
}

class _DonutPainter extends CustomPainter {
  final List<_Allocation> data;
  _DonutPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 22.0;
    final r = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: r);
    final bgPaint = Paint()..color = const Color(0x0AFFFFFF)..strokeWidth = stroke..style = PaintingStyle.stroke;
    canvas.drawCircle(rect.center, r, bgPaint);

    double startAngle = 0;
    final gapAngle = 2.5 * pi / 180;

    for (final a in data) {
      final sweepAngle = (a.pct / 100) * 2 * pi;
      if (sweepAngle <= 0) continue;
      final paint = Paint()..color = a.color..strokeWidth = stroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle - gapAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
