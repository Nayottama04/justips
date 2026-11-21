import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/picker.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'nav.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = P.of(context);
    final uid = s.uid;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
        children: [
          Text('Pesan', style: tx(28, w: FontWeight.w800, color: p.ink, ls: -0.9)),
          const SizedBox(height: 4),
          Text('Percakapan pembeli & penjastip', style: tx(13, color: p.muted)),
          const SizedBox(height: 16),
          if (uid == null)
            EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Masuk untuk melihat pesan',
              message: 'Chat hanya tersedia setelah login.',
              action: Btn('Masuk', onTap: () => requireLogin(context)),
            )
          else
            StreamBuilder<List<ChatRoom>>(
              stream: s.repo.watchRooms(uid),
              builder: (context, snap) {
                final rooms = (snap.data ?? const <ChatRoom>[]).where((r) => r.lastText.isNotEmpty).toList();
                if (!snap.hasData) return const Loading();
                if (rooms.isEmpty) {
                  return const EmptyState(
                    icon: Icons.forum_outlined,
                    title: 'Belum ada percakapan',
                    message: 'Mulai chat dari kartu order atau halaman detail order.',
                  );
                }
                return Column(children: [
                  for (var i = 0; i < rooms.length; i++)
                    Reveal(
                      index: i,
                      child: GlassCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        radius: 20,
                        onTap: () => pushPage(context, ChatRoomScreen(roomId: rooms[i].id)),
                        child: Row(children: [
                          Avatar(name: rooms[i].otherName(uid), size: 46),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(
                                  child: Text(rooms[i].otherName(uid),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: tx(14, w: FontWeight.w700, color: p.ink)),
                                ),
                                if (rooms[i].lastAt != null)
                                  Text(relTime(rooms[i].lastAt!), style: tx(11, color: p.muted)),
                              ]),
                              Text(rooms[i].itemName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: tx(11, w: FontWeight.w600, color: p.accent)),
                              const SizedBox(height: 2),
                              Row(children: [
                                Expanded(
                                  child: Text(rooms[i].lastText, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: tx(12, color: p.muted)),
                                ),
                                if (rooms[i].unreadFor(uid) > 0)
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: P.emerald, borderRadius: BorderRadius.circular(99)),
                                    child: Text('${rooms[i].unreadFor(uid)}',
                                        style: tx(10, w: FontWeight.w700, color: Colors.white)),
                                  ),
                              ]),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                ]);
              },
            ),
        ],
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.roomId});
  final String roomId;
  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _ctl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  void _markRead() {
    final s = context.read<AppState>();
    if (s.uid != null) s.repo.markRoomRead(widget.roomId, s.uid!);
  }

  @override
  void dispose() {
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(ChatRoom room, {String? image}) async {
    final s = context.read<AppState>();
    final me = s.user;
    if (me == null) return;
    final text = _ctl.text;
    if (text.trim().isEmpty && image == null) return;
    _ctl.clear();
    setState(() => _sending = true);
    try {
      await s.repo.sendMessage(room, me, text: text, imagePath: image);
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = P.of(context);
    final me = s.user;

    return StreamBuilder<ChatRoom?>(
      stream: s.repo.watchRoom(widget.roomId),
      builder: (context, roomSnap) {
        final room = roomSnap.data;
        if (room == null || me == null) {
          return const PageShell(title: 'Chat', child: Loading());
        }
        final other = room.otherName(me.id);
        final otherRead = room.readAt[room.otherId(me.id)] ?? 0;

        return PageShell(
          title: other,
          actions: [
            GlassIconButton(Icons.receipt_long_outlined, onTap: () => openOrder(context, room.orderId)),
          ],
          bottom: Padding(
            padding: EdgeInsets.fromLTRB(12, 6, 12, MediaQuery.of(context).padding.bottom + 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              GlassIconButton(Icons.image_outlined, onTap: () async {
                try {
                  final path = await pickPhoto();
                  if (path != null) _send(room, image: path);
                } catch (_) {
                  if (context.mounted) toast(context, 'Tidak dapat membuka galeri.');
                }
              }),
              const SizedBox(width: 8),
              Expanded(
                child: GlassField(
                  controller: _ctl,
                  hint: 'Tulis pesan...',
                  maxLines: 4,
                  action: TextInputAction.send,
                  onSubmitted: (_) => _send(room),
                ),
              ),
              const SizedBox(width: 8),
              PressScale(
                onTap: _sending ? null : () => _send(room),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [P.emeraldDeep, P.emerald]),
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                ),
              ),
            ]),
          ),
          child: Column(children: [
            // Header order
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GlassCard(
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onTap: () => openOrder(context, room.orderId),
                child: Row(children: [
                  Icon(iconForItem(room.itemName), size: 18, color: p.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(room.itemName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: tx(13, w: FontWeight.w600, color: p.ink))),
                  Icon(Icons.chevron_right_rounded, size: 18, color: p.muted),
                ]),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: s.repo.watchMessages(room.id),
                builder: (context, snap) {
                  final msgs = snap.data ?? const <ChatMessage>[];
                  if (msgs.length != _lastCount) {
                    _lastCount = msgs.length;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scroll.hasClients) {
                        _scroll.animateTo(0,
                            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                      }
                    });
                    _markRead();
                  }
                  if (!snap.hasData) return const Loading();
                  final rev = msgs.reversed.toList();
                  return ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    itemCount: rev.length,
                    itemBuilder: (c, i) {
                      final m = rev[i];
                      if (m.system) return _SystemBubble(text: m.text);
                      final mine = m.senderId == me.id;
                      final read = mine && otherRead >= m.createdAt.millisecondsSinceEpoch;
                      return _Bubble(msg: m, mine: mine, read: read);
                    },
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(99), border: Border.all(color: p.line)),
          child: Text(text, textAlign: TextAlign.center, style: tx(11, color: p.muted)),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.mine, required this.read});
  final ChatMessage msg;
  final bool mine;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final br = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(mine ? 20 : 6),
      bottomRight: Radius.circular(mine ? 6 : 20),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                borderRadius: br,
                gradient: mine ? const LinearGradient(colors: [P.emeraldDeep, P.emerald]) : null,
                color: mine ? null : p.glassFill,
                border: mine ? null : Border.all(color: p.glassEdge),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (msg.imageUrl.isNotEmpty) ...[
                  SmartImage(msg.imageUrl, size: 150, radius: 14, fill: true),
                  const SizedBox(height: 6),
                ],
                if (msg.text.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(msg.text, style: tx(14, color: mine ? Colors.white : p.ink, h: 1.35)),
                  ),
                const SizedBox(height: 3),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(hm(msg.createdAt),
                      style: tx(10, color: mine ? Colors.white70 : p.muted)),
                  if (mine) ...[
                    const SizedBox(width: 3),
                    Icon(read ? Icons.done_all_rounded : Icons.done_rounded, size: 13,
                        color: read ? Colors.white : Colors.white70),
                  ],
                ]),
              ]),
            ),
          ),
        ),
        if (msg.flagged)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.warning_amber_rounded, size: 13, color: p.amberText),
              const SizedBox(width: 4),
              Flexible(
                child: Text('Hati-hati: transaksi di luar aplikasi tidak dilindungi escrow Justips.',
                    style: tx(10, color: p.amberText)),
              ),
            ]),
          ),
      ]),
    );
  }
}
