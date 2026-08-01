// lib/models/price_alarm.dart
//
// Backend /api/v1/alarms endpoint'inden dönen response'u parse eder.
// PriceAlarmResponse { id, symbol, targetPrice, direction, triggered, createdAt }

class PriceAlarmModel {
  final String id;
  final String symbol;
  final double targetPrice;
  final String direction; // "ABOVE" | "BELOW"
  final bool triggered;
  final String createdAt;

  const PriceAlarmModel({
    required this.id,
    required this.symbol,
    required this.targetPrice,
    required this.direction,
    required this.triggered,
    required this.createdAt,
  });

  factory PriceAlarmModel.fromJson(Map<String, dynamic> json) => PriceAlarmModel(
        id: (json['id'] as String?) ?? '',
        symbol: (json['symbol'] as String?) ?? '',
        targetPrice: (json['targetPrice'] as num?)?.toDouble() ?? 0,
        direction: (json['direction'] as String?) ?? 'ABOVE',
        triggered: (json['triggered'] as bool?) ?? false,
        createdAt: (json['createdAt'] as String?) ?? '',
      );
}
