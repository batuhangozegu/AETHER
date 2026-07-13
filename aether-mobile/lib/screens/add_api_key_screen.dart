// lib/screens/add_api_key_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/api_keys_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

// Desteklenen borsalar (backend enum ile eşleşmeli)
const _exchanges = ['Binance', 'Bybit', 'OKX', 'BingX'];
const _exchangeEnums = {
  'Binance': 'BINANCE',
  'Bybit':   'BYBIT',
  'OKX':     'OKX',
  'BingX':   'BINGX',
};
const _exchangeColors = {
  'Binance': Color(0xFFF7A13A),
  'Bybit':   Color(0xFFF5B969),
  'OKX':     Color(0xFFA78BFA),
  'BingX':   Color(0xFF5FD49B),
};

class AddApiKeyScreen extends ConsumerStatefulWidget {
  const AddApiKeyScreen({super.key});
  @override
  ConsumerState<AddApiKeyScreen> createState() => _AddApiKeyState();
}

class _AddApiKeyState extends ConsumerState<AddApiKeyScreen> {
  String _exchange = 'Binance';
  bool _permRead   = true;
  bool _permTrade  = false;

  final _apiKeyCtrl    = TextEditingController();
  final _secretKeyCtrl = TextEditingController();

  bool _loading = false;
  bool? _testOk;  // null=idle, true=ok, false=error

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _secretKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final apiKey    = _apiKeyCtrl.text.trim();
    final secretKey = _secretKeyCtrl.text.trim();

    if (apiKey.isEmpty || secretKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key ve Secret Key boş olamaz')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ref.read(apiKeysProvider.notifier).addKey(
        exchangeName: _exchangeEnums[_exchange]!,
        apiKey:       apiKey,
        secretKey:    secretKey,
        canRead:      _permRead,
        canTrade:     _permTrade,
      );
      setState(() { _loading = false; _testOk = true; });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      String msg = 'Anahtar kaydedilemedi.';
      if (e is DioException && e.response?.data != null) {
        msg = e.response!.data.toString();
      }
      setState(() { _loading = false; _testOk = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.loss),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Başlık satırı
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new, color: AppColors.text2, size: 18),
                ),
                const SizedBox(width: 8),
                Text('API Yönetimi', style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
              ]),
              const SizedBox(height: 18),
              Text('YENİ API ANAHTARI', style: GoogleFonts.spaceGrotesk(
                  fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.11, color: AppColors.text3)),
              const SizedBox(height: 4),
              Text('Borsanı Bağla', style: GoogleFonts.spaceGrotesk(
                  fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: AppColors.text1)),
              const SizedBox(height: 24),

              // Borsa seçici
              Text('Borsa', style: GoogleFonts.spaceGrotesk(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 0.11)),
              const SizedBox(height: 8),
              Row(children: _exchanges.map((ex) {
                final color = _exchangeColors[ex]!;
                final sel   = _exchange == ex;
                return Expanded(child: Padding(
                  padding: EdgeInsets.only(right: ex != _exchanges.last ? 6 : 0),
                  child: _ExchangeBox(
                    label: ex, color: color, selected: sel,
                    onTap: () => setState(() => _exchange = ex),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 20),

              // Alanlar
              _AuthField(label: 'API Key', hint: 'Borsadan kopyaladığın anahtarı yapıştır',
                  controller: _apiKeyCtrl),
              const SizedBox(height: 12),
              _AuthField(label: 'Secret Key', hint: 'Gizli anahtarı yapıştır',
                  obscure: true, controller: _secretKeyCtrl),
              const SizedBox(height: 20),

              // İzinler
              Text('İzinler', style: GoogleFonts.spaceGrotesk(
                  fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 0.11)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x07FFFFFF),
                  border: Border.all(color: AppColors.hairline, width: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  _PermRow('Okuma',  'Bakiye ve işlem geçmişi', _permRead,
                      (_) {}, true, false, true),
                  _PermRow('İşlem',  'Emir aç & kapat', _permTrade,
                      (v) => setState(() => _permTrade = v), false, false, false),
                ]),
              ),
              const SizedBox(height: 20),

              // Durum göstergesi
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _testOk == null
                    ? const SizedBox.shrink()
                    : _testOk == true
                        ? _StatusRow(ok: true,  text: 'Anahtar başarıyla kaydedildi')
                        : _StatusRow(ok: false, text: 'Kayıt başarısız'),
              ),
              if (_testOk != null) const SizedBox(height: 20),

              // Kaydet butonu
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: AppColors.accentGradient,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x404D9FFF), blurRadius: 28, offset: Offset(0, 10)),
                  ],
                ),
                child: TextButton(
                  onPressed: _loading ? null : _save,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Anahtarı Kaydet', style: GoogleFonts.spaceGrotesk(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 44),
            ]),
          )),
        ],
      ),
    );
  }
}

// ── Alt widget'lar ──────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final bool ok;
  final String text;
  const _StatusRow({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.profit : AppColors.loss;
    final bg    = ok ? AppColors.profitSoft : AppColors.lossSoft;
    final border= ok ? const Color(0x4D5FD49B) : const Color(0x4DF08080);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color, blurRadius: 8)])),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.spaceGrotesk(
            fontSize: 12, fontWeight: FontWeight.w500, color: color))),
      ]),
    );
  }
}

class _ExchangeBox extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ExchangeBox(
      {required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:  selected ? color.withValues(alpha: 0.1) : const Color(0x07FFFFFF),
          border: Border.all(
              color: selected ? color.withValues(alpha: 0.4) : AppColors.hairline, width: 0.5),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(7)),
            alignment: Alignment.center,
            child: Text(label[0],
                style: AppTheme.mono(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.spaceGrotesk(
              fontSize: 10.5, fontWeight: FontWeight.w500,
              color: selected ? AppColors.text1 : AppColors.text3)),
        ]),
      ),
    );
  }
}

class _AuthField extends StatefulWidget {
  final String label;
  final String hint;
  final bool obscure;
  final TextEditingController controller;
  const _AuthField(
      {required this.label, required this.hint, this.obscure = false, required this.controller});

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: GoogleFonts.spaceGrotesk(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.04,
          color: _focused ? AppColors.accent : AppColors.text3)),
      const SizedBox(height: 6),
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _focused ? const Color(0x0A4D9FFF) : const Color(0x09FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _focused ? const Color(0x884D9FFF) : AppColors.hairline, width: 0.5),
        ),
        child: TextField(
          controller:  widget.controller,
          obscureText: widget.obscure,
          onTap:       () => setState(() => _focused = true),
          onTapOutside: (_) => setState(() => _focused = false),
          style: GoogleFonts.spaceGrotesk(
              fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1),
          decoration: InputDecoration(
            hintText:        widget.hint,
            hintStyle:       GoogleFonts.spaceGrotesk(fontSize: 14, color: AppColors.text4),
            border:          InputBorder.none,
            contentPadding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense:         true,
          ),
        ),
      ),
    ]);
  }
}

class _PermRow extends StatelessWidget {
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChange;
  final bool required, danger, isFirst;
  const _PermRow(
      this.label, this.sub, this.value, this.onChange, this.required, this.danger, this.isFirst);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
            top: isFirst
                ? BorderSide.none
                : const BorderSide(color: AppColors.hairline, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(label, style: GoogleFonts.spaceGrotesk(
                fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text1)),
            if (required) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(4)),
                child: Text('ZORUNLU', style: GoogleFonts.spaceGrotesk(
                    fontSize: 9, color: AppColors.text3, letterSpacing: 0.04)),
              ),
            ],
            if (danger) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: AppColors.lossSoft, borderRadius: BorderRadius.circular(4)),
                child: Text('RİSKLİ', style: GoogleFonts.spaceGrotesk(
                    fontSize: 9, fontWeight: FontWeight.w600,
                    color: AppColors.loss, letterSpacing: 0.04)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
        ])),
        Switch(
          value:              value,
          onChanged:          required ? null : onChange,
          activeTrackColor:   danger ? AppColors.loss : AppColors.accent,
          activeThumbColor:   Colors.white,
          inactiveTrackColor: const Color(0x1AFFFFFF),
          inactiveThumbColor: AppColors.text3,
        ),
      ]),
    );
  }
}
