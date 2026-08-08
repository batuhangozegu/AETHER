// lib/screens/markets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';
import '../providers/api_keys_provider.dart';
import '../providers/app_providers.dart';
import '../providers/live_prices_provider.dart';
import '../providers/market_providers.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/coin_avatar.dart';
import '../widgets/delta_pill.dart';
import '../widgets/sparkline_chart.dart';
import 'trade_screen.dart';

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
// marketCoinsProvider artık lib/providers/market_providers.dart içinde —
// trade_screen.dart ile paylaşılabilmesi için oradan import ediliyor.

/// Backend candle history'sinden gerçek kapanış fiyatlarını döner.
/// Borsa bağlantısı yoksa veya istek başarısız olursa boş liste döner —
/// çağıran taraf bu durumda [_sparklineFallback]'e düşer.
final _candleCloseHistoryProvider = FutureProvider.family<List<double>,
    ({String exchangeKeyId, String symbol, String interval})>((ref, params) async {
  try {
    final api = ref.watch(apiServiceProvider);
    final candles =
        await api.getCandleHistory(params.exchangeKeyId, params.symbol, params.interval);
    return candles.map((c) => c.close).toList();
  } catch (_) {
    return [];
  }
});

// ── Favorites ───────────────────────────────────────────────────────────
class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  ApiService get _api => ref.read(apiServiceProvider);

  @override
  Future<Set<String>> build() async {
    try {
      return await _api.getFavorites();
    } catch (_) {
      return {};
    }
  }

  Future<void> toggle(String symbol) async {
    final current = state.valueOrNull ?? {};
    if (current.contains(symbol)) {
      await _api.removeFavorite(symbol);
      state = AsyncData({...current}..remove(symbol));
    } else {
      await _api.addFavorite(symbol);
      state = AsyncData({...current, symbol});
    }
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

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
            final keys = ref.watch(apiKeysProvider).valueOrNull ?? [];
            final livePrices = ref.watch(livePricesProvider);
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 44),
              sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                final m = rows[i];
                final displayPrice = livePrices[m.symbol] ?? m.price;
                final meta = _kCoinMeta[m.symbol];
                final name = meta?['name'] as String? ?? m.symbol;
                final rank = meta?['rank'] as int? ?? 0;
                final sparkPoints = keys.isEmpty
                    ? null
                    : ref
                        .watch(_candleCloseHistoryProvider((
                          exchangeKeyId: keys.first.id,
                          symbol: '${m.symbol}USDT',
                          interval: '1h',
                        )))
                        .valueOrNull;
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
                        Text('\$${displayPrice < 10 ? displayPrice.toStringAsFixed(3) : Formatters.price(displayPrice)}',
                          style: AppTheme.mono(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        DeltaPill(value: m.priceChangePercent),
                      ]),
                      const SizedBox(width: 10),
                      (sparkPoints != null && sparkPoints.isNotEmpty)
                          ? SparklineChart(
                              points: sparkPoints,
                              color: m.isUp ? AppColors.profit : AppColors.loss,
                              width: 48, height: 22)
                          : const SizedBox(
                              width: 48, height: 22,
                              child: Center(
                                child: SizedBox(
                                  width: 12, height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.6, color: AppColors.text3),
                                ),
                              ),
                            ),
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
  // 'Dk' = dakika (önceden 'D' idi, "gün" ile karışabiliyordu).
  final _rangeLabels = ['1Dk', '5Dk', '15Dk', '1S', '4S', '1G'];

  @override
  Widget build(BuildContext context) {
    final m = widget.coin;
    final keys = ref.watch(apiKeysProvider).valueOrNull ?? [];
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? {};
    final isFavorite = favorites.contains(m.symbol);
    final livePrice = ref.watch(livePricesProvider)[m.symbol] ?? m.price;
    final candlePoints = keys.isEmpty
        ? null
        : ref
            .watch(_candleCloseHistoryProvider((
              exchangeKeyId: keys.first.id,
              symbol: '${m.symbol}USDT',
              interval: _ranges[_rangeIdx],
            )))
            .valueOrNull;

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
              _IconBtn(
                icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFavorite ? const Color(0xFFF5B969) : AppColors.text2,
                onTap: () => ref.read(favoritesProvider.notifier).toggle(m.symbol),
              ),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.notifications_outlined, onTap: () => _showCreateAlarmSheet(context, ref, m.symbol, livePrice)),
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
                  Text('\$${Formatters.price(livePrice)}',
                    style: AppTheme.mono(fontSize: 26, fontWeight: FontWeight.w500, letterSpacing: -0.5)),
                  const SizedBox(width: 8),
                  DeltaPill(value: m.priceChangePercent),
                ]),
              ])),
            ]),
            const SizedBox(height: 14),
            // Mini price chart — gerçek mum verisi (candlePoints) gelene
            // kadar sahte veri değil, spinner gösterilir.
            Container(
              height: 140,
              child: (candlePoints != null && candlePoints.isNotEmpty)
                  ? CustomPaint(
                      size: const Size(double.infinity, 140),
                      painter: _AreaChartPainter(
                          points: candlePoints, color: AppColors.accent),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: AppColors.accent)),
            ),
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
              _StatRow(label: 'Güncel Fiyat', value: '\$${Formatters.price(livePrice)}', borderTop: false, borderLeft: true),
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
  final Color? color;
  const _IconBtn({required this.icon, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    width: 32, height: 32, decoration: BoxDecoration(
      color: const Color(0x0AFFFFFF),
      border: Border.all(color: AppColors.hairline, width: 0.5),
      borderRadius: BorderRadius.circular(9)),
    child: Icon(icon, color: color ?? AppColors.text2, size: 15)));
}

/// Fiyat alarmı oluşturma bottom sheet'i — backend'e POST /api/v1/alarms atar.
void _showCreateAlarmSheet(BuildContext context, WidgetRef ref, String symbol, double currentPrice) {
  final priceCtrl = TextEditingController(text: currentPrice.toStringAsFixed(2));
  String direction = 'ABOVE';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111828),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$symbol için Fiyat Alarmı', style: GoogleFonts.spaceGrotesk(
            fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text1)),
        const SizedBox(height: 6),
        Text('Hedef fiyata ulaşıldığında bildirim alırsın.',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() => direction = 'ABOVE'),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 10), alignment: Alignment.center,
              decoration: BoxDecoration(
                color: direction == 'ABOVE' ? AppColors.profitSoft : AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: direction == 'ABOVE' ? AppColors.profit : AppColors.hairline, width: 0.5)),
              child: Text('Üzerine çıkınca', style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w600,
                color: direction == 'ABOVE' ? AppColors.profit : AppColors.text2))))),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(
            onTap: () => setState(() => direction = 'BELOW'),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 10), alignment: Alignment.center,
              decoration: BoxDecoration(
                color: direction == 'BELOW' ? AppColors.lossSoft : AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: direction == 'BELOW' ? AppColors.loss : AppColors.hairline, width: 0.5)),
              child: Text('Altına düşünce', style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w600,
                color: direction == 'BELOW' ? AppColors.loss : AppColors.text2))))),
        ]),
        const SizedBox(height: 14),
        Text('Hedef Fiyat', style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
        const SizedBox(height: 6),
        TextField(
          controller: priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTheme.mono(fontSize: 16),
          decoration: InputDecoration(
            prefixText: '\$ ',
            filled: true, fillColor: AppColors.surface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.hairline, width: 0.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.hairline, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: () async {
            final target = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
            if (target == null) return;
            try {
              await ref.read(apiServiceProvider).createAlarm(symbol: symbol, targetPrice: target, direction: direction);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fiyat alarmı oluşturuldu')));
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Alarm oluşturulamadı: $e'), backgroundColor: AppColors.loss));
              }
            }
          },
          child: Text('Alarm Oluştur', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        )),
      ]),
    )),
  );
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
