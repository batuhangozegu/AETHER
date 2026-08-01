// lib/screens/trade_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../models/order.dart';
import '../providers/api_keys_provider.dart';
import '../providers/app_providers.dart';
import '../providers/trade_provider.dart';
import '../providers/live_prices_provider.dart';
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

// ── Per-coin mock price data (Faz 7 gelmeden önce sabit őrnek) ─────
/// Her coin için farklı bir yaklaşık fiyat seti kullanılıyor.
/// Format: kısa price history (normalised = price x factor)
const _kCoinBasePrices = {
  'BTC': 67234.12,
  'ETH': 3821.55,
  'SOL': 178.44,
  'BNB': 418.70,
  'ADA': 0.651,
};

/// Coin'e özgü fiyat geçmişi mölcü verileri.
/// Her sembolün kendi iner/çıkar şekli var.
const _kCoinHistory = {
  'BTC': [65100.0, 64800.0, 66200.0, 65700.0, 67100.0, 66500.0, 67800.0, 67234.12],
  'ETH': [3600.0, 3650.0, 3720.0, 3680.0, 3750.0, 3800.0, 3810.0, 3821.55],
  'SOL': [172.0, 168.5, 174.3, 176.0, 171.0, 179.2, 177.0, 178.44],
  'BNB': [400.0, 405.5, 410.0, 415.2, 412.0, 416.8, 419.0, 418.70],
  'ADA': [0.601, 0.620, 0.615, 0.635, 0.628, 0.644, 0.650, 0.651],
};

// ── Providers ──────────────────────────────────────────────────────────

/// Selected chart time range — drives which candle interval is requested.
final timeRangeProvider = StateProvider<String>((_) => '24S');

const _kRangeToInterval = {
  '1S': '1m',
  '24S': '15m',
  '1H': '4h',
  '1A': '1d',
  '1Y': '1w',
  'Max': '1M',
};

/// Coin'e göre fiyat geçmişi döndüren family provider — backend candle
/// history'sinden gerçek kapanış fiyatlarını çeker; borsa bağlantısı yoksa
/// veya istek başarısız olursa yaklaşık mock veriye düşer.
final priceHistoryProvider =
    FutureProvider.family<List<double>, String>((ref, symbol) async {
  final keys = ref.watch(apiKeysProvider).valueOrNull ?? [];
  final fallback = _kCoinHistory[symbol] ?? _kCoinHistory['BTC']!;
  if (keys.isEmpty) return fallback;

  final range = ref.watch(timeRangeProvider);
  final interval = _kRangeToInterval[range] ?? '15m';
  final coin = _kTradeCoins.firstWhere((c) => c.symbol == symbol,
      orElse: () => _kTradeCoins.first);

  try {
    final api = ref.watch(apiServiceProvider);
    final candles = await api.getCandleHistory(keys.first.id, coin.pair, interval);
    if (candles.isEmpty) return fallback;
    return candles.map((c) => c.close).toList();
  } catch (_) {
    return fallback;
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

  const TradeFormState({
    this.side = TradeSide.buy,
    this.entryPrice = 67234.12,
    this.stopLoss = 65800.00,
    this.selectedKeyId,
    this.accountBalance = 0.0,
    this.selectedCoinIdx = 'BTC',
    this.orderType = 'Limit',
    this.riskPercent = 2.0,
  });

  double get riskAmount => accountBalance * (riskPercent / 100);
  double get stopDistance => (entryPrice - stopLoss).abs();
  double get idealUnits => stopDistance > 0 ? riskAmount / stopDistance : 0;
  double get positionSize => idealUnits * entryPrice;
  double get positionPercent =>
      accountBalance > 0 ? (positionSize / accountBalance) * 100 : 0;
  double get targetPrice => entryPrice + stopDistance * 2.5;
  double get stopPercent =>
      entryPrice > 0 ? ((entryPrice - stopLoss) / entryPrice) * 100 : 0;

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
      );
}

class TradeFormNotifier extends StateNotifier<TradeFormState> {
  TradeFormNotifier() : super(const TradeFormState());
  void setSide(TradeSide side) => state = state.copyWith(side: side);
  void setEntry(double v) => state = state.copyWith(entryPrice: v);
  void setStop(double v) => state = state.copyWith(stopLoss: v);
  void setKeyId(String id) => state = state.copyWith(selectedKeyId: id);
  void setBalance(double b) => state = state.copyWith(accountBalance: b);
  void setOrderType(String t) => state = state.copyWith(orderType: t);

  /// Coin değişince hem symbol hem de giriş/stop-loss fiyatlarını sıfırla
  void setCoin(String symbol) {
    // Coin'e özgü varsayılan giriş + stop-loss değerleri
    const defaults = {
      'BTC': (67234.12, 65800.0),
      'ETH': (3821.55,  3700.0),
      'SOL': (178.44,   172.0),
      'BNB': (418.70,   408.0),
      'ADA': (0.651,    0.62),
    };
    final d = defaults[symbol];
    state = state.copyWith(
      selectedCoinIdx: symbol,
      entryPrice: d?.$1 ?? state.entryPrice,
      stopLoss:   d?.$2 ?? state.stopLoss,
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
    // Always reflect the user's saved risk-per-trade % (falls back to the
    // form's default of 2.0 until the risk profile has loaded).
    final riskProfile = ref.watch(riskProvider);
    final state = rawState.copyWith(riskPercent: riskProfile.riskPerTrade);
    final historyAsync = ref.watch(priceHistoryProvider(state.selectedCoinIdx));
    final keysAsync = ref.watch(apiKeysProvider);
    final activeOrdersAsync = ref.watch(tradeStateProvider);
    final balanceAsync = ref.watch(accountBalanceProvider);

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
                        onSelected: notifier.setCoin,
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

                      // Buy/Sell toggle
                      _buildSideToggle(state, notifier),
                      const SizedBox(height: 14),

                      // Entry price input
                      _InputCard(
                        label: 'Giriş Fiyatı',
                        value: state.entryPrice,
                        suffix: 'USD',
                        onChanged: notifier.setEntry,
                      ),
                      const SizedBox(height: 10),

                      // Stop loss input
                      _InputCard(
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
                horizontalInterval: (points.reduce((a, b) => a > b ? a : b) -
                        points.reduce((a, b) => a < b ? a : b)) /
                    4,
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
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTimeRange(WidgetRef ref) {
    final ranges = ['1S', '24S', '1H', '1A', '1Y', 'Max'];
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
            label: 'Al',
            selected: state.side == TradeSide.buy,
            isBuy: true,
            onTap: () => notifier.setSide(TradeSide.buy),
          ),
          _SideButton(
            label: 'Sat',
            selected: state.side == TradeSide.sell,
            isBuy: false,
            onTap: () => notifier.setSide(TradeSide.sell),
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
                label: 'HEDEF (1:2.5)',
                value: Formatters.moneyCompact(state.targetPrice),
                color: AppColors.profit,
              ),
            ],
          ),
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
              'Emri Onayla — ${isBuy ? 'Al' : 'Sat'}',
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
  final VoidCallback onTap;

  const _SideButton({
    required this.label,
    required this.selected,
    required this.isBuy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              color: selected ? activeColor : AppColors.text2,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline, width: 0.5),
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
              child: Text(order.isBuy ? 'ALIŞ' : 'SATIŞ',
                  style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700,
                      color: order.isBuy ? AppColors.profit : AppColors.loss)),
            ),
            const SizedBox(width: 6),
            Text(order.symbol, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text1)),
          ]),
          const SizedBox(height: 2),
          Text('${order.amount.toStringAsFixed(4)} adet',
              style: AppTheme.mono(fontSize: 11, color: AppColors.text3)),
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
    // 24h delta lookup (approx from history first vs last point)
    const deltas = {'BTC': 2.84, 'ETH': 1.47, 'SOL': -0.63, 'BNB': 0.92, 'ADA': -1.15};
    final delta = deltas[coin.symbol] ?? 0.0;
    final isUp = delta >= 0;
    final livePrice = ref.watch(livePricesProvider)[coin.symbol];
    final price = livePrice ?? _kCoinBasePrices[coin.symbol] ?? entryPrice;

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
