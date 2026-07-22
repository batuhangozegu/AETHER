// lib/models/order.dart
//
// Backend OrderResponse: { id, symbol, side, amount, status, currentPnL, createdAt, closedAt }
// Backend enums: TradeSide { BUY, SELL } — OrderStatus { OPEN, CLOSED, CANCELED, TRIGGERED }

class OrderModel {
  final String id;           // UUID string
  final String symbol;       // e.g. "BTCUSDT"
  final String side;         // "BUY" | "SELL"
  final double amount;
  final String status;       // "OPEN" | "CLOSED" | "CANCELED" | "TRIGGERED"
  final double? currentPnL;  // nullable — backend live hesaplıyor
  final String? createdAt;
  final String? closedAt;

  const OrderModel({
    required this.id,
    required this.symbol,
    required this.side,
    required this.amount,
    required this.status,
    this.currentPnL,
    this.createdAt,
    this.closedAt,
  });

  bool get isBuy => side.toUpperCase() == 'BUY';
  bool get isOpen => status.toUpperCase() == 'OPEN';
  bool get isProfit => (currentPnL ?? 0) >= 0;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: (json['id'] as String?) ?? '',
        symbol: (json['symbol'] as String?) ?? '',
        side: (json['side'] as String?) ?? 'BUY',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: (json['status'] as String?) ?? 'OPEN',
        currentPnL: (json['currentPnL'] as num?)?.toDouble(),
        createdAt: (json['createdAt'] as String?),
        closedAt: (json['closedAt'] as String?),
      );
}

/// POST /api/v1/trades/order request body
class CreateOrderPayload {
  final String exchangeKeyId;
  final String symbol;
  final String side;   // "BUY" | "SELL"
  final String type;   // "LIMIT" | "MARKET"
  final double amount;
  final double entryPrice;
  final double? stopLoss;
  final double? takeProfit;

  const CreateOrderPayload({
    required this.exchangeKeyId,
    required this.symbol,
    required this.side,
    required this.type,
    required this.amount,
    required this.entryPrice,
    this.stopLoss,
    this.takeProfit,
  });

  Map<String, dynamic> toJson() => {
        'exchangeKeyId': exchangeKeyId,
        'symbol': symbol,
        'side': side,
        'type': type,
        'amount': amount,
        'entryPrice': entryPrice,
        if (stopLoss != null) 'stopLoss': stopLoss,
        if (takeProfit != null) 'takeProfit': takeProfit,
      };
}

/// POST /api/v1/risk/calculate request body
class RiskCalculationPayload {
  final String symbol;
  final double entryPrice;
  final double stopLossPrice;
  final double accountBalance;

  const RiskCalculationPayload({
    required this.symbol,
    required this.entryPrice,
    required this.stopLossPrice,
    required this.accountBalance,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'entryPrice': entryPrice,
        'stopLossPrice': stopLossPrice,
        'accountBalance': accountBalance,
      };
}

/// POST /api/v1/risk/calculate response
class RiskCalculationResult {
  final double suggestedAmount;
  final double riskAmountUsd;
  final double riskPercentage;

  const RiskCalculationResult({
    required this.suggestedAmount,
    required this.riskAmountUsd,
    required this.riskPercentage,
  });

  factory RiskCalculationResult.fromJson(Map<String, dynamic> json) =>
      RiskCalculationResult(
        suggestedAmount: (json['suggestedAmount'] as num).toDouble(),
        riskAmountUsd: (json['riskAmountUsd'] as num).toDouble(),
        riskPercentage: (json['riskPercentage'] as num).toDouble(),
      );
}
