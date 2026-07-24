// lib/screens/portfolio_breakdown_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/asset.dart';
import '../providers/app_providers.dart';
import '../providers/api_keys_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/delta_pill.dart';

// ── Renk paleti ──────────────────────────────────────────────────────────
const _kColors = [
  Color(0xFFF7A13A),
  Color(0xFF8B9EFF),
  Color(0xFFB692FF),
  Color(0xFF4D9FFF),
  Color(0xFFF08080),
  Color(0xFF5FD49B),
  Color(0xFFFFD166),
  Color(0xFF06D6A0),
];

// ── Provider ────────────────────────────────────────────────────────────
/// GET /api/v1/portfolio/breakdown?exchangeKeyId=
/// Exchange key yoksa boş liste döner.
final breakdownProvider = FutureProvider<List<AssetAllocation>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final keys = ref.watch(apiKeysProvider).valueOrNull ?? [];

  if (keys.isEmpty) return [];

  try {
    return await apiService.getPortfolioBreakdown(keys.first.id);
  } catch (_) {
    return [];
  }
});

// ── Screen ───────────────────────────────────────────────────────────────
class PortfolioBreakdownScreen extends ConsumerWidget {
  const PortfolioBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(breakdownProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: AppColors.text2, size: 18)),
                    const SizedBox(width: 8),
                    Text('Cüzdan',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12, color: AppColors.text3)),
                  ]),
                  const SizedBox(height: 18),
                  Text('PORTFÖY DAĞILIMI',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.11,
                          color: AppColors.text3)),
                  const SizedBox(height: 4),
                  Text('Risk Analizi',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: AppColors.text1)),
                  const SizedBox(height: 24),

                  // ── İçerik ─────────────────────────────────────────
                  breakdownAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: AppColors.accent),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text('Veri alınamadı: $e',
                            style: const TextStyle(color: AppColors.loss)),
                      ),
                    ),
                    data: (allocations) {
                      if (allocations.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      final totalUsd = allocations.fold(
                          0.0, (s, a) => s + a.usdValue);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Donut Chart
                          Center(
                            child: _DonutChart(
                                data: allocations,
                                total: totalUsd,
                                size: 170),
                          ),
                          const SizedBox(height: 24),

                          // Metrics
                          Container(
                            decoration: BoxDecoration(
                                color: const Color(0x07FFFFFF),
                                border: Border.all(
                                    color: AppColors.hairline, width: 0.5),
                                borderRadius: BorderRadius.circular(14)),
                            child: Row(children: [
                              Expanded(
                                  child: _Stat(
                                      label: 'Yoğunlaşma',
                                      value: _concentration(allocations),
                                      color: _concentrationColor(allocations))),
                              Container(
                                  width: 0.5,
                                  height: 40,
                                  color: AppColors.hairline),
                              Expanded(
                                  child: _Stat(
                                      label: 'Varlık Sayısı',
                                      value: '${allocations.length}',
                                      color: AppColors.profit)),
                              Container(
                                  width: 0.5,
                                  height: 40,
                                  color: AppColors.hairline),
                              Expanded(
                                  child: _Stat(
                                      label: 'Toplam USD',
                                      value: Formatters.moneyCompact(totalUsd))),
                            ]),
                          ),
                          const SizedBox(height: 24),

                          // Legend list
                          Text('VARLIK DAĞILIMI',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.11,
                                  color: AppColors.text3)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                                color: const Color(0x07FFFFFF),
                                border: Border.all(
                                    color: AppColors.hairline, width: 0.5),
                                borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              children: allocations.asMap().entries.map((e) {
                                final idx = e.key;
                                final a = e.value;
                                final color = _kColors[idx % _kColors.length];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                      border: Border(
                                          top: idx > 0
                                              ? const BorderSide(
                                                  color: AppColors.hairline,
                                                  width: 0.5)
                                              : BorderSide.none)),
                                  child: Row(children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            color: color,
                                            borderRadius:
                                                BorderRadius.circular(2))),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(a.symbol,
                                            style: GoogleFonts.spaceGrotesk(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.text1))),
                                    Text(
                                        '\$${Formatters.money(a.usdValue, decimals: 0)}',
                                        style: AppTheme.mono(
                                            fontSize: 12,
                                            color: AppColors.text3)),
                                    const SizedBox(width: 14),
                                    SizedBox(
                                        width: 44,
                                        child: Text(
                                            '%${a.allocationPct.toStringAsFixed(1)}',
                                            textAlign: TextAlign.right,
                                            style: AppTheme.mono(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.text1))),
                                  ]),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Insight card
                          _buildInsightCard(allocations),
                          const SizedBox(height: 44),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: AppColors.text3, size: 48),
          const SizedBox(height: 12),
          Text('Portföy verisi yok',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2)),
          const SizedBox(height: 6),
          Text('Exchange API anahtarı ekleyerek başlayın.',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 12, color: AppColors.text3)),
        ]),
      ),
    );
  }

  Widget _buildInsightCard(List<AssetAllocation> allocations) {
    if (allocations.isEmpty) return const SizedBox.shrink();
    final top = allocations.reduce(
        (a, b) => a.allocationPct > b.allocationPct ? a : b);
    final isConcentrated = top.allocationPct > 40;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0x144D9FFF), Color(0x0A7C5CFF)]),
          border: Border.all(color: AppColors.hairlineAccent, width: 0.5),
          borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
            padding: EdgeInsets.only(top: 2, right: 10),
            child: Icon(Icons.info_outline, color: AppColors.accent, size: 14)),
        Expanded(
            child: Text.rich(TextSpan(
          style: GoogleFonts.spaceGrotesk(
              fontSize: 11.5, color: AppColors.text2, height: 1.5),
          children: [
            TextSpan(
                text: '${top.symbol} payın %${top.allocationPct.toStringAsFixed(1)}',
                style: const TextStyle(
                    color: AppColors.text1, fontWeight: FontWeight.w500)),
            TextSpan(
                text: isConcentrated
                    ? ' — eşik %40. Daha dengeli portföy için diğer varlıklara bak.'
                    : ' — portföy dengeli görünüyor.'),
          ],
        ))),
      ]),
    );
  }

  String _concentration(List<AssetAllocation> a) {
    if (a.isEmpty) return '-';
    final top = a.map((x) => x.allocationPct).reduce((a, b) => a > b ? a : b);
    if (top > 60) return 'Yüksek';
    if (top > 40) return 'Orta';
    return 'Düşük';
  }

  Color _concentrationColor(List<AssetAllocation> a) {
    final c = _concentration(a);
    if (c == 'Yüksek') return AppColors.loss;
    if (c == 'Orta') return AppColors.warn;
    return AppColors.profit;
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 10, color: AppColors.text3)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color ?? AppColors.text1)),
        ]),
      );
}

class _DonutChart extends StatelessWidget {
  final List<AssetAllocation> data;
  final double total;
  final double size;
  const _DonutChart(
      {required this.data, required this.total, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          Transform.rotate(
              angle: -pi / 2,
              child: CustomPaint(
                  size: Size(size, size),
                  painter: _DonutPainter(data: data))),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('TOPLAM',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: AppColors.text3,
                    letterSpacing: 0.1)),
            const SizedBox(height: 2),
            Text('\$${Formatters.money(total, decimals: 0)}',
                style: AppTheme.mono(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5)),
          ]),
        ]));
  }
}

class _DonutPainter extends CustomPainter {
  final List<AssetAllocation> data;
  _DonutPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final r = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2), radius: r);
    canvas.drawCircle(
        rect.center,
        r,
        Paint()
          ..color = const Color(0x0AFFFFFF)
          ..strokeWidth = stroke
          ..style = PaintingStyle.stroke);

    double startAngle = 0;
    const gapAngle = 2.5 * pi / 180;
    for (var i = 0; i < data.length; i++) {
      final a = data[i];
      final sweepAngle = (a.allocationPct / 100) * 2 * pi;
      if (sweepAngle <= 0) continue;
      canvas.drawArc(
          rect,
          startAngle,
          sweepAngle - gapAngle,
          false,
          Paint()
            ..color = _kColors[i % _kColors.length]
            ..strokeWidth = stroke
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.butt);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
