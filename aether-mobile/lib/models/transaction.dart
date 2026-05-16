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

  const Transaction({
    required this.id,
    required this.date,
    required this.time,
    required this.side,
    required this.symbol,
    required this.price,
    required this.amount,
    required this.total,
  });

  bool get isBuy => side == 'buy';

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        date: json['date'] as String,
        time: json['time'] as String,
        side: json['side'] as String,
        symbol: json['symbol'] as String,
        price: (json['price'] as num).toDouble(),
        amount: (json['amount'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'time': time,
        'side': side,
        'symbol': symbol,
        'price': price,
        'amount': amount,
        'total': total,
      };
}
