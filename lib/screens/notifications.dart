import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'chat.dart';
import 'nav.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String t) => switch (t) {
        'chat' => Icons.chat_bubble_outline_rounded,
        'pay' => Icons.lock_outline_rounded,
        'fees' => Icons.request_quote_outlined,
        'take' => Icons.how_to_reg_outlined,
        'wallet' => Icons.account_balance_wallet_outlined,
        'complaint' => Icons.flag_outlined,
        'account' => Icons.person_outline_rounded,
        _ => Icons.local_shipping_outlined,
      };

  Color _color(String t) => switch (t) {
        'chat' => const Color(0xFF0284C7),
        'pay' => const Color(0xFF0D9488),
        'fees' => P.amber,
        'wallet' => P.gold,
        'complaint' => const Color(0xFFE11D48),
        'account' => const Color(0xFF6366F1),
        _ => P.emerald,
      };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = P.of(context);
    final uid = s.uid;

    return SafeArea(
      bottom: false,
      child: uid == null
          ? ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 140), children: [
              Text('Notifikasi', style: tx(28, w: FontWeight.w800, color: p.ink, ls: -0.9)),
              const SizedBox(height: 16),
              EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Masuk untuk melihat notifikasi',
                message: 'Status order, chat, dan dana muncul di sini.',
                action: Btn('Masuk', onTap: () => requireLogin(context)),
              ),
            ])
          : StreamBuilder<List<NotificationItem>>(
              stream: s.repo.watchNotifications(uid),
              builder: (context, snap) {
                final items = snap.data ?? const <NotificationItem>[];
                final unread = items.where((e) => !e.isRead).length;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
                  children: [
                    Row(children: [
                      Expanded(child: Text('Notifikasi', style: tx(28, w: FontWeight.w800, color: p.ink, ls: -0.9))),
                      if (unread > 0)
                        Btn('Tandai dibaca', kind: BtnKind.soft, onTap: () => s.repo.markAllRead(items)),
                    ]),
                    const SizedBox(height: 4),
                    Text(unread > 0 ? '$unread belum dibaca' : 'Semua sudah dibaca', style: tx(13, color: p.muted)),
                    const SizedBox(height: 16),
                    if (!snap.hasData)
                      const Loading()
                    else if (items.isEmpty)
                      const EmptyState(
                        icon: Icons.notifications_off_outlined,
                        title: 'Belum ada notifikasi',
                        message: 'Aktivitas order dan dana akan tampil di sini.',
                      )
                    else
                      for (var i = 0; i < items.length; i++)
                        Reveal(
                          index: i,
                          child: GlassCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            radius: 20,
                            tint: items[i].isRead ? null : P.emerald.withOpacity(0.10),
                            onTap: () {
                              s.repo.markNotificationRead(items[i].id);
                              final n = items[i];
                              if (n.type == 'chat') {
                                pushPage(context, ChatRoomScreen(roomId: n.refId));
                              } else if (n.refId.isNotEmpty && n.type != 'account') {
                                openOrder(context, n.refId);
                              }
                            },
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _color(items[i].type).withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(_icon(items[i].type), size: 19, color: _color(items[i].type)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(items[i].title,
                                          style: tx(13, w: items[i].isRead ? FontWeight.w600 : FontWeight.w700, color: p.ink)),
                                    ),
                                    Text(relTime(items[i].createdAt), style: tx(10, color: p.muted)),
                                  ]),
                                  const SizedBox(height: 2),
                                  Text(items[i].body, maxLines: 3, overflow: TextOverflow.ellipsis,
                                      style: tx(12, color: p.muted, h: 1.4)),
                                ]),
                              ),
                              if (!items[i].isRead)
                                Container(
                                  margin: const EdgeInsets.only(left: 8, top: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: P.emerald, shape: BoxShape.circle),
                                ),
                            ]),
                          ),
                        ),
                  ],
                );
              },
            ),
    );
  }
}
