// lib/models/exchange_key.dart
//
// Backend /api/v1/exchanges endpoint'inden dönen response'u parse eder.
// ExchangeKeyResponse { id, exchangeName, maskedApiKey, canRead, canTrade, status }

class ExchangeKeyModel {
  final String id;           // UUID string
  final String exchangeName; // "BINANCE" | "BYBIT" | "OKX" | "BINGX"
  final String maskedApiKey;
  final bool canRead;
  final bool canTrade;
  final String status;       // "ACTIVE"

  const ExchangeKeyModel({
    required this.id,
    required this.exchangeName,
    required this.maskedApiKey,
    required this.canRead,
    required this.canTrade,
    required this.status,
  });

  factory ExchangeKeyModel.fromJson(Map<String, dynamic> json) {
    return ExchangeKeyModel(
      id:           (json['id'] as String?) ?? '',
      exchangeName: (json['exchangeName'] as String?) ?? '',
      maskedApiKey: (json['maskedApiKey'] as String?) ?? '',
      canRead:      (json['canRead'] as bool?) ?? false,
      canTrade:     (json['canTrade'] as bool?) ?? false,
      status:       (json['status'] as String?) ?? '',
    );
  }

  /// UI'da gösterilecek kısa borsa adı (enum → okunabilir)
  String get displayName {
    switch (exchangeName.toUpperCase()) {
      case 'BINANCE': return 'Binance';
      case 'BYBIT':   return 'Bybit';
      case 'OKX':     return 'OKX';
      case 'BINGX':   return 'BingX';
      default:        return exchangeName;
    }
  }
}
