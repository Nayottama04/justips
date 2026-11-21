import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'nav.dart';

/// Kartu order glass (dipakai pembeli & penjastip).
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.actions,
    required this.amountLabel,
    required this.amount,
    this.amountColor,
    this.infoIcon = Icons.place_outlined,
    this.info,
    this.index = 0,
  });
  final Order order;
  final List<Widget> actions;
  final String amountLabel;
  final int amount;
  final Color? amountColor;
  final IconData infoIcon;
  final String? info;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Reveal(
      index: index,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        onTap: () => openOrder(context, order.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.receipt_long_outlined, size: 13, color: p.muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text('${order.code}  •  ${dateShort(order.createdAt)}',
                  overflow: TextOverflow.ellipsis,
                  style: tx(11, w: FontWeight.w600, color: p.ink, ls: 0.4)),
            ),
            const Spacer(),
            StatusBadge(order.status),
          ]),
          Divider(height: 22, color: p.line),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SmartImage(order.imageUrl, size: 72, radius: 16, fallbackIcon: iconForItem(order.itemName)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tx(16, w: FontWeight.w600, color: p.ink)),
                const SizedBox(height: 2),
                Text(order.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tx(12, color: p.muted, h: 1.35)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(infoIcon, size: 13, color: p.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(info ?? order.locationFull,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tx(11, color: p.muted)),
                  ),
                ]),
              ]),
            ),
          ]),
          Divider(height: 22, color: p.line),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(amountLabel, style: tx(11, w: FontWeight.w600, color: p.muted, ls: 0.4)),
              const SizedBox(height: 2),
              Text(rupiah(amount),
                  style: tx(16, w: FontWeight.w700, color: amountColor ?? p.ink)),
            ]),
            const Spacer(),
            Wrap(spacing: 8, children: actions),
          ]),
        ]),
      ),
    );
  }
}

/// Kartu order masuk di Home Penjastip (Chat dengan Pembeli + Ambil Order).
class IncomingOrderCard extends StatefulWidget {
  const IncomingOrderCard({super.key, required this.order, this.index = 0, this.onTaken});
  final Order order;
  final int index;
  final VoidCallback? onTaken;

  @override
  State<IncomingOrderCard> createState() => _IncomingOrderCardState();
}

class _IncomingOrderCardState extends State<IncomingOrderCard> {
  bool _busy = false;

  Future<void> _take() async {
    final s = context.read<AppState>();
    final me = s.user;
    if (me == null) return;
    final o = widget.order;
    if (!me.kycOk) {
      toast(context, 'Verifikasi identitas (KYC) dulu sebelum mengambil order.');
      return;
    }
    // FR-24: konfirmasi sebelum mengambil order.
    final ok = await showGlassSheet<bool>(
      context,
      _ConfirmTake(order: o),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await s.repo.takeOrder(o, me);
      if (!mounted) return;
      toast(context, 'Order berhasil diambil. Kirim rincian biaya ke pembeli.');
      widget.onTaken?.call();
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final o = widget.order;
    final me = context.select<AppState, AppUser?>((s) => s.user);
    final over = me != null && o.estimatedPrice > me.maxOrderValue;
    return Reveal(
      index: widget.index,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 14),
        onTap: () => openOrder(context, o.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Avatar(name: o.buyerName, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Diorder oleh @${o.buyerUsername}',
                  style: tx(12, w: FontWeight.w600, color: p.ink)),
            ),
            Text(relTime(o.createdAt), style: tx(11, color: p.muted)),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SmartImage(o.imageUrl, size: 64, radius: 16, fallbackIcon: iconForItem(o.itemName)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.itemName, style: tx(16, w: FontWeight.w600, color: p.ink)),
                const SizedBox(height: 2),
                Text(o.description, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: tx(12, color: p.muted, h: 1.35)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          if (o.linkUrl.isNotEmpty)
            PressScale(
              onTap: () {
                Clipboard.setData(ClipboardData(text: o.linkUrl));
                toast(context, 'Tautan contoh item disalin.');
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(Icons.link_rounded, size: 15, color: p.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(o.linkUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tx(12, w: FontWeight.w500, color: p.accent)),
                  ),
                ]),
              ),
            ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.place_outlined, size: 15, color: p.muted),
            const SizedBox(width: 6),
            Expanded(child: Text(o.locationFull, style: tx(12, color: p.muted, h: 1.3))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Text('Estimasi ', style: tx(11, color: p.muted)),
            Text(rupiah(o.estimatedPrice), style: tx(13, w: FontWeight.w700, color: p.ink)),
            const Spacer(),
            if (over)
              Pill('Melebihi batas level kamu', color: P.danger, icon: Icons.lock_outline_rounded),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Btn('Chat dengan Pembeli',
                  icon: Icons.chat_bubble_outline_rounded,
                  kind: BtnKind.outline,
                  expand: true,
                  onTap: () => openChatForOrder(context, o)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Btn('Ambil Order',
                  icon: Icons.bolt_rounded,
                  expand: true,
                  busy: _busy,
                  onTap: over ? null : _take),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ConfirmTake extends StatelessWidget {
  const _ConfirmTake({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Ambil order ini?', style: tx(20, w: FontWeight.w700, color: p.ink, ls: -0.4)),
      const SizedBox(height: 8),
      Text(
          'Setelah diambil, order terkunci untukmu dan tidak bisa diambil penjastip lain. '
          'Kamu akan mengirim rincian biaya, lalu membeli barang setelah dana pembeli ditahan.',
          style: tx(13, color: p.muted, h: 1.5)),
      const SizedBox(height: 14),
      GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 16,
        child: Row(children: [
          SmartImage('', size: 44, radius: 12, fallbackIcon: iconForItem(order.itemName)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.itemName, style: tx(14, w: FontWeight.w600, color: p.ink)),
              Text('${order.locationLabel} • est. ${rupiah(order.estimatedPrice)}',
                  style: tx(12, color: p.muted)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: Btn('Batal', kind: BtnKind.outline, expand: true, large: true,
            onTap: () => Navigator.pop(context, false))),
        const SizedBox(width: 12),
        Expanded(child: Btn('Ya, Ambil', expand: true, large: true,
            onTap: () => Navigator.pop(context, true))),
      ]),
    ]);
  }
}
