// lib/screens/add_api_key_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AddApiKeyScreen extends StatefulWidget {
  const AddApiKeyScreen({super.key});
  @override
  State<AddApiKeyScreen> createState() => _AddApiKeyState();
}

class _AddApiKeyState extends State<AddApiKeyScreen> {
  String _exchange = 'Binance';
  bool _permRead = true;
  bool _permTrade = true;
  bool _permWithdraw = false;

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
              Row(children: [
                GestureDetector(onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new, color: AppColors.text2, size: 18)),
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

              // Exchange picker
              Text('Borsa', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 0.11)),
              const SizedBox(height: 8),
              Row(children: [
                _ExchangeBox('Binance', const Color(0xFFF7A13A), _exchange == 'Binance', () => setState(() => _exchange = 'Binance')),
                const SizedBox(width: 6),
                _ExchangeBox('Bybit', const Color(0xFFF5B969), _exchange == 'Bybit', () => setState(() => _exchange = 'Bybit')),
                const SizedBox(width: 6),
                _ExchangeBox('OKX', const Color(0xFFA78BFA), _exchange == 'OKX', () => setState(() => _exchange = 'OKX')),
                const SizedBox(width: 6),
                _ExchangeBox('KuCoin', const Color(0xFF5FD49B), _exchange == 'KuCoin', () => setState(() => _exchange = 'KuCoin')),
              ]),
              const SizedBox(height: 20),

              // Keys
              _AuthField(label: 'API Key', hint: 'Borsadan kopyaladığın anahtarı yapıştır'),
              const SizedBox(height: 12),
              _AuthField(label: 'Secret Key', hint: 'Gizli anahtarı yapıştır', obscure: true),
              const SizedBox(height: 20),

              // Permissions
              Text('İzinler', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text3, letterSpacing: 0.11)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: const Color(0x07FFFFFF),
                  border: Border.all(color: AppColors.hairline, width: 0.5),
                  borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  _PermRow('Okuma', 'Bakiye ve işlem geçmişi', _permRead, (v) {}, true, false, true),
                  _PermRow('İşlem', 'Emir aç & kapat', _permTrade, (v) => setState(() => _permTrade = v), false, false, false),
                  _PermRow('Çekim', 'ÖNERİLMEZ · cüzdan dışına transfer', _permWithdraw, (v) => setState(() => _permWithdraw = v), false, true, false),
                ]),
              ),
              const SizedBox(height: 20),

              // Test status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.profitSoft,
                  border: Border.all(color: const Color(0x4D5FD49B), width: 0.5),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(
                    color: AppColors.profit, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.profit, blurRadius: 8)])),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Bağlantı testi: başarılı', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.profit))),
                  Text('~120ms', style: AppTheme.mono(fontSize: 10, color: AppColors.text3)),
                ]),
              ),
              const SizedBox(height: 24),

              // Save button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: AppColors.accentGradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x404D9FFF), blurRadius: 28, offset: Offset(0, 10))],
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text('Anahtarı Kaydet', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
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

class _ExchangeBox extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ExchangeBox(this.label, this.color, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : const Color(0x07FFFFFF),
          border: Border.all(color: selected ? color.withValues(alpha: 0.4) : AppColors.hairline, width: 0.5),
          borderRadius: BorderRadius.circular(11)),
        child: Column(children: [
          Container(width: 26, height: 26, decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(7)),
            alignment: Alignment.center,
            child: Text(label[0], style: AppTheme.mono(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, fontWeight: FontWeight.w500, color: selected ? AppColors.text1 : AppColors.text3)),
        ]),
      ),
    ));
  }
}

class _AuthField extends StatefulWidget {
  final String label;
  final String hint;
  final bool obscure;
  const _AuthField({required this.label, required this.hint, this.obscure = false});

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: GoogleFonts.spaceGrotesk(
        fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.04, color: _focused ? AppColors.accent : AppColors.text3)),
      const SizedBox(height: 6),
      AnimatedContainer(duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _focused ? const Color(0x0A4D9FFF) : const Color(0x09FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _focused ? const Color(0x884D9FFF) : AppColors.hairline, width: 0.5)),
        child: TextField(
          obscureText: widget.obscure,
          onTap: () => setState(() => _focused = true),
          onTapOutside: (_) => setState(() => _focused = false),
          style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.spaceGrotesk(fontSize: 14, color: AppColors.text4),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
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
  const _PermRow(this.label, this.sub, this.value, this.onChange, this.required, this.danger, this.isFirst);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(border: Border(top: isFirst ? BorderSide.none : const BorderSide(color: AppColors.hairline, width: 0.5))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text1)),
            if (required) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(4)),
                child: Text('ZORUNLU', style: GoogleFonts.spaceGrotesk(fontSize: 9, color: AppColors.text3, letterSpacing: 0.04))),
            ],
            if (danger) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.lossSoft, borderRadius: BorderRadius.circular(4)),
                child: Text('RİSKLİ', style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.loss, letterSpacing: 0.04))),
            ],
          ]),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
        ])),
        Switch(
          value: value,
          onChanged: required ? null : onChange,
          activeTrackColor: danger ? AppColors.loss : AppColors.accent,
          activeThumbColor: Colors.white,
          inactiveTrackColor: const Color(0x1AFFFFFF),
          inactiveThumbColor: AppColors.text3,
        ),
      ]),
    );
  }
}
