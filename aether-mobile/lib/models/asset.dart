// lib/models/asset.dart
class Asset {
  final String symbol;
  final String name;
  final double amount;
  final double avgPrice;
  final double currentPrice;
  final List<double> sparkline;

  const Asset({
    required this.symbol,
    required this.name,
    required this.amount,
    required this.avgPrice,
    required this.currentPrice,
    required this.sparkline,
  });

  double get value => amount * currentPrice;
  double get cost => amount * avgPrice;
  double get pnl => value - cost;
  double get pnlPercent => cost > 0 ? (pnl / cost) * 100 : 0;
  bool get isProfit => pnl >= 0;

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        avgPrice: (json['avgPrice'] as num).toDouble(),
        currentPrice: (json['currentPrice'] as num).toDouble(),
        sparkline: (json['sparkline'] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'amount': amount,
        'avgPrice': avgPrice,
        'currentPrice': currentPrice,
        'sparkline': sparkline,
      };
}

class Portfolio {
  final double balance;
  final double pnl24h;
  final double pnl24hPercent;

  const Portfolio({
    required this.balance,
    required this.pnl24h,
    required this.pnl24hPercent,
  });

  /// Backend: { totalBalanceUsd, dailyPnlUsd, dailyPnlPct }
  factory Portfolio.fromBackend(Map<String, dynamic> json) => Portfolio(
        balance: (json['totalBalanceUsd'] as num).toDouble(),
        pnl24h: (json['dailyPnlUsd'] as num).toDouble(),
        pnl24hPercent: (json['dailyPnlPct'] as num).toDouble(),
      );
}

// ── AssetAllocation ─────────────────────────────────────────────────────
/// Backend: GET /api/v1/portfolio/breakdown?exchangeKeyId=
/// { symbol, amount, usdValue, allocationPct }
class AssetAllocation {
  final String symbol;
  final double amount;
  final double usdValue;
  final double allocationPct;

  const AssetAllocation({
    required this.symbol,
    required this.amount,
    required this.usdValue,
    required this.allocationPct,
  });

  factory AssetAllocation.fromJson(Map<String, dynamic> json) => AssetAllocation(
        symbol:        json['symbol'] as String,
        amount:        (json['amount'] as num).toDouble(),
        usdValue:      (json['usdValue'] as num).toDouble(),
        allocationPct: (json['allocationPct'] as num).toDouble(),
      );
}
