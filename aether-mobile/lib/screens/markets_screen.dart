// lib/screens/markets_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/coin_avatar.dart';
import '../widgets/delta_pill.dart';
import '../widgets/sparkline_chart.dart';

class Market {
  final String sym, name, vol;
  final double price, change;
  final List<double> spark;
  final int rank;
  const Market({required this.sym, required this.name, required this.price,
    required this.change, required this.vol, required this.spark, required this.rank});
  bool get isUp => change >= 0;
}

const _kMarkets = [
  Market(sym:'BTC',  name:'Bitcoin',   price:67234.12, change:2.84,  vol:'38.2B', rank:1,  spark:[62,64,63,65,67,66,68,67,69,70,68,72]),
  Market(sym:'ETH',  name:'Ethereum',  price:3127.80,  change:1.92,  vol:'14.8B', rank:2,  spark:[28,27,29,30,28,31,30,32,31,33,32,34]),
  Market(sym:'SOL',  name:'Solana',    price:156.42,   change:4.21,  vol:'3.1B',  rank:5,  spark:[14,15,14,13,15,16,15,14,16,15,16,17]),
  Market(sym:'AVAX', name:'Avalanche', price:32.18,    change:-1.84, vol:'420M',  rank:9,  spark:[38,37,36,35,36,34,35,33,34,33,32,31]),
  Market(sym:'LINK', name:'Chainlink', price:16.34,    change:6.10,  vol:'388M',  rank:12, spark:[14,15,14,16,15,16,17,16,17,16,17,18]),
  Market(sym:'ADA',  name:'Cardano',   price:0.42,     change:-0.92, vol:'210M',  rank:11, spark:[44,43,42,43,42,41,42,41,42,41,42,41]),
  Market(sym:'DOT',  name:'Polkadot',  price:6.71,     change:3.10,  vol:'180M',  rank:14, spark:[62,63,62,64,65,64,66,65,67,66,68,69]),
  Market(sym:'MATIC',name:'Polygon',   price:0.83,     change:2.10,  vol:'92M',   rank:17, spark:[78,80,79,81,82,80,82,83,82,84,83,85]),
];

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});
  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  String _filter = 'all';
  String _search = '';
  final _searchCtrl = TextEditingController();

  List<Market> get _rows {
    var list = _kMarkets.where((m) {
      if (_search.isNotEmpty) {
        return m.sym.toLowerCase().contains(_search.toLowerCase()) ||
               m.name.toLowerCase().contains(_search.toLowerCase());
      }
      return true;
    }).toList();
    if (_filter == 'gainers') list = list.where((m) => m.isUp).toList();
    if (_filter == 'losers')  list = list.where((m) => !m.isUp).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Piyasalar', style: GoogleFonts.spaceGrotesk(
              fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: AppColors.text1)),
            const SizedBox(height: 14),
            // Search bar
            Container(
              decoration: BoxDecoration(color: const Color(0x0AFFFFFF),
                border: Border.all(color: AppColors.hairline, width: 0.5),
                borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Padding(padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search, color: AppColors.text3, size: 16)),
                Expanded(child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text1),
                  decoration: InputDecoration(
                    hintText: 'Coin ara...',
                    hintStyle: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3),
                    border: InputBorder.none, isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11)),
                )),
              ]),
            ),
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              for (final f in [
                ('all', 'Hepsi'), ('gainers', 'Yükselen'), ('losers', 'Düşen'), ('watch', 'İzleme'),
              ]) ...[
                GestureDetector(
                  onTap: () => setState(() => _filter = f.$1),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _filter == f.$1 ? AppColors.accentSoft : Colors.transparent,
                      border: Border.all(
                        color: _filter == f.$1 ? AppColors.hairlineAccent : AppColors.hairline, width: 0.5),
                      borderRadius: BorderRadius.circular(999)),
                    child: Text(f.$2, style: GoogleFonts.spaceGrotesk(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: _filter == f.$1 ? AppColors.accent : AppColors.text2)))),
                const SizedBox(width: 6),
              ],
            ])),
            const SizedBox(height: 4),
          ]),
        )),
        // Table header
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
          child: Row(children: [
            Expanded(child: Text('Coin', style: GoogleFonts.spaceGrotesk(
              fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.06, color: AppColors.text3))),
            Text('Fiyat / 24s', style: GoogleFonts.spaceGrotesk(
              fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.06, color: AppColors.text3)),
            const SizedBox(width: 48 + 22),
          ]),
        )),
        // List
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 44),
          sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
            final m = rows[i];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CoinDetailScreen(market: m))),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: i < rows.length - 1 ? AppColors.hairline : Colors.transparent, width: 0.5))),
                child: Row(children: [
                  // Rank
                  SizedBox(width: 24, child: Text('${m.rank}', style: AppTheme.mono(
                    fontSize: 10, color: AppColors.text4))),
                  CoinAvatar(symbol: m.sym, size: 32),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.sym, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1)),
                    Text(m.name, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, color: AppColors.text3)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('\$${m.price < 10 ? m.price.toStringAsFixed(3) : Formatters.price(m.price)}',
                      style: AppTheme.mono(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    DeltaPill(value: m.change),
                  ]),
                  const SizedBox(width: 10),
                  SparklineChart(points: m.spark.map((e) => e.toDouble()).toList(),
                    color: m.isUp ? AppColors.profit : AppColors.loss, width: 48, height: 22),
                ]),
              ),
            );
          }, childCount: rows.length)),
        ),
      ]),
    );
  }
}

// ── Coin Detail ─────────────────────────────────────────────────────────
class CoinDetailScreen extends StatefulWidget {
  final Market market;
  const CoinDetailScreen({super.key, required this.market});
  @override
  State<CoinDetailScreen> createState() => _CoinDetailState();
}

class _CoinDetailState extends State<CoinDetailScreen> {
  int _rangeIdx = 1;
  final _ranges = ['1S', '24S', '1H', '1A', '1Y', 'Max'];

  @override
  Widget build(BuildContext context) {
    final m = widget.market;
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top nav
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new, color: AppColors.text2, size: 18)),
              const SizedBox(width: 8),
              Text('Piyasalar', style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
              const Spacer(),
              _IconBtn(icon: Icons.star_border_rounded, onTap: () {}),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.notifications_outlined, onTap: () {}),
            ]),
            const SizedBox(height: 18),
            // Header
            Row(children: [
              CoinAvatar(symbol: m.sym, size: 46),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(m.name, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text1)),
                  const SizedBox(width: 8),
                  Text('${m.sym} · #${m.rank}', style: AppTheme.mono(fontSize: 11, color: AppColors.text3)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('\$${Formatters.price(m.price)}', style: AppTheme.mono(fontSize: 26, fontWeight: FontWeight.w500, letterSpacing: -0.5)),
                  const SizedBox(width: 8),
                  DeltaPill(value: m.change),
                ]),
              ])),
            ]),
            const SizedBox(height: 14),
            // Chart
            Container(height: 140, child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _AreaChartPainter(points: m.spark.map((e) => e.toDouble()).toList(), color: AppColors.accent),
            )),
            const SizedBox(height: 12),
            // Time range
            Row(children: List.generate(_ranges.length, (i) => Expanded(child: GestureDetector(
              onTap: () => setState(() => _rangeIdx = i),
              child: AnimatedContainer(duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _rangeIdx == i ? AppColors.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(7)),
                child: Text(_ranges[i], textAlign: TextAlign.center,
                  style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w600,
                    color: _rangeIdx == i ? AppColors.accent : AppColors.text3,
                    letterSpacing: 0.02))),
            )))),
            // Stats
            const SizedBox(height: 20),
            Text('İSTATİSTİKLER', style: GoogleFonts.spaceGrotesk(
              fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.11, color: AppColors.text3)),
            const SizedBox(height: 8),
            Container(decoration: BoxDecoration(color: const Color(0x07FFFFFF),
              border: Border.all(color: AppColors.hairline, width: 0.5),
              borderRadius: BorderRadius.circular(14)), child: Column(children: [
              _StatRow(label: 'Piyasa Değeri', value: '\$1.32T', borderTop: false, borderLeft: false),
              _StatRow(label: '24s Hacim', value: '\$${m.vol}', borderTop: false, borderLeft: true),
              _StatRow(label: 'Dolaşımda', value: '19.6M BTC', borderTop: true, borderLeft: false),
              _StatRow(label: 'ATH', value: '\$73,748', borderTop: true, borderLeft: true),
            ])),
            const SizedBox(height: 22),
            // CTAs
            Row(children: [
              Expanded(child: _TradeBtn(label: 'Al', color: AppColors.profit)),
              const SizedBox(width: 10),
              Expanded(child: _TradeBtn(label: 'Sat', color: AppColors.loss)),
            ]),
            const SizedBox(height: 44),
          ]),
        )),
      ]),
    );
  }
}

// ── Small helpers ───────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    width: 32, height: 32, decoration: BoxDecoration(
      color: const Color(0x0AFFFFFF),
      border: Border.all(color: AppColors.hairline, width: 0.5),
      borderRadius: BorderRadius.circular(9)),
    child: Icon(icon, color: AppColors.text2, size: 15)));
}

class _StatRow extends StatelessWidget {
  final String label, value;
  final bool borderTop, borderLeft;
  const _StatRow({required this.label, required this.value, required this.borderTop, required this.borderLeft});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(border: Border(
      top: borderTop ? const BorderSide(color: AppColors.hairline, width: 0.5) : BorderSide.none,
      left: borderLeft ? const BorderSide(color: AppColors.hairline, width: 0.5) : BorderSide.none)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.text3, letterSpacing: 0.04)),
      const SizedBox(height: 4),
      Text(value, style: AppTheme.mono(fontSize: 13, fontWeight: FontWeight.w500)),
    ]));
}

class _TradeBtn extends StatelessWidget {
  final String label;
  final Color color;
  const _TradeBtn({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {},
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
        borderRadius: BorderRadius.circular(14)),
      child: Text(label, textAlign: TextAlign.center,
        style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: color))));
}

// ── Area chart painter ──────────────────────────────────────────────────
class _AreaChartPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  const _AreaChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs().clamp(0.001, double.infinity);
    final w = size.width, h = size.height;

    List<Offset> pts = List.generate(points.length, (i) {
      final x = (i / (points.length - 1)) * w;
      final y = h - ((points[i] - min) / range) * (h - 8) - 4;
      return Offset(x, y);
    });

    final linePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var p in pts.skip(1)) linePath.lineTo(p.dx, p.dy);

    final areaPath = Path.from(linePath)
      ..lineTo(w, h)..lineTo(0, h)..close();

    canvas.drawPath(areaPath, Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)])
          .createShader(Rect.fromLTWH(0, 0, w, h)));

    canvas.drawPath(linePath, Paint()
      ..color = color..strokeWidth = 1.8..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    // Current price dot
    final last = pts.last;
    canvas.drawCircle(last, 7, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawCircle(last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
