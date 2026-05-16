// lib/models/risk_profile.dart
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

  factory RiskProfile.fromJson(Map<String, dynamic> json) => RiskProfile(
        riskPerTrade: (json['riskPerTrade'] as num).toDouble(),
        rrRatio: (json['rrRatio'] as num).toDouble(),
        maxOpenPositions: json['maxOpenPositions'] as int,
        dailyLossCap: (json['dailyLossCap'] as num).toDouble(),
        autoStopLoss: json['autoStopLoss'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'riskPerTrade': riskPerTrade,
        'rrRatio': rrRatio,
        'maxOpenPositions': maxOpenPositions,
        'dailyLossCap': dailyLossCap,
        'autoStopLoss': autoStopLoss,
      };
}
