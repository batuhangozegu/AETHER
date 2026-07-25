// lib/models/market.dart
//
// Matches backend CoinResponse { symbol, price, priceChangePercent }
// and CandleResponse { timestamp, open, high, low, close }

class CoinData {
  final String symbol;
  final double price;
  final double priceChangePercent;

  const CoinData({
    required this.symbol,
    required this.price,
    required this.priceChangePercent,
  });

  bool get isUp => priceChangePercent >= 0;

  factory CoinData.fromJson(Map<String, dynamic> json) => CoinData(
        symbol: (json['symbol'] as String?) ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        priceChangePercent:
            (json['priceChangePercent'] as num?)?.toDouble() ?? 0.0,
      );
}

class CandleData {
  final String timestamp; // ISO string
  final double open;
  final double high;
  final double low;
  final double close;

  const CandleData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory CandleData.fromJson(Map<String, dynamic> json) => CandleData(
        timestamp: (json['timestamp'] as String?) ?? '',
        open: (json['open'] as num?)?.toDouble() ?? 0.0,
        high: (json['high'] as num?)?.toDouble() ?? 0.0,
        low: (json['low'] as num?)?.toDouble() ?? 0.0,
        close: (json['close'] as num?)?.toDouble() ?? 0.0,
      );
}
