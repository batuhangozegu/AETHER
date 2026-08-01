// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  try {
    return await ref.watch(apiServiceProvider).getNotifications();
  } catch (_) {
    return [];
  }
});

String _groupFor(String createdAt) {
  final date = DateTime.tryParse(createdAt);
  if (date == null) return 'Daha Önce';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(date.year, date.month, date.day);
  final diffDays = today.difference(that).inDays;
  if (diffDays == 0) return 'Bugün';
  if (diffDays == 1) return 'Dün';
  if (diffDays <= 7) return 'Bu Hafta';
  return 'Daha Önce';
}

String _timeFor(String createdAt) {
  final date = DateTime.tryParse(createdAt);
  if (date == null) return '';
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'all';

  Map<String, List<NotificationModel>> _groups(List<NotificationModel> notifs) {
    final filtered = notifs.where((n) {
      if (_filter == 'all') return true;
      if (_filter == 'alarms') return n.type == 'alert';
      if (_filter == 'security') return n.type == 'security';
      if (_filter == 'trades') return n.type == 'loss' || n.type == 'success';
      return true;
    }).toList();
    final map = <String, List<NotificationModel>>{};
    for (final n in filtered) (map[_groupFor(n.createdAt)] ??= []).add(n);
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsProvider);
    final notifs = notifsAsync.valueOrNull ?? [];
    final unreadCount = notifs.where((n) => !n.isRead).length;
    final groups = _groups(notifs);

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
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(5)),
                  child: Text('$unreadCount YENİ', style: AppTheme.mono(fontSize: 11, color: AppColors.accent))),
              ],
              const Spacer(),
              TextButton(onPressed: () async {
                await ref.read(apiServiceProvider).markAllNotificationsRead();
                ref.invalidate(notificationsProvider);
              }, child: Text('Tümünü oku',
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
        if (notifsAsync.isLoading)
          const SliverToBoxAdapter(child: Center(child: Padding(
            padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.accent))))
        else if (notifs.isEmpty)
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.notifications_off_outlined, color: AppColors.text3, size: 40),
              const SizedBox(height: 10),
              Text('Henüz bildirim yok', style: GoogleFonts.spaceGrotesk(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text2)),
            ])),
          ))
        else
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
                    return GestureDetector(
                      onTap: () async {
                        if (!n.isRead) {
                          await ref.read(apiServiceProvider).markNotificationRead(n.id);
                          ref.invalidate(notificationsProvider);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(border: Border(
                          top: e.key > 0 ? const BorderSide(color: AppColors.hairline, width: 0.5) : BorderSide.none)),
                        padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _NotifIcon(kind: n.type),
                          const SizedBox(width: 11),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n.title, style: GoogleFonts.spaceGrotesk(
                              fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.text1,
                              letterSpacing: -0.005)),
                            const SizedBox(height: 2),
                            Text('${_timeFor(n.createdAt)}${n.message != null ? ' · ${n.message}' : ''}',
                              style: GoogleFonts.spaceGrotesk(fontSize: 10.5, color: AppColors.text3, height: 1.4)),
                          ])),
                          if (!n.isRead) Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.accent, blurRadius: 6)])),
                        ]),
                      ),
                    );
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
