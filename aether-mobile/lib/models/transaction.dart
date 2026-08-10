// lib/models/transaction.dart
class Transaction {
  final String id;
  final String date;
  final String time;
  final String side; // 'buy' | 'sell'
  final String symbol;
  final double price;
  final double amount;
  final double total;
  final String status; // 'OPEN' | 'CLOSED' | 'CANCELED' | 'TRIGGERED'
  final double? pnl; // canlı (OPEN) veya kesinleşmiş (CLOSED) kâr/zarar

  // Geçmiş/açık işlem detay sheet'i için — hepsi opsiyonel, backend'den
  // gelmeyen alanlar için UI ilgili satırı basitçe göstermez.
  final double? exitPrice;
  final double? stopLoss;
  final double? takeProfit;
  final String marketType; // 'SPOT' | 'FUTURES'
  final int? leverage;
  final String? marginMode; // 'ISOLATED' | 'CROSS'
  final double? liquidationPrice;
  final String? closedAt;

  const Transaction({
    required this.id,
    required this.date,
    required this.time,
    required this.side,
    required this.symbol,
    required this.price,
    required this.amount,
    required this.total,
    this.status = 'CLOSED',
    this.pnl,
    this.exitPrice,
    this.stopLoss,
    this.takeProfit,
    this.marketType = 'SPOT',
    this.leverage,
    this.marginMode,
    this.liquidationPrice,
    this.closedAt,
  });

  bool get isBuy => side == 'buy';
  bool get isOpen => status.toUpperCase() == 'OPEN';
  bool get isFutures => marketType.toUpperCase() == 'FUTURES';

  /// [OrderModel.pnlPercent] ile aynı mantık — bkz. oradaki açıklama.
  double? get pnlPercent {
    if (pnl == null || price == 0 || amount == 0) return null;
    final notional = price * amount;
    final costBasis =
        isFutures && (leverage ?? 1) > 1 ? notional / leverage! : notional;
    if (costBasis == 0) return null;
    return (pnl! / costBasis) * 100;
  }

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        date: json['date'] as String,
        time: json['time'] as String,
        side: json['side'] as String,
        symbol: json['symbol'] as String,
        price: (json['price'] as num).toDouble(),
        amount: (json['amount'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        status: (json['status'] as String?) ?? 'CLOSED',
        pnl: (json['pnl'] as num?)?.toDouble(),
        exitPrice: (json['exitPrice'] as num?)?.toDouble(),
        stopLoss: (json['stopLoss'] as num?)?.toDouble(),
        takeProfit: (json['takeProfit'] as num?)?.toDouble(),
        marketType: (json['marketType'] as String?) ?? 'SPOT',
        leverage: (json['leverage'] as num?)?.toInt(),
        marginMode: json['marginMode'] as String?,
        liquidationPrice: (json['liquidationPrice'] as num?)?.toDouble(),
        closedAt: json['closedAt'] as String?,
      );

  /// Bir OrderModel'i (açık ya da kapalı) Geçmiş ekranı için Transaction'a
  /// çevirir. Backend: { id, symbol, side, amount, entryPrice, exitPrice,
  /// status, currentPnL, createdAt, closedAt, marketType, leverage,
  /// marginMode, liquidationPrice }
  factory Transaction.fromOrder(dynamic order) {
    final createdAt = (order.createdAt as String?) ?? '';
    String date = '';
    String time = '';
    if (createdAt.isNotEmpty) {
      final parts = createdAt.split('T');
      date = parts.isNotEmpty ? parts[0] : createdAt;
      if (parts.length > 1) {
        time = parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
      }
    }
    final side = (order.side as String).toUpperCase() == 'BUY' ? 'buy' : 'sell';
    final price = (order.entryPrice as double?) ?? 0.0;
    final amount = (order.amount as double);
    return Transaction(
      id: order.id as String,
      date: date,
      time: time,
      side: side,
      symbol: order.symbol as String,
      price: price,
      amount: amount,
      total: amount * price,
      status: (order.status as String?) ?? 'CLOSED',
      pnl: order.currentPnL as double?,
      exitPrice: order.exitPrice as double?,
      stopLoss: order.stopLoss as double?,
      takeProfit: order.takeProfit as double?,
      marketType: (order.marketType as String?) ?? 'SPOT',
      leverage: order.leverage as int?,
      marginMode: order.marginMode as String?,
      liquidationPrice: order.liquidationPrice as double?,
      closedAt: order.closedAt as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'time': time,
        'side': side,
        'symbol': symbol,
        'price': price,
        'amount': amount,
        'total': total,
        'status': status,
        if (pnl != null) 'pnl': pnl,
        if (exitPrice != null) 'exitPrice': exitPrice,
        if (stopLoss != null) 'stopLoss': stopLoss,
        if (takeProfit != null) 'takeProfit': takeProfit,
        'marketType': marketType,
        if (leverage != null) 'leverage': leverage,
        if (marginMode != null) 'marginMode': marginMode,
        if (liquidationPrice != null) 'liquidationPrice': liquidationPrice,
        if (closedAt != null) 'closedAt': closedAt,
      };
}
