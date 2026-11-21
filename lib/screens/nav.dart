import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'auth.dart';
import 'chat.dart';
import 'order_detail.dart';

Route<T> slideRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (c, a, sa, child) {
        final curved = CurvedAnimation(
            parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.10, 0), end: Offset.zero).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );

Future<T?> pushPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(slideRoute<T>(page));

/// FR-06 / FR-57: fitur yang butuh login mengarahkan pengunjung ke halaman Login.
Future<bool> requireLogin(BuildContext context) async {
  final s = context.read<AppState>();
  if (s.loggedIn) return true;
  final ok = await pushPage<bool>(context, const LoginScreen());
  return ok == true || s.loggedIn;
}

void openOrder(BuildContext context, String orderId) =>
    pushPage(context, OrderDetailScreen(orderId: orderId));

/// Buka chat untuk sebuah order (pembeli -> penjastip terkait; penjastip -> pembeli).
Future<void> openChatForOrder(BuildContext context, Order o) async {
  if (!await requireLogin(context)) return;
  if (!context.mounted) return;
  final s = context.read<AppState>();
  final me = s.user;
  if (me == null) return;
  try {
    ChatRoom room;
    if (me.id == o.buyerId) {
      if (o.sellerId.isEmpty) {
        toast(context, 'Belum ada penjastip yang mengambil order ini.');
        return;
      }
      room = await s.repo.ensureRoom(o, o.sellerId, o.sellerName);
    } else {
      room = await s.repo.ensureRoom(o, me.id, me.name);
    }
    if (!context.mounted) return;
    pushPage(context, ChatRoomScreen(roomId: room.id));
  } catch (e) {
    if (context.mounted) toast(context, e.toString());
  }
}
