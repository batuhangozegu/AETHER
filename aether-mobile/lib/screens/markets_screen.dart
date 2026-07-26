// lib/screens/markets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';
import '../providers/api_keys_provider.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/coin_avatar.dart';
import '../widgets/delta_pill.dart';
import '../widgets/sparkline_chart.dart';
import 'trade_screen.dart';

/// Coin sembolünden deterministik ama görsel olarak farklı sparkline üretir.
List<double> _sparklineFor(String symbol, double price, bool isUp) {
  // symbol karakterlerinin ASCII toplamını seed olarak kullan
  final seed = symbol.codeUnits.fold(0, (a, b) => a + b);
  // 7 adımlık faktör serisi — her coin için benzersiz bir desen
  final offsets = List.generate(7, (i) {
    final v = ((seed * (i + 3)) % 17) / 100.0; // 0..0.17 aralığı
    return (i % 2 == 0) ? -v : v;
  });
  // Son değeri gerçek fiyat yap, diğerlerini ona göre hesapla
  final result = <double>[];
  double cur = price * (isUp ? 0.94 : 1.06);
  for (final off in offsets) {
    cur = cur + price * off;
    result.add(cur);
  }
  result.add(price); // son nokta her zaman gerçek fiyat
  return result;
}

// ── Static coin metadata (name + rank) ──────────────────────────────────
const _kCoinMeta = {
  'BTC':  {'name': 'Bitcoin',   'rank': 1},
  'ETH':  {'name': 'Ethereum',  'rank': 2},
  'SOL':  {'name': 'Solana',    'rank': 5},
  'AVAX': {'name': 'Avalanche', 'rank': 9},
  'LINK': {'name': 'Chainlink', 'rank': 12},
  'ADA':  {'name': 'Cardano',   'rank': 11},
  'DOT':  {'name': 'Polkadot',  'rank': 14},
  'MATIC':{'name': 'Polygon',   'rank': 17},
};

// ── Provider ────────────────────────────────────────────────────────────
final marketCoinsProvider = FutureProvider<List<CoinData>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final keys = ref.watch(apiKeysProvider).valueOrNull ?? [];
  if (keys.isEmpty) return [];
  try {
    return await apiService.getMarketCoins(keys.first.id);
  } catch (_) {
    return [];
  }
});

class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});
  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen> {
  String _filter = 'all';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CoinData> _filtered(List<CoinData> coins) {
    var list = coins.where((m) {
      if (_search.isNotEmpty) {
        return m.symbol.toLowerCase().contains(_search.toLowerCase());
      }
      return true;
    }).toList();
    if (_filter == 'gainers') list = list.where((m) => m.isUp).toList();
    if (_filter == 'losers') list = list.where((m) => !m.isUp).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final coinsAsync = ref.watch(marketCoinsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Piyasalar', style: GoogleFonts.spaceGrotesk(
                  fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: AppColors.text1)),
                GestureDetector(
                  onTap: () => ref.invalidate(marketCoinsProvider),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.hairline, width: 0.5),
                    ),
                    child: const Icon(Icons.refresh_rounded, color: AppColors.text2, size: 16),
                  ),
                ),
              ],
            ),
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
                ('all', 'Hepsi'), ('gainers', 'Yükselen'), ('losers', 'Düşen'),
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
        coinsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.accent),
            )),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Center(child: Text(
                'Piyasa verisi yüklenemedi.\nExchange API anahtarı ekleyin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3),
              )),
            ),
          ),
          data: (coins) {
            if (coins.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.bar_chart_rounded, color: AppColors.text3, size: 40),
                    const SizedBox(height: 10),
                    Text('Piyasa verisi yok', style: GoogleFonts.spaceGrotesk(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text2)),
                    const SizedBox(height: 4),
                    Text('Exchange API anahtarı ekleyerek başlayın.',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
                  ])),
                ),
              );
            }
            final rows = _filtered(coins);
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 44),
              sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                final m = rows[i];
                final meta = _kCoinMeta[m.symbol];
                final name = meta?['name'] as String? ?? m.symbol;
                final rank = meta?['rank'] as int? ?? 0;
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CoinDetailScreen(coin: m, name: name, rank: rank))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(
                        color: i < rows.length - 1 ? AppColors.hairline : Colors.transparent, width: 0.5))),
                    child: Row(children: [
                      SizedBox(width: 24, child: Text(rank > 0 ? '$rank' : '-',
                        style: AppTheme.mono(fontSize: 10, color: AppColors.text4))),
                      CoinAvatar(symbol: m.symbol, size: 32),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.symbol, style: GoogleFonts.spaceGrotesk(
                          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1)),
                        Text(name, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, color: AppColors.text3)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('\$${m.price < 10 ? m.price.toStringAsFixed(3) : Formatters.price(m.price)}',
                          style: AppTheme.mono(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        DeltaPill(value: m.priceChangePercent),
                      ]),
                      const SizedBox(width: 10),
                      SparklineChart(
                        points: _sparklineFor(m.symbol, m.price, m.isUp),
                        color: m.isUp ? AppColors.profit : AppColors.loss,
                        width: 48, height: 22),
                    ]),
                  ),
                );
              }, childCount: rows.length)),
            );
          },
        ),
      ]),
    );
  }
}

// ── Coin Detail ─────────────────────────────────────────────────────────
class CoinDetailScreen extends ConsumerStatefulWidget {
  final CoinData coin;
  final String name;
  final int rank;
  const CoinDetailScreen({super.key, required this.coin, required this.name, required this.rank});
  @override
  ConsumerState<CoinDetailScreen> createState() => _CoinDetailState();
}

class _CoinDetailState extends ConsumerState<CoinDetailScreen> {
  int _rangeIdx = 1;
  final _ranges = ['1m', '5m', '15m', '1h', '4h', '1d'];
  final _rangeLabels = ['1D', '5D', '15D', '1S', '4S', '1G'];

  @override
  Widget build(BuildContext context) {
    final m = widget.coin;
    final keys = ref.watch(apiKeysProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top nav
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, color: AppColors.text2, size: 18)),
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
              CoinAvatar(symbol: m.symbol, size: 46),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(widget.name, style: GoogleFonts.spaceGrotesk(
                    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text1)),
                  const SizedBox(width: 8),
                  Text('${m.symbol}${widget.rank > 0 ? ' · #${widget.rank}' : ''}',
                    style: AppTheme.mono(fontSize: 11, color: AppColors.text3)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('\$${Formatters.price(m.price)}',
                    style: AppTheme.mono(fontSize: 26, fontWeight: FontWeight.w500, letterSpacing: -0.5)),
                  const SizedBox(width: 8),
                  DeltaPill(value: m.priceChangePercent),
                ]),
              ])),
            ]),
            const SizedBox(height: 14),
            // Mini price chart (static sparkline while candle data loads)
            Container(height: 140, child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _AreaChartPainter(
                points: [m.price * 0.94, m.price * 0.96, m.price * 0.95, m.price * 0.97,
                         m.price * 0.98, m.price * 0.97, m.price * 0.99, m.price],
                color: AppColors.accent),
            )),
            const SizedBox(height: 12),
            // Time range
            Row(children: List.generate(_rangeLabels.length, (i) => Expanded(child: GestureDetector(
              onTap: () => setState(() => _rangeIdx = i),
              child: AnimatedContainer(duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _rangeIdx == i ? AppColors.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(7)),
                child: Text(_rangeLabels[i], textAlign: TextAlign.center,
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
              _StatRow(label: '24s Değişim', value: '${m.priceChangePercent >= 0 ? '+' : ''}${m.priceChangePercent.toStringAsFixed(2)}%', borderTop: false, borderLeft: false),
              _StatRow(label: 'Güncel Fiyat', value: '\$${Formatters.price(m.price)}', borderTop: false, borderLeft: true),
            ])),
            const SizedBox(height: 22),
            // CTAs — navigate to Trade screen with coin pre-selected
            Row(children: [
              Expanded(child: _TradeBtn(label: 'Al', color: AppColors.profit,
                  symbol: m.symbol,
                  onTap: () {
                    // supported symbols in trade screen
                    const supported = {'BTC', 'ETH', 'SOL', 'BNB', 'ADA'};
                    if (supported.contains(m.symbol)) {
                      ref.read(tradeFormProvider.notifier).setCoin(m.symbol);
                    }
                    ref.read(tradeFormProvider.notifier).setSide(TradeSide.buy);
                    ref.read(navIndexProvider.notifier).state = 1;
                    Navigator.pop(context);
                  })),
              const SizedBox(width: 10),
              Expanded(child: _TradeBtn(label: 'Sat', color: AppColors.loss,
                  symbol: m.symbol,
                  onTap: () {
                    const supported = {'BTC', 'ETH', 'SOL', 'BNB', 'ADA'};
                    if (supported.contains(m.symbol)) {
                      ref.read(tradeFormProvider.notifier).setCoin(m.symbol);
                    }
                    ref.read(tradeFormProvider.notifier).setSide(TradeSide.sell);
                    ref.read(navIndexProvider.notifier).state = 1;
                    Navigator.pop(context);
                  })),
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
  final String symbol;
  final VoidCallback onTap;
  const _TradeBtn({required this.label, required this.color, required this.symbol, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
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

    final last = pts.last;
    canvas.drawCircle(last, 7, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawCircle(last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
