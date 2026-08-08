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
  final String status;   // 'OPEN' | 'CLOSED' | 'CANCELED' | 'TRIGGERED'
  final double? pnl;      // canlı (OPEN) veya kesinleşmiş (CLOSED) kâr/zarar

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
  });

  bool get isBuy => side == 'buy';
  bool get isOpen => status.toUpperCase() == 'OPEN';

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
      );

  /// Bir OrderModel'i (açık ya da kapalı) Geçmiş ekranı için Transaction'a
  /// çevirir. Backend: { id, symbol, side, amount, entryPrice, exitPrice,
  /// status, currentPnL, createdAt }
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
      id:     order.id as String,
      date:   date,
      time:   time,
      side:   side,
      symbol: order.symbol as String,
      price:  price,
      amount: amount,
      total:  amount * price,
      status: (order.status as String?) ?? 'CLOSED',
      pnl:    order.currentPnL as double?,
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
      };
}
