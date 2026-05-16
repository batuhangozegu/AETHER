import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../providers/api_keys_provider.dart';

/// API anahtarı ekle / düzenle dialogu
Future<void> showApiKeyDialog(
  BuildContext context, {
  ApiKey? existing,
  required void Function(String exchange, String mask) onSave,
}) async {
  final exchCtrl = TextEditingController(text: existing?.exchange ?? '');
  final keyCtrl = TextEditingController(text: '');

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF111828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.hairline, width: 0.5),
      ),
      title: Text(existing == null ? 'API Anahtarı Ekle' : 'Anahtarı Düzenle',
          style: GoogleFonts.spaceGrotesk(color: AppColors.text1, fontWeight: FontWeight.w600)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _Field(controller: exchCtrl, label: 'Borsa adı', hint: 'Binance, Bybit…'),
        const SizedBox(height: 12),
        _Field(controller: keyCtrl, label: existing == null ? 'API Anahtarı' : 'Yeni API Anahtarı (boş bırak = değiştirme)', hint: 'sk-…', obscure: true),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('İptal', style: GoogleFonts.spaceGrotesk(color: AppColors.text3)),
        ),
        TextButton(
          onPressed: () {
            if (exchCtrl.text.isEmpty) return;
            final rawKey = keyCtrl.text.trim();
            final mask = rawKey.length >= 4
                ? '****${rawKey.substring(rawKey.length - 4)}'
                : (existing?.mask ?? '****0000');
            onSave(exchCtrl.text.trim(), mask);
            Navigator.pop(ctx);
          },
          child: Text('Kaydet', style: GoogleFonts.spaceGrotesk(color: AppColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

/// Profil adı / e-posta düzenleme bottom sheet
Future<Map<String, String>?> showProfileEditSheet(
  BuildContext context, {
  required String name,
  required String email,
}) async {
  final nameCtrl = TextEditingController(text: name);
  final mailCtrl = TextEditingController(text: email);

  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111828),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('Profili Düzenle', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text1)),
        const SizedBox(height: 6),
        Text('Değişiklikler backend bağlandığında kaydedilecek.',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppColors.text3)),
        const SizedBox(height: 20),
        _Field(controller: nameCtrl, label: 'Ad Soyad', hint: 'John Doe'),
        const SizedBox(height: 12),
        _Field(controller: mailCtrl, label: 'E-posta', hint: 'john@example.com'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.pop(ctx, {'name': nameCtrl.text, 'email': mailCtrl.text}),
            child: Text('Kaydet', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ]),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final bool obscure;
  const _Field({required this.controller, required this.label, required this.hint, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.text3)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: obscure,
        style: AppTheme.mono(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.mono(fontSize: 14, color: AppColors.text4),
          filled: true,
          fillColor: AppColors.surface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.hairline, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.hairline, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
        ),
      ),
    ]);
  }
}
