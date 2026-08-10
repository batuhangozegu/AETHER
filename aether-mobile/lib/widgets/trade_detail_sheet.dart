// lib/widgets/trade_detail_sheet.dart
//
// Açık işlem kartı (trade_screen) ve geçmiş işlem satırı (history_screen)
// için ortak "tıkla, detayları gör" bottom sheet'i.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

void showTradeDetailSheet(
  BuildContext context, {
  required String symbol,
  required bool isBuy,
  required bool isFutures,
  String? statusBadge, // 'AÇIK' gibi
  int? leverage,
  String? marginMode,
  double? entryPrice,
  double? exitPrice,
  double? stopLoss,
  double? takeProfit,
  double? liquidationPrice,
  double? amount,
  double? pnl,
  double? pnlPercent,
  String? openedAt,
  String? closedAt,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _TradeDetailSheet(
      symbol: symbol,
      isBuy: isBuy,
      isFutures: isFutures,
      statusBadge: statusBadge,
      leverage: leverage,
      marginMode: marginMode,
      entryPrice: entryPrice,
      exitPrice: exitPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      liquidationPrice: liquidationPrice,
      amount: amount,
      pnl: pnl,
      pnlPercent: pnlPercent,
      openedAt: openedAt,
      closedAt: closedAt,
    ),
  );
}

class _TradeDetailSheet extends StatelessWidget {
  final String symbol;
  final bool isBuy;
  final bool isFutures;
  final String? statusBadge;
  final int? leverage;
  final String? marginMode;
  final double? entryPrice;
  final double? exitPrice;
  final double? stopLoss;
  final double? takeProfit;
  final double? liquidationPrice;
  final double? amount;
  final double? pnl;
  final double? pnlPercent;
  final String? openedAt;
  final String? closedAt;

  const _TradeDetailSheet({
    required this.symbol,
    required this.isBuy,
    required this.isFutures,
    this.statusBadge,
    this.leverage,
    this.marginMode,
    this.entryPrice,
    this.exitPrice,
    this.stopLoss,
    this.takeProfit,
    this.liquidationPrice,
    this.amount,
    this.pnl,
    this.pnlPercent,
    this.openedAt,
    this.closedAt,
  });

  @override
  Widget build(BuildContext context) {
    final sideColor = isBuy ? AppColors.profit : AppColors.loss;
    final pnlColor = (pnl ?? 0) >= 0 ? AppColors.profit : AppColors.loss;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline, width: 0.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hairlineStrong,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isBuy ? AppColors.profitSoft : AppColors.lossSoft,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                isFutures
                    ? (isBuy ? 'LONG' : 'SHORT')
                    : (isBuy ? 'ALIŞ' : 'SATIŞ'),
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: sideColor),
              ),
            ),
            if (isFutures && leverage != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                    '${leverage}x ${marginMode == 'CROSS' ? 'Cross' : 'İzole'}',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ),
            ],
            if (statusBadge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(statusBadge!,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text2)),
              ),
            ],
            const Spacer(),
            Text(symbol,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1)),
          ]),
          const SizedBox(height: 18),
          if (pnl != null) ...[
            Text('${pnl! >= 0 ? '+' : ''}${Formatters.money(pnl!)}',
                style: AppTheme.mono(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: pnlColor)),
            if (pnlPercent != null)
              Text(
                  '${pnlPercent! >= 0 ? '+' : ''}${pnlPercent!.toStringAsFixed(2)}%',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: pnlColor)),
            const SizedBox(height: 16),
            const Divider(color: AppColors.hairline, height: 1, thickness: 0.5),
            const SizedBox(height: 4),
          ],
          if (amount != null)
            _DetailRow(label: 'Miktar', value: Formatters.coinAmount(amount!)),
          if (entryPrice != null)
            _DetailRow(
                label: 'Giriş Fiyatı',
                value: '\$${Formatters.price(entryPrice!)}'),
          if (exitPrice != null)
            _DetailRow(
                label: 'Çıkış Fiyatı',
                value: '\$${Formatters.price(exitPrice!)}'),
          if (stopLoss != null)
            _DetailRow(
                label: 'Stop-Loss',
                value: '\$${Formatters.price(stopLoss!)}',
                valueColor: AppColors.loss),
          if (takeProfit != null)
            _DetailRow(
                label: 'Take-Profit',
                value: '\$${Formatters.price(takeProfit!)}',
                valueColor: AppColors.profit),
          if (liquidationPrice != null)
            _DetailRow(
                label: 'Likidasyon Fiyatı',
                value: '\$${Formatters.price(liquidationPrice!)}',
                valueColor: AppColors.loss),
          if (openedAt != null) _DetailRow(label: 'Açılış', value: openedAt!),
          if (closedAt != null) _DetailRow(label: 'Kapanış', value: closedAt!),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5, color: AppColors.text3)),
        const Spacer(),
        Text(value,
            style: AppTheme.mono(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.text1)),
      ]),
    );
  }
}
