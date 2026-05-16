// lib/models/order_request.dart
class OrderRequest {
  final String symbol;
  final String side; // 'buy' | 'sell'
  final double entryPrice;
  final double stopLoss;
  final double quantity;
  final String type; // 'limit' | 'market'

  const OrderRequest({
    required this.symbol,
    required this.side,
    required this.entryPrice,
    required this.stopLoss,
    required this.quantity,
    this.type = 'limit',
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'side': side,
        'entryPrice': entryPrice,
        'stopLoss': stopLoss,
        'quantity': quantity,
        'type': type,
      };
}

class User {
  final String id;
  final String name;
  final String email;
  final String initials;
  final bool kycVerified;
  final double totalBalance;
  final double pnlPercent;
  final bool twoFAEnabled;
  final bool biometricEnabled;
  final bool priceAlerts;
  final bool riskAlerts;
  final String currency;
  final String language;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.initials,
    this.kycVerified = false,
    this.totalBalance = 0,
    this.pnlPercent = 0,
    this.twoFAEnabled = true,
    this.biometricEnabled = true,
    this.priceAlerts = true,
    this.riskAlerts = true,
    this.currency = 'USD',
    this.language = 'Türkçe',
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        initials: json['initials'] as String,
        kycVerified: json['kycVerified'] as bool? ?? false,
        totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0,
        pnlPercent: (json['pnlPercent'] as num?)?.toDouble() ?? 0,
        twoFAEnabled: json['twoFAEnabled'] as bool? ?? true,
        biometricEnabled: json['biometricEnabled'] as bool? ?? true,
        priceAlerts: json['priceAlerts'] as bool? ?? true,
        riskAlerts: json['riskAlerts'] as bool? ?? true,
        currency: json['currency'] as String? ?? 'USD',
        language: json['language'] as String? ?? 'Türkçe',
      );
}
