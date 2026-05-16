// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/coin_avatar.dart';

// ── Provider ───────────────────────────────────────────────────────────
final _historyApiProvider = Provider((_) => ApiService());

final transactionsProvider = FutureProvider((ref) {
  return ref.watch(_historyApiProvider).getTransactions();
});

final historyFilterProvider = StateProvider<String>((_) => 'all');

// ── Screen ─────────────────────────────────────────────────────────────
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final filter = ref.watch(historyFilterProvider);

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GEÇMİŞ',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.11,
                                color: AppColors.text3,
                              )),
                          const SizedBox(height: 4),
                          Text('İşlemlerim',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                                color: AppColors.text1,
                              )),
                        ],
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.hairline, width: 0.5),
                        ),
                        child: const Icon(Icons.search,
                            color: AppColors.text2, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary cards
                  txAsync.when(
                    data: (txs) => _buildSummary(txs),
                    loading: () => const SizedBox(height: 60),
                    error: (_, __) => const SizedBox(height: 60),
                  ),
                  const SizedBox(height: 14),

                  // Filter chips
                  txAsync.when(
                    data: (txs) => _buildFilters(context, ref, txs, filter),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),

          // Timeline list
          txAsync.when(
            data: (txs) {
              final filtered = filter == 'all'
                  ? txs
                  : txs.where((t) => t.side == filter).toList();
              final groups = _groupByDate(filtered);

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, gi) {
                    final group = groups[gi];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                          22, gi == 0 ? 0 : 18, 22, 0),
                      child: _DateGroup(group: group),
                    );
                  },
                  childCount: groups.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.accent),
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

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('— Geçmişin sonu —',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.text3)),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSummary(List<Transaction> txs) {
    final buys =
        txs.where((t) => t.isBuy).fold(0.0, (s, t) => s + t.total);
    final sells =
        txs.where((t) => !t.isBuy).fold(0.0, (s, t) => s + t.total);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Toplam Alım',
            value: Formatters.moneyCompact(buys),
            color: AppColors.profit,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Toplam Satım',
            value: Formatters.moneyCompact(sells),
            color: AppColors.loss,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref,
      List<Transaction> txs, String filter) {
    final options = [
      _FilterOption('all', 'Hepsi', txs.length),
      _FilterOption('buy', 'Alış', txs.where((t) => t.isBuy).length),
      _FilterOption('sell', 'Satış', txs.where((t) => !t.isBuy).length),
    ];
    return Row(
      children: options
          .map((f) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _FilterChip(
                  option: f,
                  selected: filter == f.id,
                  onTap: () => ref
                      .read(historyFilterProvider.notifier)
                      .state = f.id,
                ),
              ))
          .toList(),
    );
  }

  List<_TxGroup> _groupByDate(List<Transaction> txs) {
    final groups = <_TxGroup>[];
    _TxGroup? current;
    for (final t in txs) {
      if (current == null || current.date != t.date) {
        current = _TxGroup(t.date, []);
        groups.add(current);
      }
      current.items.add(t);
    }
    return groups;
  }
}

class _TxGroup {
  final String date;
  final List<Transaction> items;
  _TxGroup(this.date, this.items);
}

class _FilterOption {
  final String id, label;
  final int count;
  _FilterOption(this.id, this.label, this.count);
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  color: AppColors.text3,
                  letterSpacing: 0.04)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTheme.mono(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final _FilterOption option;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface1,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.hairlineAccent : AppColors.hairline,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(option.label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.accent : AppColors.text2,
                )),
            const SizedBox(width: 6),
            Text('${option.count}',
                style: AppTheme.mono(
                    fontSize: 10,
                    color: (selected ? AppColors.accent : AppColors.text3)
                        .withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final _TxGroup group;
  const _DateGroup({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 22, bottom: 8),
          child: Text(group.date,
              style: AppTheme.mono(
                  fontSize: 11, color: AppColors.text3, letterSpacing: 0.04)),
        ),
        Stack(
          children: [
            // Timeline rail
            Positioned(
              left: 7,
              top: 12,
              bottom: 12,
              child: Container(
                width: 1,
                color: AppColors.hairline,
              ),
            ),
            Column(
              children: group.items
                  .map((t) => _TxRow(tx: t))
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  final Transaction tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Timeline dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 4, right: 14),
            decoration: BoxDecoration(
              color: tx.isBuy ? AppColors.profit : AppColors.loss,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (tx.isBuy ? AppColors.profit : AppColors.loss)
                      .withValues(alpha: 0.3),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairline, width: 0.5),
              ),
              child: Row(
                children: [
                  CoinAvatar(symbol: tx.symbol, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              tx.isBuy ? 'ALIŞ' : 'SATIŞ',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tx.isBuy
                                    ? AppColors.profit
                                    : AppColors.loss,
                                letterSpacing: 0.04,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(tx.symbol,
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.text1)),
                            const Spacer(),
                            Text(tx.time,
                                style: AppTheme.mono(
                                    fontSize: 11,
                                    color: AppColors.text3)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${Formatters.coinAmount(tx.amount)} @ \$${Formatters.price(tx.price)}',
                              style: AppTheme.mono(
                                  fontSize: 12, color: AppColors.text2),
                            ),
                            const Spacer(),
                            Text(
                              '${tx.isBuy ? '−' : '+'}${Formatters.money(tx.total)}',
                              style: AppTheme.mono(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
