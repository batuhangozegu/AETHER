import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../providers/api_keys_provider.dart';

/// API anahtarını düzenleme dialogu — backend PUT /exchanges/{id} hem apiKey
/// hem secretKey'i yeniden ister (mevcutlar decrypt edilip geri gösterilmiyor).
Future<void> showApiKeyDialog(
  BuildContext context, {
  required ApiKey existing,
  required Future<void> Function(String apiKey, String secretKey, bool canRead, bool canTrade) onSave,
}) async {
  final keyCtrl = TextEditingController(text: '');
  final secretCtrl = TextEditingController(text: '');
  bool canRead = existing.canRead;
  bool canTrade = existing.canTrade;
  bool saving = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
      backgroundColor: const Color(0xFF111828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.hairline, width: 0.5),
      ),
      title: Text('${existing.exchange} Anahtarını Düzenle',
          style: GoogleFonts.spaceGrotesk(color: AppColors.text1, fontWeight: FontWeight.w600)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _Field(controller: keyCtrl, label: 'Yeni API Anahtarı', hint: 'sk-…', obscure: true),
        const SizedBox(height: 12),
        _Field(controller: secretCtrl, label: 'Yeni Secret Anahtarı', hint: '••••••••', obscure: true),
        const SizedBox(height: 12),
        Row(children: [
          Checkbox(value: canRead, onChanged: (v) => setState(() => canRead = v ?? canRead)),
          Text('Okuma', style: GoogleFonts.spaceGrotesk(color: AppColors.text2, fontSize: 12)),
          const SizedBox(width: 12),
          Checkbox(value: canTrade, onChanged: (v) => setState(() => canTrade = v ?? canTrade)),
          Text('İşlem', style: GoogleFonts.spaceGrotesk(color: AppColors.text2, fontSize: 12)),
        ]),
      ]),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(ctx),
          child: Text('İptal', style: GoogleFonts.spaceGrotesk(color: AppColors.text3)),
        ),
        TextButton(
          onPressed: saving ? null : () async {
            if (keyCtrl.text.trim().isEmpty || secretCtrl.text.trim().isEmpty) return;
            setState(() => saving = true);
            try {
              await onSave(keyCtrl.text.trim(), secretCtrl.text.trim(), canRead, canTrade);
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (_) {
              setState(() => saving = false);
            }
          },
          child: saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
              : Text('Kaydet', style: GoogleFonts.spaceGrotesk(color: AppColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    )),
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
