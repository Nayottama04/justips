import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'chat.dart';
import 'home.dart';
import 'nav.dart';
import 'notifications.dart';
import 'profile.dart';
import 'search.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final Set<int> _visited = {0};
  bool _compact = false;

  Widget _tab(int i) {
    switch (i) {
      case 0:
        return const HomeTab();
      case 1:
        return const SearchScreen();
      case 2:
        return const ChatListScreen();
      case 3:
        return const NotificationsScreen();
      default:
        return const ProfileScreen();
    }
  }

  Future<void> _go(int i) async {
    final s = context.read<AppState>();
    // FR-57: Chat, Notifikasi, Profil butuh login.
    if (i >= 2 && !s.loggedIn) {
      await requireLogin(context);
      return;
    }
    setState(() => _visited.add(i));
    s.setTab(i);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final kb = MediaQuery.of(context).viewInsets.bottom > 0;
    final p = P.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      resizeToAvoidBottomInset: false,
      body: Aurora(
        child: Stack(
          children: [
            NotificationListener<UserScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis != Axis.vertical) return false;
                if (n.direction == ScrollDirection.reverse && !_compact) {
                  setState(() => _compact = true);
                } else if (n.direction == ScrollDirection.forward && _compact) {
                  setState(() => _compact = false);
                }
                return false;
              },
              child: IndexedStack(
                index: s.tab,
                children: [
                  for (var i = 0; i < 5; i++)
                    _visited.contains(i) || s.tab == i ? _tab(i) : const SizedBox.shrink(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                offset: kb ? const Offset(0, 1.6) : Offset.zero,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: FloatingNavBar(
                  index: s.tab,
                  compact: _compact,
                  onTap: _go,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.index, required this.onTap, this.compact = false});
  final int index;
  final ValueChanged<int> onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final s = context.watch<AppState>();
    final bottom = MediaQuery.of(context).padding.bottom;

    Widget badge(int n, Color c) => n <= 0
        ? const SizedBox.shrink()
        : Positioned(
            right: -9,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)),
              child: Text(n > 99 ? '99+' : '$n', style: tx(9, w: FontWeight.w700, color: Colors.white)),
            ),
          );

    Widget item(int i, IconData off, IconData on, String label, {int count = 0, Color bc = P.emerald, Widget? custom}) {
      final active = index == i;
      final fg = active ? p.accent : p.muted;
      return PressScale(
        onTap: () => onTap(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          padding: EdgeInsets.symmetric(horizontal: active ? 16 : 10, vertical: compact ? 8 : 7),
          decoration: BoxDecoration(
            color: active ? P.emerald.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: active ? P.emerald.withOpacity(0.32) : Colors.transparent),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              custom ?? Icon(active ? on : off, size: 21, color: fg),
              badge(count, bc),
            ]),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: compact
                  ? const SizedBox(height: 0, width: 0)
                  : Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(label,
                          style: tx(10, w: active ? FontWeight.w700 : FontWeight.w500, color: fg)),
                    ),
            ),
          ]),
        ),
      );
    }

    final uid = s.uid;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: RepaintBoundary(
           child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(p.dark ? 0.5 : 0.14),
                    blurRadius: 32,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: p.dark ? const Color(0x99101826) : const Color(0xB3FFFFFF),
                    border: Border.all(color: p.glassEdge),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      item(0, Icons.home_outlined, Icons.home_rounded, 'Beranda'),
                      item(1, Icons.search_rounded, Icons.search_rounded, 'Cari'),
                      uid == null
                          ? item(2, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Pesan')
                          : StreamBuilder<List<ChatRoom>>(
                              stream: s.repo.watchRooms(uid),
                              builder: (c, snap) {
                                final n = (snap.data ?? const <ChatRoom>[])
                                    .fold<int>(0, (a, r) => a + r.unreadFor(uid));
                                return item(2, Icons.chat_bubble_outline_rounded,
                                    Icons.chat_bubble_rounded, 'Pesan', count: n);
                              }),
                      uid == null
                          ? item(3, Icons.notifications_none_rounded, Icons.notifications_rounded, 'Notifikasi')
                          : StreamBuilder<List<NotificationItem>>(
                              stream: s.repo.watchNotifications(uid),
                              builder: (c, snap) {
                                final n = (snap.data ?? const <NotificationItem>[])
                                    .where((x) => !x.isRead)
                                    .length;
                                return item(3, Icons.notifications_none_rounded,
                                    Icons.notifications_rounded, 'Notifikasi',
                                    count: n, bc: P.danger);
                              }),
                      item(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profil',
                          custom: s.user == null
                              ? null
                              : Avatar(name: s.user!.name, photoUrl: s.user!.photoUrl, size: 22)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
