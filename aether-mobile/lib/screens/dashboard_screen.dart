// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/asset.dart';
import '../providers/app_providers.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/coin_avatar.dart';
import '../widgets/delta_pill.dart';
import '../widgets/sparkline_chart.dart';
import 'markets_screen.dart';
import 'notifications_screen.dart';
import 'portfolio_breakdown_screen.dart';

// ── Providers ──────────────────────────────────────────────────────────
final _apiProvider = Provider((_) => ApiService());

final portfolioProvider = FutureProvider((ref) {
  return ref.watch(_apiProvider).getPortfolio();
});

final holdingsProvider = FutureProvider((ref) {
  return ref.watch(_apiProvider).getHoldings();
});

// ── Screen ─────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final holdingsAsync = ref.watch(holdingsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        children: [
          // Aurora arka plan
          const Positioned(
            top: 0, right: 0, left: 0,
            height: 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.6, -0.8),
                  radius: 1.2,
                  colors: [Color(0x174D9FFF), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header (ref geçiriliyor — profil butonu için)
              SliverToBoxAdapter(
                  child: _buildHeader(context, ref, portfolioAsync)),
              // Yeni İşlem butonu
              SliverToBoxAdapter(child: _buildQuickAction(context, ref)),
              // Varlıklar başlığı
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 6),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortfolioBreakdownScreen())),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'VARLIKLARİM',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.11,
                            color: AppColors.text3,
                          ),
                        ),
                        holdingsAsync.when(
                          data: (h) => Row(
                            children: [
                              Text(
                                '${h.length} coin',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12, color: AppColors.text3),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 14, color: AppColors.text3),
                            ],
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Varlık listesi
              holdingsAsync.when(
                data: (holdings) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: EdgeInsets.fromLTRB(
                          22,
                          i == 0 ? 0 : 3,
                          22,
                          i == holdings.length - 1 ? 24 : 3),
                      child: _AssetCard(asset: holdings[i]),
                    ),
                    childCount: holdings.length,
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppColors.accent),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Text('Hata: $e',
                        style: const TextStyle(color: AppColors.loss)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Portfolio> portfolioAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 64, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOPLAM BAKİYE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.11,
                  color: AppColors.text3,
                ),
              ),
              Row(
                children: [
                  // Bildirim butonu
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    child: Stack(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.hairline, width: 0.5)),
                        child: const Icon(Icons.notifications_outlined, color: AppColors.text2, size: 18)),
                      Positioned(top: 7, right: 7, child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.accent, blurRadius: 4)]))),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  // Profil avatarı — tıklanınca Profil tabına gider
                  GestureDetector(
                    onTap: () =>
                        ref.read(navIndexProvider.notifier).state = 4,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.accentGradient,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'MK',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bakiye
          portfolioAsync.when(
            data: (p) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '\$',
                        style: AppTheme.mono(
                            fontSize: 16, color: AppColors.text3),
                      ),
                      TextSpan(
                        text: Formatters.price(
                            p.balance.floorToDouble()),
                        style: AppTheme.mono(
                          fontSize: 42,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            '.${p.balance.toStringAsFixed(2).split('.')[1]}',
                        style: AppTheme.mono(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    DeltaPill(value: p.pnl24hPercent, size: DeltaSize.lg),
                    const SizedBox(width: 10),
                    Text(
                      '${p.pnl24h >= 0 ? '+' : '−'}\$${Formatters.price(p.pnl24h.abs())}',
                      style: AppTheme.mono(
                        fontSize: 13,
                        color: p.pnl24h >= 0
                            ? AppColors.profit
                            : AppColors.loss,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('24s',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12, color: AppColors.text3)),
                  ],
                ),
              ],
            ),
            loading: () => const SizedBox(
              height: 70,
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent)),
            ),
            error: (_, __) => const SizedBox(height: 70),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ── Hızlı İşlemler: Yeni İşlem + Senkronize Et ─────────────────────
  Widget _buildQuickAction(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Row(children: [
        Expanded(child: GestureDetector(
          onTap: () => ref.read(navIndexProvider.notifier).state = 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairlineAccent, width: 0.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.swap_vert_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text('Yeni İşlem', style: GoogleFonts.spaceGrotesk(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ]),
          ),
        )),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketsScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(color: AppColors.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline, width: 0.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.text1, size: 18),
              const SizedBox(width: 8),
              Text('Piyasalar', style: GoogleFonts.spaceGrotesk(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
            ]),
          ),
        )),
      ]),
    );
  }
}

// ── Varlık kartı ────────────────────────────────────────────────────────
class _AssetCard extends StatelessWidget {
  final Asset asset;

  const _AssetCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline, width: 0.5),
      ),
      child: Row(
        children: [
          CoinAvatar(symbol: asset.symbol, size: 36),
          const SizedBox(width: 10),
          // Sol: isim + ort fiyat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.symbol,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ort. \$${Formatters.price(asset.avgPrice)}',
                  style: AppTheme.mono(
                      fontSize: 11, color: AppColors.text3),
                ),
              ],
            ),
          ),
          // Orta: sparkline + değer
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SparklineChart(
                points: asset.sparkline,
                color:
                    asset.isProfit ? AppColors.profit : AppColors.loss,
                width: 44,
                height: 18,
              ),
              const SizedBox(height: 3),
              Text(
                Formatters.moneyCompact(asset.value),
                style: AppTheme.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Sağ: delta pill
          DeltaPill(value: asset.pnlPercent),
        ],
      ),
    );
  }
}
