// lib/widgets/glass_card.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x09FFFFFF), Color(0x03FFFFFF)],
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0DFFFFFF),
            blurRadius: 0,
            spreadRadius: 0,
            offset: Offset(0, 0.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

/// Accent gradient kartı (Trade / Risk ekranları için)
class AccentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AccentCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x144D9FFF), Color(0x0D7C5CFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairlineAccent, width: 0.5),
      ),
      child: child,
    );
  }
}
