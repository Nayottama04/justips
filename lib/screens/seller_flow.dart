import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

Future<void> showFeesSheet(BuildContext context, Order order) =>
    showGlassSheet<void>(context, FeesSheet(order: order));

/// Penjastip mengisi rincian biaya (harga barang, fee jasa, ongkir) - FR-70.
class FeesSheet extends StatefulWidget {
  const FeesSheet({super.key, required this.order});
  final Order order;

  @override
  State<FeesSheet> createState() => _FeesSheetState();
}

class _FeesSheetState extends State<FeesSheet> {
  late final TextEditingController _item;
  final _fee = TextEditingController();
  final _ship = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _item = TextEditingController(
        text: o.estimatedPrice > 0 ? rupiah(o.estimatedPrice).substring(3) : '');
    if (o.hasFees) {
      _item.text = rupiah(o.itemPrice).substring(3);
      _fee.text = rupiah(o.serviceFee).substring(3);
      _ship.text = rupiah(o.shippingFee).substring(3);
    }
  }

  @override
  void dispose() {
    _item.dispose();
    _fee.dispose();
    _ship.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = context.read<AppState>();
    final me = s.user;
    if (me == null) return;
    final item = parseRupiah(_item.text), fee = parseRupiah(_fee.text), ship = parseRupiah(_ship.text);
    if (item + fee + ship > me.maxOrderValue) {
      toast(context, 'Melebihi batas level kamu (${rupiah(me.maxOrderValue)} per order).');
      return;
    }
    setState(() => _busy = true);
    try {
      await s.repo.submitFees(widget.order, item, fee, ship);
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, 'Rincian biaya dikirim ke pembeli.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final item = parseRupiah(_item.text), fee = parseRupiah(_fee.text), ship = parseRupiah(_ship.text);
    final sub = item + fee + ship;
    final comm = (fee * AppConfig.commissionRate).round();
    Widget row(String l, String v, {bool bold = false, Color? c}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(l, style: tx(12, color: p.muted, w: bold ? FontWeight.w600 : FontWeight.w400))),
            Text(v, style: tx(bold ? 14 : 12, w: bold ? FontWeight.w700 : FontWeight.w500, color: c ?? p.ink)),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Kirim Rincian Biaya', style: tx(20, w: FontWeight.w700, color: p.ink, ls: -0.4)),
      const SizedBox(height: 4),
      Text(widget.order.itemName, style: tx(13, color: p.muted)),
      const SizedBox(height: 16),
      GlassField(controller: _item, label: 'Harga barang', hint: '0', icon: Icons.sell_outlined,
          keyboard: TextInputType.number, formatters: [RupiahInputFormatter()],
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      GlassField(controller: _fee, label: 'Fee jasa', hint: '0', icon: Icons.handshake_outlined,
          keyboard: TextInputType.number, formatters: [RupiahInputFormatter()],
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      GlassField(controller: _ship, label: 'Ongkos kirim', hint: '0', icon: Icons.local_shipping_outlined,
          keyboard: TextInputType.number, formatters: [RupiahInputFormatter()],
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 14),
      GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 16,
        child: Column(children: [
          row('Subtotal ke pembeli', rupiah(sub)),
          row('Komisi aplikasi (5% dari fee)', '- ${rupiah(comm)}'),
          Divider(color: p.line, height: 16),
          row('Pendapatan bersih kamu', rupiah(sub - comm), bold: true, c: p.accent),
          const SizedBox(height: 4),
          Text('Biaya payment gateway ditambahkan otomatis pada tagihan pembeli.',
              style: tx(11, color: p.muted)),
        ]),
      ),
      const SizedBox(height: 16),
      Btn('Kirim ke Pembeli', expand: true, large: true, busy: _busy,
          icon: Icons.send_rounded, onTap: item <= 0 ? null : _send),
    ]);
  }
}
