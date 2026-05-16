// lib/utils/formatters.dart

class Formatters {
  Formatters._();

  /// Para birimi formatı: 84273.52 → "$84,273.52"
  static String money(double value, {int decimals = 2}) {
    final isNegative = value < 0;
    final abs = value.abs();
    final parts = abs.toStringAsFixed(decimals).split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';

    // Binlik ayraç
    final buf = StringBuffer();
    final chars = intPart.split('').reversed.toList();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(',');
      buf.write(chars[i]);
    }
    final formatted = buf.toString().split('').reversed.join();

    return '${isNegative ? '-' : ''}\$$formatted.$decPart';
  }

  /// Küçük para: 840.43 → "$840.43"
  static String moneyCompact(double value) => money(value, decimals: 0);

  /// Yüzde: 2.23 → "+2.23%"
  static String percent(double value, {bool showSign = true}) {
    final sign = showSign ? (value >= 0 ? '+' : '') : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  /// Coin miktarı: 0.4827 → "0.4827"
  static String coinAmount(double value) {
    if (value >= 100) return value.toStringAsFixed(2);
    if (value >= 1) return value.toStringAsFixed(4);
    return value.toStringAsFixed(6);
  }

  /// Fiyat: 67234.12 → "67,234.12"
  static String price(double value) {
    return money(value).replaceFirst('\$', '');
  }
}
