// lib/screens/risk_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../models/risk_profile.dart';
import '../services/api_service.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

// ── Providers ──────────────────────────────────────────────────────────
class RiskNotifier extends StateNotifier<RiskProfile> {
  final ApiService _api;
  RiskNotifier(this._api) : super(const RiskProfile());

  Future<void> load() async {
    try {
      state = await _api.getRiskProfile();
    } catch (_) {
      // fallback to defaults on error
    }
  }

  void setRiskPerTrade(double v) => state = state.copyWith(riskPerTrade: v);
  void setRrRatio(double v) => state = state.copyWith(rrRatio: v);
  void setMaxOpen(int v) => state = state.copyWith(maxOpenPositions: v);
  void setDailyLossCap(double v) => state = state.copyWith(dailyLossCap: v);
  void setAutoStop(bool v) => state = state.copyWith(autoStopLoss: v);

  Future<void> save() async {
    state = await _api.saveRiskProfile(state);
  }
}

final riskProvider = StateNotifierProvider<RiskNotifier, RiskProfile>((ref) {
  final notifier = RiskNotifier(ref.watch(apiServiceProvider));
  notifier.load();
  return notifier;
});

// ── Risk Calculation Provider ──────────────────────────────────────────
class RiskCalcNotifier extends StateNotifier<AsyncValue<RiskCalculationResult?>> {
  final ApiService _api;
  RiskCalcNotifier(this._api) : super(const AsyncData(null));

  Future<void> calculate(RiskCalculationPayload payload) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.calculateRisk(payload));
  }

  void reset() => state = const AsyncData(null);
}

final riskCalcProvider =
    StateNotifierProvider<RiskCalcNotifier, AsyncValue<RiskCalculationResult?>>(
  (ref) => RiskCalcNotifier(ref.watch(apiServiceProvider)),
);

// ── Screen ─────────────────────────────────────────────────────────────
class RiskScreen extends ConsumerWidget {
  const RiskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(riskProvider);
    final notifier = ref.read(riskProvider.notifier);

    const accountBalance = 84273.52;
    final riskUSD = accountBalance * profile.riskPerTrade / 100;
    final targetUSD = riskUSD * profile.rrRatio;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RİSK PROFİLİ',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.11,
                        color: AppColors.text3,
                      )),
                  const SizedBox(height: 4),
                  Text('Sermayeni koru.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: AppColors.text1,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    'Bu kurallar her işlemde otomatik olarak uygulanır.\nİdeal alım miktarı bu profile göre hesaplanır.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: AppColors.text3,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary preview
                  AccentCard(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_outlined,
                              color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kasanın %${profile.riskPerTrade.toStringAsFixed(1)}\'i',
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11, color: AppColors.text3),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '−${Formatters.moneyCompact(riskUSD)}',
                                    style: AppTheme.mono(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.loss),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text('→',
                                        style: AppTheme.mono(
                                            fontSize: 14,
                                            color: AppColors.text3)),
                                  ),
                                  Text(
                                    '+${Formatters.moneyCompact(targetUSD)}',
                                    style: AppTheme.mono(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.profit),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '1:${profile.rrRatio.toStringAsFixed(1)}',
                            style: AppTheme.mono(
                                fontSize: 11, color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sliders
                  _RiskSlider(
                    label: 'İşlem Başına Maks. Risk',
                    value: profile.riskPerTrade,
                    displayValue: '${profile.riskPerTrade.toStringAsFixed(1)}%',
                    min: 0.5,
                    max: 5,
                    divisions: 45,
                    helperLeft: 'Güvenli %0.5',
                    helperRight: 'Agresif %5',
                    accentColor: AppColors.accent,
                    onChanged: notifier.setRiskPerTrade,
                  ),
                  const SizedBox(height: 10),

                  _RiskSlider(
                    label: 'Risk / Ödül Oranı',
                    value: profile.rrRatio,
                    displayValue: '1:${profile.rrRatio.toStringAsFixed(1)}',
                    min: 1,
                    max: 5,
                    divisions: 40,
                    helperLeft: '1:1',
                    helperRight: '1:5',
                    accentColor: AppColors.profit,
                    onChanged: notifier.setRrRatio,
                  ),
                  const SizedBox(height: 10),

                  _RiskSlider(
                    label: 'Eş Zamanlı Maks. Pozisyon',
                    value: profile.maxOpenPositions.toDouble(),
                    displayValue: '${profile.maxOpenPositions}',
                    min: 1,
                    max: 10,
                    divisions: 9,
                    helperLeft: '1 işlem',
                    helperRight: '10 işlem',
                    accentColor: AppColors.text1,
                    onChanged: (v) => notifier.setMaxOpen(v.round()),
                  ),
                  const SizedBox(height: 10),

                  _RiskSlider(
                    label: 'Günlük Zarar Tavanı',
                    value: profile.dailyLossCap,
                    displayValue:
                        '${profile.dailyLossCap.toStringAsFixed(0)}%',
                    min: 2,
                    max: 20,
                    divisions: 18,
                    helperLeft: 'Sıkı %2',
                    helperRight: 'Esnek %20',
                    accentColor: AppColors.loss,
                    onChanged: notifier.setDailyLossCap,
                  ),
                  const SizedBox(height: 10),

                  // Auto stop toggle
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Otomatik Zarar Kes',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.text1,
                                    )),
                                const SizedBox(height: 2),
                                Text('Her emirde stop-loss zorunlu',
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11,
                                        color: AppColors.text3)),
                              ],
                            ),
                          ),
                          Switch(
                            value: profile.autoStopLoss,
                            onChanged: notifier.setAutoStop,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.accent,
                            inactiveThumbColor: AppColors.text3,
                            inactiveTrackColor: AppColors.surface3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Risk Calculator ──────────────────────────────────
                  _RiskCalculatorCard(profile: profile),
                  const SizedBox(height: 20),

                  // Save button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.accent, Color(0xFF2B78D9)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x404D9FFF),
                          blurRadius: 28,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () async {
                        try {
                          await notifier.save();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        color: AppColors.profit, size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Risk profili kaydedildi.',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF1A2040),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                      color: AppColors.hairline, width: 0.5),
                                ),
                                margin:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Kayıt başarısız: $e'),
                                backgroundColor: AppColors.loss,
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Profili Kaydet',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => notifier.load(),
                      child: Text('Varsayılana sıfırla',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 12, color: AppColors.text3)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Risk Calculator Card ───────────────────────────────────────────────
class _RiskCalculatorCard extends ConsumerStatefulWidget {
  final RiskProfile profile;
  const _RiskCalculatorCard({required this.profile});

  @override
  ConsumerState<_RiskCalculatorCard> createState() =>
      _RiskCalculatorCardState();
}

class _RiskCalculatorCardState extends ConsumerState<_RiskCalculatorCard> {
  final _symbolCtrl = TextEditingController(text: 'BTCUSDT');
  final _entryCtrl = TextEditingController(text: '67234');
  final _stopCtrl = TextEditingController(text: '65800');
  final _balanceCtrl = TextEditingController(text: '84273');

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _entryCtrl.dispose();
    _stopCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final entry = double.tryParse(_entryCtrl.text);
    final stop = double.tryParse(_stopCtrl.text);
    final balance = double.tryParse(_balanceCtrl.text);
    final symbol = _symbolCtrl.text.trim();

    if (entry == null || stop == null || balance == null || symbol.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    await ref.read(riskCalcProvider.notifier).calculate(
          RiskCalculationPayload(
            symbol: symbol,
            entryPrice: entry,
            stopLossPrice: stop,
            accountBalance: balance,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final calcAsync = ref.watch(riskCalcProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calculate_outlined,
                    color: AppColors.accent, size: 16),
              ),
              const SizedBox(width: 10),
              Text('RİSK HESAPLAYICI',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1,
                    letterSpacing: 0.05,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _CalcField(
                      label: 'Sembol',
                      controller: _symbolCtrl,
                      hint: 'BTCUSDT')),
              const SizedBox(width: 8),
              Expanded(
                  child: _CalcField(
                      label: 'Bakiye (\$)',
                      controller: _balanceCtrl,
                      hint: '84273',
                      isNum: true)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _CalcField(
                      label: 'Giriş Fiyatı',
                      controller: _entryCtrl,
                      hint: '67234',
                      isNum: true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _CalcField(
                      label: 'Stop Fiyatı',
                      controller: _stopCtrl,
                      hint: '65800',
                      isNum: true)),
            ],
          ),
          const SizedBox(height: 12),

          // Result area
          calcAsync.when(
            data: (result) {
              if (result == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.hairlineAccent, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CalcResultItem(
                        label: 'ÖNERİLEN MİKTAR',
                        value: result.suggestedAmount.toStringAsFixed(4),
                        color: AppColors.accent),
                    _CalcResultItem(
                        label: 'RİSK (\$)',
                        value:
                            Formatters.moneyCompact(result.riskAmountUsd),
                        color: AppColors.loss),
                    _CalcResultItem(
                        label: 'RİSK %',
                        value:
                            '${result.riskPercentage.toStringAsFixed(2)}%',
                        color: AppColors.text1),
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2))),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Hata: $e',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 11, color: AppColors.loss)),
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _calculate,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accentSoft,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(
                      color: AppColors.hairlineAccent, width: 0.5),
                ),
              ),
              child: Text('Hesapla',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool isNum;
  const _CalcField(
      {required this.label,
      required this.controller,
      required this.hint,
      this.isNum = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                color: AppColors.text3,
                letterSpacing: 0.04)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppColors.hairline, width: 0.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNum
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: AppTheme.mono(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  AppTheme.mono(fontSize: 13, color: AppColors.text4),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _CalcResultItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CalcResultItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 9, color: AppColors.text3, letterSpacing: 0.04)),
        const SizedBox(height: 3),
        Text(value,
            style: AppTheme.mono(
                fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ── Slider widget ──────────────────────────────────────────────────────
class _RiskSlider extends StatelessWidget {
  final String label, displayValue, helperLeft, helperRight;
  final double value, min, max;
  final int divisions;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _RiskSlider({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.helperLeft,
    required this.helperRight,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(label,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text1)),
              Text(displayValue,
                  style: AppTheme.mono(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: accentColor,
                      letterSpacing: -0.5)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: AppColors.surface3,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(helperLeft,
                  style: AppTheme.mono(fontSize: 10, color: AppColors.text3)),
              Text(helperRight,
                  style: AppTheme.mono(fontSize: 10, color: AppColors.text3)),
            ],
          ),
        ],
      ),
    );
  }
}
