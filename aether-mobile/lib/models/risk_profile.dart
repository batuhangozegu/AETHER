// lib/models/risk_profile.dart
//
// Flutter-side field adları: riskPerTrade, rrRatio, maxOpenPositions, dailyLossCap, autoStopLoss
// Backend JSON key adları  : riskPerTradePct, targetRr, maxOpenPositions, dailyLossCapPct, autoStopLossEnabled
class RiskProfile {
  final double riskPerTrade;   // %0.5 – %5
  final double rrRatio;        // 1:1 – 1:5
  final int maxOpenPositions;  // 1 – 10
  final double dailyLossCap;   // %2 – %20
  final bool autoStopLoss;

  const RiskProfile({
    this.riskPerTrade = 2.0,
    this.rrRatio = 2.5,
    this.maxOpenPositions = 4,
    this.dailyLossCap = 5.0,
    this.autoStopLoss = true,
  });

  RiskProfile copyWith({
    double? riskPerTrade,
    double? rrRatio,
    int? maxOpenPositions,
    double? dailyLossCap,
    bool? autoStopLoss,
  }) =>
      RiskProfile(
        riskPerTrade: riskPerTrade ?? this.riskPerTrade,
        rrRatio: rrRatio ?? this.rrRatio,
        maxOpenPositions: maxOpenPositions ?? this.maxOpenPositions,
        dailyLossCap: dailyLossCap ?? this.dailyLossCap,
        autoStopLoss: autoStopLoss ?? this.autoStopLoss,
      );

  /// Backend'den gelen JSON (GET /api/v1/risk/profile):
  /// { riskPerTradePct, targetRr, dailyLossCapPct, autoStopLossEnabled, maxOpenPositions }
  factory RiskProfile.fromJson(Map<String, dynamic> json) => RiskProfile(
        riskPerTrade: (json['riskPerTradePct'] as num).toDouble(),
        rrRatio: (json['targetRr'] as num).toDouble(),
        maxOpenPositions: (json['maxOpenPositions'] as int?) ?? 4,
        dailyLossCap: (json['dailyLossCapPct'] as num).toDouble(),
        autoStopLoss: (json['autoStopLossEnabled'] as bool?) ?? false,
      );

  /// Backend'e gönderilecek JSON (PUT /api/v1/risk/profile):
  /// { riskPerTradePct, dailyLossCapPct, targetRr, autoStopLossEnabled, maxOpenPositions }
  Map<String, dynamic> toJson() => {
        'riskPerTradePct': riskPerTrade,
        'dailyLossCapPct': dailyLossCap,
        'targetRr': rrRatio,
        'autoStopLossEnabled': autoStopLoss,
        'maxOpenPositions': maxOpenPositions,
      };
}
