// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class _Notif {
  final String id, group, title, sub, kind;
  const _Notif({required this.id, required this.group, required this.kind, required this.title, required this.sub});
}

const _kNotifs = [
  _Notif(id:'n1', group:'Bugün',    kind:'alert',    title:'BTC \$70,000 üzerine çıktı',            sub:'14:32 · Fiyat alarmın tetiklendi'),
  _Notif(id:'n2', group:'Bugün',    kind:'loss',     title:'Stop-loss tetiklendi',                  sub:'14:31 · AVAX pozisyonun otomatik kapatıldı'),
  _Notif(id:'n3', group:'Bugün',    kind:'success',  title:'API senkronizasyonu tamamlandı',        sub:'11:08 · Binance pozisyonları güncellendi'),
  _Notif(id:'n4', group:'Dün',      kind:'security', title:'Yeni cihazdan giriş',                   sub:'iPhone 16 Pro · İstanbul'),
  _Notif(id:'n5', group:'Dün',      kind:'info',     title:'KYC seviyen yükseltildi',               sub:'Artık günlük limit yok'),
  _Notif(id:'n6', group:'Bu Hafta', kind:'alert',    title:'ETH \$3,100 altına düştü',              sub:'12 May · Fiyat alarmın tetiklendi'),
  _Notif(id:'n7', group:'Bu Hafta', kind:'info',     title:'Risk profilin güncellendi',             sub:'%1.5 → %2.0 · senin tarafından'),
];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'all';

  Map<String, List<_Notif>> get _groups {
    final filtered = _kNotifs.where((n) {
      if (_filter == 'all') return true;
      if (_filter == 'alarms') return n.kind == 'alert';
      if (_filter == 'security') return n.kind == 'security';
      if (_filter == 'trades') return n.kind == 'loss' || n.kind == 'success';
      return true;
    }).toList();
    final map = <String, List<_Notif>>{};
    for (final n in filtered) (map[n.group] ??= []).add(n);
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 60, 22, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, color: AppColors.text2, size: 18)),
              const SizedBox(width: 8),
              Text('Bildirimler', style: GoogleFonts.spaceGrotesk(
                fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: AppColors.text1)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(5)),
                child: Text('3 YENİ', style: AppTheme.mono(fontSize: 11, color: AppColors.accent))),
              const Spacer(),
              TextButton(onPressed: () {}, child: Text('Tümünü oku',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text3))),
            ]),
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              for (final f in [
                ('all', 'Hepsi'), ('alarms', 'Alarmlar'), ('security', 'Güvenlik'), ('trades', 'İşlemler')
              ]) ...[
                GestureDetector(onTap: () => setState(() => _filter = f.$1),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: _filter == f.$1 ? AppColors.accentSoft : const Color(0x0AFFFFFF),
                      border: Border.all(
                        color: _filter == f.$1 ? AppColors.hairlineAccent : AppColors.hairline, width: 0.5),
                      borderRadius: BorderRadius.circular(999)),
                    child: Text(f.$2, style: GoogleFonts.spaceGrotesk(
                      fontSize: 11.5, fontWeight: FontWeight.w500,
                      color: _filter == f.$1 ? AppColors.accent : AppColors.text2)))),
                const SizedBox(width: 6),
              ],
            ])),
            const SizedBox(height: 6),
          ]),
        )),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 44),
          sliver: SliverList(delegate: SliverChildListDelegate([
            for (final entry in groups.entries) ...[
              Padding(padding: const EdgeInsets.fromLTRB(4, 0, 0, 6),
                child: Text(entry.key, style: GoogleFonts.spaceGrotesk(
                  fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.08,
                  color: AppColors.text3))),
              Container(margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0x07FFFFFF),
                  border: Border.all(color: AppColors.hairline, width: 0.5),
                  borderRadius: BorderRadius.circular(14)),
                child: Column(children: entry.value.asMap().entries.map((e) {
                  final n = e.value;
                  final isToday = n.group == 'Bugün';
                  return Container(
                    decoration: BoxDecoration(border: Border(
                      top: e.key > 0 ? const BorderSide(color: AppColors.hairline, width: 0.5) : BorderSide.none)),
                    padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _NotifIcon(kind: n.kind),
                      const SizedBox(width: 11),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.title, style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.text1,
                          letterSpacing: -0.005)),
                        const SizedBox(height: 2),
                        Text(n.sub, style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5, color: AppColors.text3, height: 1.4)),
                      ])),
                      if (isToday) Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6),
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.accent, blurRadius: 6)])),
                    ]));
                }).toList())),
            ],
          ])),
        ),
      ]),
    );
  }
}

class _NotifIcon extends StatelessWidget {
  final String kind;
  const _NotifIcon({required this.kind});

  @override
  Widget build(BuildContext context) {
    final cfg = switch (kind) {
      'alert'    => (const Color(0x1F4D9FFF), AppColors.accent,  Icons.notifications_outlined),
      'success'  => (AppColors.profitSoft,    AppColors.profit,  Icons.check),
      'loss'     => (AppColors.lossSoft,      AppColors.loss,    Icons.warning_amber_outlined),
      'security' => (const Color(0x1F7C5CFF), const Color(0xFFA78BFA), Icons.security),
      _          => (const Color(0x0FFFFFFF), AppColors.text2,   Icons.info_outline),
    };
    return Container(width: 36, height: 36, decoration: BoxDecoration(
      color: cfg.$1, borderRadius: BorderRadius.circular(11)),
      child: Icon(cfg.$3, color: cfg.$2, size: 16));
  }
}
