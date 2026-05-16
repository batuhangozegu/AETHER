// lib/widgets/coin_avatar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CoinAvatar extends StatelessWidget {
  final String symbol;
  final double size;

  const CoinAvatar({super.key, required this.symbol, this.size = 36});

  static const _palette = <String, _CoinStyle>{
    'BTC': _CoinStyle(color: AppColors.btc, label: '₿'),
    'ETH': _CoinStyle(color: AppColors.eth, label: 'Ξ'),
    'SOL': _CoinStyle(color: AppColors.sol, label: 'S'),
    'AVAX': _CoinStyle(color: AppColors.avax, label: 'A'),
    'LINK': _CoinStyle(color: AppColors.link, label: 'L'),
    'USDT': _CoinStyle(color: AppColors.profit, label: '₮'),
  };

  @override
  Widget build(BuildContext context) {
    final style = _palette[symbol] ??
        _CoinStyle(color: AppColors.text3, label: symbol.substring(0, 1));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        style.label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0A0F24),
          height: 1,
        ),
      ),
    );
  }
}

class _CoinStyle {
  final Color color;
  final String label;
  const _CoinStyle({required this.color, required this.label});
}
