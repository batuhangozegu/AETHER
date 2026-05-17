// lib/screens/trade_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/coin_avatar.dart';
import '../widgets/delta_pill.dart';
import '../widgets/glass_card.dart';
import '../widgets/trade_dialogs.dart';

// ── Providers ──────────────────────────────────────────────────────────
final _tradeApiProvider = Provider((_) => ApiService());

final priceHistoryProvider = FutureProvider((ref) {
  return ref.watch(_tradeApiProvider).getPriceHistory('BTC');
});

// ── State ──────────────────────────────────────────────────────────────
enum TradeSide { buy, sell }

class TradeState {
  final TradeSide side;
  final double entryPrice;
  final double stopLoss;

  const TradeState({
    this.side = TradeSide.buy,
    this.entryPrice = 67234.12,
    this.stopLoss = 65800.00,
  });

  double get accountBalance => 84273.52;
  double get riskPercent => 2.0;
  double get riskAmount => accountBalance * (riskPercent / 100);
  double get stopDistance => (entryPrice - stopLoss).abs();
  double get idealUnits => stopDistance > 0 ? riskAmount / stopDistance : 0;
  double get positionSize => idealUnits * entryPrice;
  double get positionPercent => (positionSize / accountBalance) * 100;
  double get targetPrice => entryPrice + stopDistance * 2.5;
  double get stopPercent =>
      entryPrice > 0 ? ((entryPrice - stopLoss) / entryPrice) * 100 : 0;

  TradeState copyWith({TradeSide? side, double? entryPrice, double? stopLoss}) =>
      TradeState(
        side: side ?? this.side,
        entryPrice: entryPrice ?? this.entryPrice,
        stopLoss: stopLoss ?? this.stopLoss,
      );
}

class TradeNotifier extends StateNotifier<TradeState> {
  TradeNotifier() : super(const TradeState());
  void setSide(TradeSide side) => state = state.copyWith(side: side);
  void setEntry(double v) => state = state.copyWith(entryPrice: v);
  void setStop(double v) => state = state.copyWith(stopLoss: v);
}

final tradeProvider = StateNotifierProvider<TradeNotifier, TradeState>(
  (_) => TradeNotifier(),
);

// ── Screen ─────────────────────────────────────────────────────────────
class TradeScreen extends ConsumerWidget {
  const TradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradeProvider);
    final notifier = ref.read(tradeProvider.notifier);
    final historyAsync = ref.watch(priceHistoryProvider);

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
                          Container(
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
                                Text('Limit',
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.text2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Coin info
                      Row(
                        children: [
                          const CoinAvatar(symbol: 'BTC', size: 42),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Bitcoin',
                                        style: GoogleFonts.spaceGrotesk(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.1)),
                                    const SizedBox(width: 8),
                                    Text('BTC / USD',
                                        style: AppTheme.mono(
                                            fontSize: 12,
                                            color: AppColors.text3)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                              text: '\$67,234.',
                                              style: AppTheme.mono(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500)),
                                          TextSpan(
                                              text: '12',
                                              style: AppTheme.mono(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.text3)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const DeltaPill(value: 2.84),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Chart
                      _buildChart(historyAsync),
                      const SizedBox(height: 12),

                      // Time range
                      _buildTimeRange(),
                      const SizedBox(height: 18),

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
                      _buildConfirmButton(context, state),
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

  Widget _buildTimeRange() {
    final ranges = ['1S', '24S', '1H', '1A', '1Y', 'Max'];
    return Row(
      children: ranges.asMap().entries.map((e) {
        final selected = e.key == 1;
        return Expanded(
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
        );
      }).toList(),
    );
  }

  Widget _buildSideToggle(TradeState state, TradeNotifier notifier) {
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

  Widget _buildRiskCard(TradeState state) {
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
              Text('BTC',
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

  Widget _buildConfirmButton(BuildContext context, TradeState state) {
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
            onPressed: () {
              showOrderConfirmSheet(
                context,
                isBuy: isBuy,
                entry: state.entryPrice,
                stop: state.stopLoss,
                target: state.targetPrice,
              );
            },
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
            const Icon(Icons.info_outline,
                size: 11, color: AppColors.text3),
            const SizedBox(width: 4),
            Text(
              'Komisyon dahil ≈ ${Formatters.money(commission)}',
              style:
                  GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3),
            ),
          ],
        ),
      ],
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
