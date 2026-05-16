// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const bg0 = Color(0xFF050816);
  static const bg1 = Color(0xFF070B1D);
  static const bg2 = Color(0xFF0A0F24);
  static const surface1 = Color(0xFF0E1430);
  static const surface2 = Color(0xFF141A3A);
  static const surface3 = Color(0xFF1C2348);

  // Borders
  static const hairline = Color(0x0EFFFFFF);        // rgba(255,255,255,0.055)
  static const hairlineStrong = Color(0x1CFFFFFF);  // rgba(255,255,255,0.11)
  static const hairlineAccent = Color(0x474D9FFF);  // rgba(77,159,255,0.28)

  // Text
  static const text1 = Color(0xFFE8ECF6);
  static const text2 = Color(0xFFA3A9C6);
  static const text3 = Color(0xFF6B7396);
  static const text4 = Color(0xFF444C70);

  // Accent
  static const accent = Color(0xFF4D9FFF);
  static const accentSoft = Color(0x294D9FFF);  // rgba(77,159,255,0.16)
  static const accentLine = Color(0x804D9FFF);  // rgba(77,159,255,0.5)

  // Profit / Loss
  static const profit = Color(0xFF5FD49B);
  static const profitSoft = Color(0x245FD49B);  // rgba(95,212,155,0.14)
  static const loss = Color(0xFFF08080);
  static const lossSoft = Color(0x24F08080);    // rgba(240,128,128,0.14)
  static const warn = Color(0xFFF5B969);

  // Coin colors
  static const btc = Color(0xFFF7A13A);
  static const eth = Color(0xFF8B9EFF);
  static const sol = Color(0xFFB692FF);
  static const avax = Color(0xFFF08080);
  static const link = Color(0xFF4D9FFF);

  // Gradient — accent aurora
  static const List<Color> accentGradient = [Color(0xFF4D9FFF), Color(0xFF7C5CFF)];
}
