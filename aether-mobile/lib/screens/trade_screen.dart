// lib/screens/trade_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../models/market.dart';
import '../models/order.dart';
import '../providers/api_keys_provider.dart';
import '../providers/app_providers.dart';
import '../providers/trade_provider.dart';
import '../providers/live_prices_provider.dart';
import '../providers/market_providers.dart';
import 'dashboard_screen.dart' show realPortfolioProvider;
import 'history_screen.dart' show transactionsProvider;
import 'risk_screen.dart' show riskProvider;
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/coin_avatar.dart';
import '../widgets/delta_pill.dart';
import '../widgets/glass_card.dart';
import '../widgets/trade_dialogs.dart';

// ── Available coins for trading ────────────────────────────────────────
const _kTradeCoins = [
  _TradeCoin('BTC', 'Bitcoin',  'BTCUSDT'),
  _TradeCoin('ETH', 'Ethereum', 'ETHUSDT'),
  _TradeCoin('SOL', 'Solana',   'SOLUSDT'),
  _TradeCoin('BNB', 'BNB',      'BNBUSDT'),
  _TradeCoin('ADA', 'Cardano',  'ADAUSDT'),
];

class _TradeCoin {
  final String symbol, name, pair;
  const _TradeCoin(this.symbol, this.name, this.pair);
}

// ── Order types ────────────────────────────────────────────────────────
const _kOrderTypes = ['Limit', 'Market', 'Stop-Limit'];

// ── Per-coin placeholder prices ─────────────────────────────────────────
/// Sadece canlı WebSocket fiyatı (`livePricesProvider`) ve REST piyasa
/// verisi (`marketCoinsProvider`) henüz yüklenmemişken kısa süreliğine
/// gösterilen yer tutucu değerler — ilk veri gelir gelmez ekrandan kalkar.
const _kCoinBasePrices = {
  'BTC': 67234.12,
  'ETH': 3821.55,
  'SOL': 178.44,
  'BNB': 418.70,
  'ADA': 0.651,
};

// ── Providers ──────────────────────────────────────────────────────────

/// Selected chart time range — drives which candle interval is requested.
final timeRangeProvider = StateProvider<String>((_) => '24S');

const _kRangeToInterval = {
  '1Dk': '1m',  // dakikalık mum grafiği
  '24S': '15m',
  '1H': '4h',
  '1A': '1d',
  '1Y': '1w',
  'Max': '1M',
};

/// Coin'e göre fiyat geçmişi döndüren family provider — backend candle
/// history'sinden gerçek kapanış fiyatlarını çeker. Borsa bağlantısı yoksa,
/// istek başarısız olursa veya henüz veri gelmediyse boş liste döner —
/// çağıran taraf (`_buildChart`) bu durumda spinner gösterir, sahte veri
/// üretmez.
final priceHistoryProvider =
    FutureProvider.family<List<double>, String>((ref, symbol) async {
  final keys = ref.watch(apiKeysProvider).valueOrNull ?? [];
  if (keys.isEmpty) return [];

  final range = ref.watch(timeRangeProvider);
  final interval = _kRangeToInterval[range] ?? '15m';
  final coin = _kTradeCoins.firstWhere((c) => c.symbol == symbol,
      orElse: () => _kTradeCoins.first);

  try {
    final api = ref.watch(apiServiceProvider);
    final candles = await api.getCandleHistory(keys.first.id, coin.pair, interval);
    return candles.map((c) => c.close).toList();
  } catch (_) {
    return [];
  }
});

/// Fetches the real account balance from the backend via exchange key
final accountBalanceProvider = FutureProvider<double>((ref) async {
  final keys = ref.watch(apiKeysProvider).valueOrNull ?? [];
  if (keys.isEmpty) return 0.0;
  try {
    final api = ref.watch(apiServiceProvider);
    final portfolio = await api.getPortfolioSummary(keys.first.id);
    return portfolio.balance;
  } catch (_) {
    return 0.0;
  }
});

// ── State ──────────────────────────────────────────────────────
enum TradeSide { buy, sell }

class TradeFormState {
  final TradeSide side;
  final double entryPrice;
  final double stopLoss;
  final String? selectedKeyId; // exchangeKeyId for backend
  final double accountBalance; // fetched from real API
  final String selectedCoinIdx; // index into _kTradeCoins
  final String orderType;      // Limit / Market / Stop-Limit
  final double riskPercent;    // synced from the user's risk profile
  final double rrRatio;        // synced from the user's risk profile (1:R)
  final bool isFutures;        // false = Spot, true = Futures (kaldıraçlı)
  final int leverage;          // sadece isFutures true iken anlamlı (1-20x)

  const TradeFormState({
    this.side = TradeSide.buy,
    this.entryPrice = 67234.12,
    this.stopLoss = 65800.00,
    this.selectedKeyId,
    this.accountBalance = 0.0,
    this.selectedCoinIdx = 'BTC',
    this.orderType = 'Limit',
    this.riskPercent = 2.0,
    this.rrRatio = 2.5,
    this.isFutures = false,
    this.leverage = 1,
  });

  double get riskAmount => accountBalance * (riskPercent / 100);
  double get stopDistance => (entryPrice - stopLoss).abs();
  double get idealUnits => stopDistance > 0 ? riskAmount / stopDistance : 0;
  double get positionSize => idealUnits * entryPrice;
  double get positionPercent =>
      accountBalance > 0 ? (positionSize / accountBalance) * 100 : 0;
  /// Long'da (Al) hedef girişin üstünde, short'ta (Sat) altındadır.
  double get targetPrice => side == TradeSide.buy
      ? entryPrice + stopDistance * rrRatio
      : entryPrice - stopDistance * rrRatio;

  /// Stop mesafesinin girişe oranı — yön fark etmeksizin her zaman pozitif
  /// (mesafe), UI bunu zaten "-%X" olarak "risk" anlamında gösteriyor.
  double get stopPercent =>
      entryPrice > 0 ? (stopDistance / entryPrice) * 100 : 0;

  /// Kaba, izole-marj yaklaşık likidasyon fiyatı — sadece işlem açılmadan
  /// önceki önizleme amaçlıdır. Gerçek (kesin) likidasyon fiyatı emir
  /// gönderildikten sonra borsanın kendi pozisyon uç noktasından okunur ve
  /// `OrderModel.liquidationPrice` olarak gösterilir; borsanın bakım marjı
  /// kademeleri burada hesaba katılmıyor.
  double? get estimatedLiquidationPrice {
    if (!isFutures || leverage <= 1) return null;
    const maintenanceMarginRate = 0.005;
    final factor = (1 / leverage) - maintenanceMarginRate;
    return side == TradeSide.buy
        ? entryPrice * (1 - factor)
        : entryPrice * (1 + factor);
  }

  _TradeCoin get coin =>
      _kTradeCoins.firstWhere((c) => c.symbol == selectedCoinIdx,
          orElse: () => _kTradeCoins.first);

  TradeFormState copyWith({
    TradeSide? side,
    double? entryPrice,
    double? stopLoss,
    String? selectedKeyId,
    double? accountBalance,
    String? selectedCoinIdx,
    String? orderType,
    double? riskPercent,
    double? rrRatio,
    bool? isFutures,
    int? leverage,
  }) =>
      TradeFormState(
        side: side ?? this.side,
        entryPrice: entryPrice ?? this.entryPrice,
        stopLoss: stopLoss ?? this.stopLoss,
        selectedKeyId: selectedKeyId ?? this.selectedKeyId,
        accountBalance: accountBalance ?? this.accountBalance,
        selectedCoinIdx: selectedCoinIdx ?? this.selectedCoinIdx,
        orderType: orderType ?? this.orderType,
        riskPercent: riskPercent ?? this.riskPercent,
        rrRatio: rrRatio ?? this.rrRatio,
        isFutures: isFutures ?? this.isFutures,
        leverage: leverage ?? this.leverage,
      );
}

class TradeFormNotifier extends StateNotifier<TradeFormState> {
  TradeFormNotifier() : super(const TradeFormState());

  /// Al/Sat değişince stop-loss'u girişin doğru tarafına (long'da altına,
  /// short'ta üstüne) aynı risk mesafesini koruyarak taşır — aksi halde
  /// stop aynı fiyatta kalıp yön değişince anlamsızlaşıyordu.
  void setSide(TradeSide side) {
    final distance = state.stopDistance;
    final newStop = side == TradeSide.buy
        ? state.entryPrice - distance
        : state.entryPrice + distance;
    state = state.copyWith(side: side, stopLoss: newStop);
  }

  void setEntry(double v) => state = state.copyWith(entryPrice: v);
  void setStop(double v) => state = state.copyWith(stopLoss: v);
  void setKeyId(String id) => state = state.copyWith(selectedKeyId: id);
  void setBalance(double b) => state = state.copyWith(accountBalance: b);
  void setOrderType(String t) => state = state.copyWith(orderType: t);

  /// Spot/Futures geçişi. Spot'a dönülürken "Sat" (short) seçiliyse "Al"a
  /// zorlanır — spot piyasalarda açığa satış yoktur (backend de reddeder).
  void setIsFutures(bool futures) => state = state.copyWith(
        isFutures: futures,
        side: (!futures && state.side == TradeSide.sell) ? TradeSide.buy : state.side,
        leverage: futures ? state.leverage : 1,
      );

  void setLeverage(int lev) => state = state.copyWith(leverage: lev);

  /// Coin değişince hem symbol hem de giriş/stop-loss fiyatlarını günceller.
  /// [currentPrice] çağıran taraftan (canlı WS fiyatı ya da REST piyasa
  /// verisi) geçirilir; hiçbiri henüz yüklenmediyse `_kCoinBasePrices`
  /// yer tutucusuna düşülür. Stop-loss, mevcut yöne göre (Al'da girişin
  /// altına, Sat'ta üstüne) genel %2 mesafeyle varsayılan olarak konur —
  /// kullanıcı dilediği gibi değiştirebilir.
  void setCoin(String symbol, {double? currentPrice}) {
    final entry = currentPrice ?? _kCoinBasePrices[symbol] ?? state.entryPrice;
    final stop = state.side == TradeSide.buy ? entry * 0.98 : entry * 1.02;
    state = state.copyWith(
      selectedCoinIdx: symbol,
      entryPrice: entry,
      stopLoss: stop,
    );
  }
}

final tradeFormProvider = StateNotifierProvider<TradeFormNotifier, TradeFormState>(
  (_) => TradeFormNotifier(),
);

// ── Screen ─────────────────────────────────────────────────────────────
class TradeScreen extends ConsumerWidget {
  const TradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawState = ref.watch(tradeFormProvider);
    final notifier = ref.read(tradeFormProvider.notifier);
    // Always reflect the user's saved risk-per-trade % and reward:risk
    // ratio (falls back to the form's defaults until the risk profile
    // has loaded).
    final riskProfile = ref.watch(riskProvider);
    final state = rawState.copyWith(
      riskPercent: riskProfile.riskPerTrade,
      rrRatio: riskProfile.rrRatio,
    );
    final historyAsync = ref.watch(priceHistoryProvider(state.selectedCoinIdx));
    final keysAsync = ref.watch(apiKeysProvider);
    final activeOrdersAsync = ref.watch(tradeStateProvider);
    final balanceAsync = ref.watch(accountBalanceProvider);
    final livePrices = ref.watch(livePricesProvider);
    final marketCoins = ref.watch(marketCoinsProvider).valueOrNull ?? const [];

    // Sync real balance into form state when it loads
    ref.listen(accountBalanceProvider, (_, next) {
      if (next is AsyncData<double> && next.value > 0) {
        notifier.setBalance(next.value);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        children: [
          const Positioned(
            top: 0, left: 0, right: 0, height: 250,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.5, -0.8),
                  radius: 1.0,
                  colors: [Color(0x144D9FFF), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Text('İşlem',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13, color: AppColors.text3)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showOrderTypePicker(context, state, notifier),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.hairline, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.tune,
                                      size: 14, color: AppColors.text2),
                                  const SizedBox(width: 4),
                                  Text(state.orderType,
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.text2)),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.keyboard_arrow_down,
                                      size: 14, color: AppColors.text3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Coin selector
                      _CoinSelector(
                        selected: state.selectedCoinIdx,
                        onSelected: (symbol) {
                          double? marketPrice;
                          for (final c in marketCoins) {
                            if (c.symbol == symbol) {
                              marketPrice = c.price;
                              break;
                            }
                          }
                          notifier.setCoin(symbol,
                              currentPrice: livePrices[symbol] ?? marketPrice);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Coin price header — updates when coin changes
                      _CoinPriceHeader(coin: state.coin, entryPrice: state.entryPrice),
                      const SizedBox(height: 12),

                      // Chart
                      _buildChart(historyAsync),
                      const SizedBox(height: 12),

                      // Time range
                      _buildTimeRange(ref),
                      const SizedBox(height: 18),

                      // Exchange key selector
                      _ExchangeKeySelector(
                        keysAsync: keysAsync,
                        selectedId: state.selectedKeyId,
                        onSelected: notifier.setKeyId,
                      ),
                      const SizedBox(height: 14),

                      // Spot/Futures seçici
                      _buildMarketTypeToggle(state, notifier),
                      const SizedBox(height: 14),

                      // Kaldıraç slider — sadece Futures seçiliyken
                      if (state.isFutures) ...[
                        _buildLeverageSlider(state, notifier),
                        const SizedBox(height: 14),
                      ],

                      // Buy/Sell toggle
                      _buildSideToggle(state, notifier),
                      if (!state.isFutures) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Spot piyasalarda açığa satış (short) yapılamaz — short için Futures\'a geçin.',
                          style: GoogleFonts.spaceGrotesk(fontSize: 10.5, color: AppColors.text3),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Entry price input
                      // Key coin'e bağlı: TextFormField'ın initialValue'su
                      // sadece ilk oluşturulduğunda uygulanır — coin
                      // değişince field'ın gerçekten yeniden oluşmasını
                      // (ve yeni fiyatı göstermesini) sağlamak için key
                      // gerekiyor, aksi halde eski değer ekranda kalır.
                      _InputCard(
                        key: ValueKey('entry-${state.selectedCoinIdx}'),
                        label: 'Giriş Fiyatı',
                        value: state.entryPrice,
                        suffix: 'USD',
                        onChanged: notifier.setEntry,
                      ),
                      const SizedBox(height: 10),

                      // Stop loss input
                      // Key side'a da bağlı: Al/Sat değişince stop-loss
                      // state'te doğru güncelleniyor ama side coin'i
                      // değiştirmediği için sadece coin'e bağlı key bunu
                      // yakalamıyordu — field eski değeri göstermeye devam
                      // ediyordu.
                      _InputCard(
                        key: ValueKey('stop-${state.selectedCoinIdx}-${state.side}'),
                        label: 'Zarar Kes (Stop-Loss)',
                        value: state.stopLoss,
                        suffix: '-${state.stopPercent.toStringAsFixed(2)}%',
                        isLoss: true,
                        onChanged: notifier.setStop,
                      ),
                      const SizedBox(height: 14),

                      // Risk calculator
                      _buildRiskCard(state),
                      const SizedBox(height: 18),

                      // Confirm button
                      _buildConfirmButton(context, ref, state),
                      const SizedBox(height: 18),

                      // Active orders panel
                      _ActiveOrdersPanel(ordersAsync: activeOrdersAsync, ref: ref),
                      const SizedBox(height: 44),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(AsyncValue<List<double>> historyAsync) {
    return SizedBox(
      height: 120,
      child: historyAsync.when(
        data: (points) {
          if (points.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (points.length < 2) {
            // fl_chart tek noktayla (min==max) çöküyordu — özellikle "Max"
            // aralığında (1 aylık mumlar) borsadan çok az veri dönebiliyor.
            return Center(
              child: Text('Bu aralık için yeterli veri yok',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
            );
          }
          final maxY = points.reduce((a, b) => a > b ? a : b);
          final minY = points.reduce((a, b) => a < b ? a : b);
          final range = maxY - minY;
          final spots = points
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value))
              .toList();
          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                // range 0 olabilir (tüm mumlar aynı fiyatta) — bu durumda
                // fl_chart'a 0 interval geçmek çöküyordu.
                horizontalInterval: range > 0 ? range / 4 : 1,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: Color(0x0AFFFFFF),
                  strokeWidth: 1,
                  dashArray: [2, 4],
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.accent,
                  barWidth: 1.8,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, _) =>
                        spot.x == spots.last.x,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                      radius: 3.5,
                      color: AppColors.accent,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x594D9FFF),
                        Color(0x004D9FFF),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (_, __) => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
      ),
    );
  }

  Widget _buildTimeRange(WidgetRef ref) {
    final ranges = ['1Dk', '24S', '1H', '1A', '1Y', 'Max'];
    final activeRange = ref.watch(timeRangeProvider);
    return Row(
      children: ranges.asMap().entries.map((e) {
        final selected = e.value == activeRange;
        return Expanded(
          child: GestureDetector(
            onTap: () => ref.read(timeRangeProvider.notifier).state = e.value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              margin: EdgeInsets.only(right: e.key < ranges.length - 1 ? 2 : 0),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Text(
                e.value,
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.accent : AppColors.text3,
                  letterSpacing: 0.02,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMarketTypeToggle(TradeFormState state, TradeFormNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline, width: 0.5),
      ),
      child: Row(
        children: [
          _MarketTypeButton(
            label: 'Spot',
            selected: !state.isFutures,
            onTap: () => notifier.setIsFutures(false),
          ),
          _MarketTypeButton(
            label: 'Futures',
            selected: state.isFutures,
            onTap: () => notifier.setIsFutures(true),
          ),
        ],
      ),
    );
  }

  Widget _buildLeverageSlider(TradeFormState state, TradeFormNotifier notifier) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('KALDIRAÇ',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: AppColors.text3, letterSpacing: 0.06)),
              const Spacer(),
              Text('${state.leverage}x',
                  style: AppTheme.mono(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ],
          ),
          Slider(
            value: state.leverage.toDouble(),
            min: 1,
            max: 20, // Güvenlik amacıyla ilk sürümde sabit üst sınır.
            divisions: 19,
            activeColor: AppColors.accent,
            onChanged: (v) => notifier.setLeverage(v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildSideToggle(TradeFormState state, TradeFormNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline, width: 0.5),
      ),
      child: Row(
        children: [
          _SideButton(
            label: state.isFutures ? 'Long' : 'Al',
            selected: state.side == TradeSide.buy,
            isBuy: true,
            onTap: () => notifier.setSide(TradeSide.buy),
          ),
          _SideButton(
            label: state.isFutures ? 'Short' : 'Sat',
            selected: state.side == TradeSide.sell,
            isBuy: false,
            // Spot'ta short yok — backend de reddediyor, burada da engelle.
            onTap: state.isFutures ? () => notifier.setSide(TradeSide.sell) : null,
          ),

        ],
      ),
    );
  }

  Widget _buildRiskCard(TradeFormState state) {
    return AccentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gps_fixed,
                    color: AppColors.accent, size: 15),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RİSK HESAPLAYICI',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                        letterSpacing: 0.1,
                      )),
                  Text('Profil: kasanın %${state.riskPercent.toStringAsFixed(0)} riski',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11, color: AppColors.text3)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('İdeal Alım Miktarı',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 11, color: AppColors.text3)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                state.idealUnits.toStringAsFixed(4),
                style: AppTheme.mono(
                    fontSize: 28, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 6),
              Text(state.coin.symbol,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text2)),
              const Spacer(),
              Text(
                '≈ ${Formatters.moneyCompact(state.positionSize)}',
                style: AppTheme.mono(fontSize: 13, color: AppColors.text2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.hairline, height: 1, thickness: 0.5),
          const SizedBox(height: 12),
          Row(
            children: [
              _RiskStat(
                label: 'RİSK',
                value: Formatters.moneyCompact(state.riskAmount),
                color: AppColors.loss,
              ),
              _RiskStat(
                label: 'POZİSYON',
                value: '%${state.positionPercent.toStringAsFixed(1)}',
                color: AppColors.text1,
              ),
              _RiskStat(
                label: 'HEDEF (1:${state.rrRatio.toStringAsFixed(1)})',
                value: Formatters.moneyCompact(state.targetPrice),
                color: AppColors.profit,
              ),
            ],
          ),
          if (state.estimatedLiquidationPrice != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.hairline, height: 1, thickness: 0.5),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.loss, size: 13),
                const SizedBox(width: 6),
                Text('≈ Yaklaşık Likidasyon (${state.leverage}x)',
                    style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
                const Spacer(),
                Text(
                  Formatters.moneyCompact(state.estimatedLiquidationPrice!),
                  style: AppTheme.mono(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.loss),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Kesin değer emir gönderildikten sonra borsadan alınır.',
              style: GoogleFonts.spaceGrotesk(fontSize: 9.5, color: AppColors.text3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, WidgetRef ref, TradeFormState state) {
    final isBuy = state.side == TradeSide.buy;
    final color = isBuy ? AppColors.profit : AppColors.loss;
    final commission = state.positionSize * 0.001;
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, Color.lerp(color, Colors.black, 0.3)!],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TextButton(
            onPressed: () => _submitOrder(context, ref, state),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Emri Onayla — ${state.isFutures ? (isBuy ? 'Long' : 'Short') : (isBuy ? 'Al' : 'Sat')}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 11, color: AppColors.text3),
            const SizedBox(width: 4),
            Text(
              'Komisyon dahil ≈ ${Formatters.money(commission)}',
              style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitOrder(BuildContext context, WidgetRef ref, TradeFormState state) async {
    if (state.selectedKeyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir borsa bağlantısı seçin')),
      );
      return;
    }
    final payload = CreateOrderPayload(
      exchangeKeyId: state.selectedKeyId!,
      symbol: state.coin.pair,   // use selected coin, not hardcoded BTCUSDT
      side: state.side == TradeSide.buy ? 'BUY' : 'SELL',
      type: state.orderType.toUpperCase().replaceAll('-', '_'),
      amount: state.idealUnits,
      entryPrice: state.entryPrice,
      stopLoss: state.stopLoss,
      takeProfit: state.targetPrice,
      marketType: state.isFutures ? 'FUTURES' : 'SPOT',
      leverage: state.isFutures ? state.leverage : null,
      marginMode: state.isFutures ? 'ISOLATED' : null,
    );
    try {
      await ref.read(tradeStateProvider.notifier).createOrder(payload);

      // İşlem başarılı → bakiye provider'larını yenile
      // Backend'e 1sn işlem için süre ver, sonra yenile
      await Future.delayed(const Duration(milliseconds: 1200));
      ref.invalidate(accountBalanceProvider);
      ref.invalidate(realPortfolioProvider);
      ref.invalidate(transactionsProvider);

      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderSuccessScreen()));
      }
    } on DioException catch (e) {
      if (context.mounted) {
        final msg = e.response?.data?.toString() ?? e.message ?? 'Hata oluştu';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.loss),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.loss),
        );
      }
    }
  }

  void _showOrderTypePicker(
      BuildContext context, TradeFormState state, TradeFormNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111828),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emir Tipi', style: GoogleFonts.spaceGrotesk(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text1)),
            const SizedBox(height: 4),
            Text('Kullanmak istediğiniz emir tipini seçin',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
            const SizedBox(height: 16),
            ..._kOrderTypes.map((t) => GestureDetector(
              onTap: () {
                notifier.setOrderType(t);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: state.orderType == t
                      ? AppColors.accentSoft
                      : const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: state.orderType == t
                          ? AppColors.hairlineAccent
                          : AppColors.hairline,
                      width: 0.5),
                ),
                child: Row(children: [
                  Text(t, style: GoogleFonts.spaceGrotesk(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: state.orderType == t ? AppColors.accent : AppColors.text1)),
                  const Spacer(),
                  if (state.orderType == t)
                    const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 18),
                ]),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isBuy;
  final VoidCallback? onTap;

  const _SideButton({
    required this.label,
    required this.selected,
    required this.isBuy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final activeColor = isBuy ? AppColors.profit : AppColors.loss;
    final activeBg = isBuy ? AppColors.profitSoft : AppColors.lossSoft;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected
                ? Border.all(
                    color: activeColor.withValues(alpha: 0.3), width: 0.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: disabled
                  ? AppColors.text3.withValues(alpha: 0.5)
                  : (selected ? activeColor : AppColors.text2),
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketTypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MarketTypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected
                ? Border.all(color: AppColors.hairlineAccent, width: 0.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.accent : AppColors.text2,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final double value;
  final String suffix;
  final bool isLoss;
  final ValueChanged<double> onChanged;

  const _InputCard({
    super.key,
    required this.label,
    required this.value,
    required this.suffix,
    this.isLoss = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isLoss
            ? const Color(0xFF0E1430)
            : AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLoss
              ? const Color(0x2EF08080)
              : AppColors.hairline,
          width: 0.5,
        ),
        gradient: isLoss
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0E1430), Color(0x0AF08080)],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLoss) ...[
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.loss, size: 11),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isLoss ? AppColors.loss : AppColors.text3,
                  letterSpacing: 0.02,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('\$',
                  style:
                      AppTheme.mono(fontSize: 14, color: AppColors.text3)),
              const SizedBox(width: 4),
              Expanded(
                child: TextFormField(
                  initialValue: Formatters.price(value),
                  style: AppTheme.mono(fontSize: 20, fontWeight: FontWeight.w500),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (v) {
                    final parsed = double.tryParse(v.replaceAll(',', ''));
                    if (parsed != null) onChanged(parsed);
                  },
                ),
              ),
              Text(
                suffix,
                style: AppTheme.mono(
                  fontSize: 11,
                  color: isLoss ? AppColors.loss : AppColors.text3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RiskStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  color: AppColors.text3,
                  letterSpacing: 0.02)),
          const SizedBox(height: 3),
          Text(value,
              style: AppTheme.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Exchange Key Selector ──────────────────────────────────────────────
class _ExchangeKeySelector extends StatelessWidget {
  final AsyncValue<List<ApiKey>> keysAsync;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _ExchangeKeySelector({
    required this.keysAsync,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return keysAsync.when(
      data: (keys) {
        if (keys.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairline, width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.loss, size: 16),
              const SizedBox(width: 8),
              Text('Borsa bağlantısı yok — önce API Key ekleyin',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
            ]),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairline, width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedId,
              hint: Text('Borsa seç', style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text3)),
              dropdownColor: AppColors.surface2,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.text3, size: 18),
              items: keys.map((k) => DropdownMenuItem(
                value: k.id,
                child: Text('${k.exchange} — ${k.mask}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AppColors.text1)),
              )).toList(),
              onChanged: (v) { if (v != null) onSelected(v); },
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 44, child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Active Orders Panel ────────────────────────────────────────────────
class _ActiveOrdersPanel extends StatelessWidget {
  final AsyncValue<List<OrderModel>> ordersAsync;
  final WidgetRef ref;

  const _ActiveOrdersPanel({required this.ordersAsync, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) return const SizedBox.shrink();
        final open = orders.where((o) => o.isOpen).toList();
        if (open.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('AKTİF POZİSYONLAR',
                  style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 0.1)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(4)),
                child: Text('${open.length}', style: AppTheme.mono(fontSize: 10, color: AppColors.accent)),
              ),
            ]),
            const SizedBox(height: 10),
            ...open.map((o) => _OrderCard(order: o, ref: ref)),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final WidgetRef ref;
  const _OrderCard({required this.order, required this.ref});

  @override
  Widget build(BuildContext context) {
    final pnl = order.currentPnL ?? 0.0;
    final isProfit = pnl >= 0;

    // Likidasyona yakınlık uyarısı — anlık fiyat kopyası (canlı tick'e değil,
    // bu panelin son yenilenişine göre günceldir).
    String? liqWarning;
    if (order.isFutures && order.liquidationPrice != null) {
      final base = order.symbol.replaceAll('USDT', '').replaceAll('BUSD', '');
      final livePrice = ref.read(livePricesProvider)[base] ?? order.entryPrice;
      if (livePrice != null && livePrice > 0) {
        final distancePct =
            ((livePrice - order.liquidationPrice!).abs() / livePrice) * 100;
        if (distancePct <= 5) {
          liqWarning = 'Likidasyona %${distancePct.toStringAsFixed(1)} kaldı';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: liqWarning != null ? AppColors.loss.withValues(alpha: 0.5) : AppColors.hairline,
          width: liqWarning != null ? 1 : 0.5,
        ),
      ),
      child: Row(children: [
        CoinAvatar(symbol: order.symbol.replaceAll('USDT', '').replaceAll('BUSD', ''), size: 32),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: order.isBuy ? AppColors.profitSoft : AppColors.lossSoft,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                  order.isFutures
                      ? (order.isBuy ? 'LONG' : 'SHORT')
                      : (order.isBuy ? 'ALIŞ' : 'SATIŞ'),
                  style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700,
                      color: order.isBuy ? AppColors.profit : AppColors.loss)),
            ),
            if (order.isFutures) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${order.leverage ?? 1}x',
                    style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ),
            ],
            const SizedBox(width: 6),
            Text(order.symbol, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text1)),
          ]),
          const SizedBox(height: 2),
          Text('${order.amount.toStringAsFixed(4)} adet',
              style: AppTheme.mono(fontSize: 11, color: AppColors.text3)),
          if (liqWarning != null) ...[
            const SizedBox(height: 3),
            Text(liqWarning,
                style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.loss)),
          ],
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${isProfit ? '+' : ''}${Formatters.money(pnl)}',
            style: AppTheme.mono(fontSize: 14, fontWeight: FontWeight.w500,
                color: isProfit ? AppColors.profit : AppColors.loss),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _closeOrder(context, order.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.lossSoft,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.loss.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Text('Kapat', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AppColors.loss, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _closeOrder(BuildContext context, String orderId) async {
    try {
      await ref.read(tradeStateProvider.notifier).closeOrder(orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pozisyon kapatıldı', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
            backgroundColor: const Color(0xFF1A2040),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.loss),
        );
      }
    }
  }
}

// ── Coin Selector ──────────────────────────────────────────────────────
class _CoinSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _CoinSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('İşlem Çifti',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 11, color: AppColors.text3, letterSpacing: 0.04)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _kTradeCoins.map((coin) {
              final isSelected = coin.symbol == selected;
              return GestureDetector(
                onTap: () => onSelected(coin.symbol),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentSoft : AppColors.surface1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.hairlineAccent : AppColors.hairline,
                      width: 0.5,
                    ),
                  ),
                  child: Row(children: [
                    CoinAvatar(symbol: coin.symbol, size: 22),
                    const SizedBox(width: 7),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(coin.symbol,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.accent : AppColors.text1)),
                      Text(coin.pair,
                          style: AppTheme.mono(fontSize: 9, color: AppColors.text3)),
                    ]),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Coin Price Header ──────────────────────────────────────────────────
/// Selected coin's name, price and 24h delta — updates on coin switch,
/// and reflects the live WebSocket price stream when available.
class _CoinPriceHeader extends ConsumerWidget {
  final _TradeCoin coin;
  final double entryPrice;
  const _CoinPriceHeader({required this.coin, required this.entryPrice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gerçek 24 saatlik değişim ve fiyat — backend'in bağlı borsadan
    // çektiği piyasa verisinden (marketCoinsProvider) okunuyor.
    final marketCoins = ref.watch(marketCoinsProvider).valueOrNull ?? const [];
    CoinData? match;
    for (final c in marketCoins) {
      if (c.symbol == coin.symbol) {
        match = c;
        break;
      }
    }
    final delta = match?.priceChangePercent ?? 0.0;
    final livePrice = ref.watch(livePricesProvider)[coin.symbol];
    final price =
        livePrice ?? match?.price ?? _kCoinBasePrices[coin.symbol] ?? entryPrice;

    return Row(children: [
      CoinAvatar(symbol: coin.symbol, size: 42),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(coin.name, style: GoogleFonts.spaceGrotesk(
              fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.1)),
          const SizedBox(width: 8),
          Text(coin.pair, style: AppTheme.mono(fontSize: 11, color: AppColors.text3)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          RichText(text: TextSpan(children: [
            TextSpan(
              text: '\$${price.toStringAsFixed(price < 10 ? 3 : 0).replaceAllMapped(
                RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},',
              )}.',
              style: AppTheme.mono(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: price < 10
                  ? ''
                  : price.toStringAsFixed(2).split('.')[1],
              style: AppTheme.mono(fontSize: 22, fontWeight: FontWeight.w500,
                  color: AppColors.text3),
            ),
          ])),
          const SizedBox(width: 8),
          DeltaPill(value: delta),
        ]),
      ])),
    ]);
  }
}
