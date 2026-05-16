// lib/widgets/delta_pill.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum DeltaSize { sm, lg }

class DeltaPill extends StatelessWidget {
  final double value;
  final DeltaSize size;

  const DeltaPill({super.key, required this.value, this.size = DeltaSize.sm});

  @override
  Widget build(BuildContext context) {
    final isUp = value >= 0;
    final bgColor = isUp ? AppColors.profitSoft : AppColors.lossSoft;
    final textColor = isUp ? AppColors.profit : AppColors.loss;
    final fontSize = size == DeltaSize.lg ? 13.0 : 11.0;
    final hPad = size == DeltaSize.lg ? 10.0 : 7.0;
    final vPad = size == DeltaSize.lg ? 5.0 : 3.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: textColor,
            size: fontSize + 4,
          ),
          Text(
            '${value.abs().toStringAsFixed(2)}%',
            style: GoogleFonts.jetBrainsMono(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: textColor,
              letterSpacing: 0.01,
            ),
          ),
        ],
      ),
    );
  }
}
