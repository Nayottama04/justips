import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'complaint.dart';
import 'evidence.dart';
import 'nav.dart';
import 'order_form.dart';
import 'seller_flow.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return StreamBuilder<Order?>(
      stream: s.repo.watchOrder(orderId),
      builder: (context, snap) {
        final o = snap.data;
        return PageShell(
          title: o?.code ?? 'Detail Order',
          child: o == null
              ? (snap.connectionState == ConnectionState.waiting
                  ? const Loading()
                  : const Center(child: Text('Order tidak ditemukan')))
              : _Body(order: o),
        );
      },
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.order});
  final Order order;
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job, String okMsg) async {
    setState(() => _busy = true);
    try {
      await job();
      if (mounted) toast(context, okMsg);
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String msg, String yes) async {
    final r = await showGlassSheet<bool>(
      context,
      Builder(builder: (ctx) {
        final p = P.of(ctx);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: tx(20, w: FontWeight.w700, color: p.ink, ls: -0.4)),
          const SizedBox(height: 8),
          Text(msg, style: tx(13, color: p.muted, h: 1.5)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Btn('Batal', kind: BtnKind.outline, expand: true, large: true,
                onTap: () => Navigator.pop(ctx, false))),
            const SizedBox(width: 12),
            Expanded(child: Btn(yes, expand: true, large: true, onTap: () => Navigator.pop(ctx, true))),
          ]),
        ]);
      }),
    );
    return r == true;
  }

  String _statusText(Order o, bool isBuyer) {
    switch (o.status) {
      case OrderStatus.waiting:
        return 'Menunggu penjastip mengambil order ini.';
      case OrderStatus.taken:
        return isBuyer
            ? 'Order diambil ${o.sellerName}. Tunggu rincian biaya dikirim.'
            : 'Kirim rincian biaya ke pembeli.';
      case OrderStatus.awaitingPayment:
        return isBuyer
            ? 'Periksa rincian biaya lalu bayar. Dana ditahan aman oleh Justips.'
            : 'Menunggu pembeli menyetujui & membayar.';
      case OrderStatus.held:
        return isBuyer
            ? 'Dana ditahan. Penjastip akan membeli barangmu.'
            : 'Dana pembeli sudah ditahan. Silakan beli barang & unggah bukti.';
      case OrderStatus.purchased:
        return isBuyer ? 'Barang sudah dibeli penjastip.' : 'Kirim barang & unggah bukti pengiriman.';
      case OrderStatus.shipped:
        return isBuyer
            ? 'Barang dalam pengiriman. Konfirmasi bila sudah tiba.'
            : 'Menunggu pembeli konfirmasi (otomatis 3x24 jam).';
      case OrderStatus.received:
        return 'Barang tercatat diterima. Dana dirilis setelah jendela komplain 2x24 jam.';
      case OrderStatus.done:
        return 'Order selesai. Dana sudah dilepas ke penjastip.';
      case OrderStatus.cancelled:
        return 'Order dibatalkan.';
      case OrderStatus.complaint:
        return 'Komplain sedang ditinjau. Dana tetap ditahan.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = P.of(context);
    final o = widget.order;
    final me = s.user;
    final isBuyer = me != null && me.id == o.buyerId;
    final isSeller = me != null && me.id == o.sellerId;

    Widget title(String t, {IconData? i}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            if (i != null) ...[Icon(i, size: 17, color: p.accent), const SizedBox(width: 8)],
            Text(t, style: tx(15, w: FontWeight.w700, color: p.ink)),
          ]),
        );

    final children = <Widget>[
      // ---- Status
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            StatusBadge(o.status),
            const Spacer(),
            Text(dateShort(o.createdAt), style: tx(11, color: p.muted)),
          ]),
          const SizedBox(height: 12),
          Text(_statusText(o, isBuyer), style: tx(13, color: p.ink, h: 1.45)),
          const SizedBox(height: 16),
          _Stepper(status: o.status),
        ]),
      ),
      const SizedBox(height: 14),
    ];

    // ---- Panel aksi
    final action = _actions(context, o, isBuyer, isSeller);
    if (action != null) {
      children..add(action)..add(const SizedBox(height: 14));
    }

    // ---- Item
    children.add(GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SmartImage(o.imageUrl, size: 72, radius: 16, fallbackIcon: iconForItem(o.itemName)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.itemName, style: tx(17, w: FontWeight.w700, color: p.ink, ls: -0.2)),
              const SizedBox(height: 3),
              Text(o.description, style: tx(12, color: p.muted, h: 1.4)),
            ]),
          ),
        ]),
        Divider(height: 24, color: p.line),
        _kv(p, Icons.place_outlined, 'Lokasi beli', o.locationFull),
        if (o.linkUrl.isNotEmpty) _kv(p, Icons.link_rounded, 'Link contoh', o.linkUrl),
        if (o.deliveryAddress.isNotEmpty) _kv(p, Icons.home_outlined, 'Alamat kirim', o.deliveryAddress),
        _kv(p, Icons.sell_outlined, 'Estimasi harga', rupiah(o.estimatedPrice)),
        if (o.trackingNo.isNotEmpty) _kv(p, Icons.local_shipping_outlined, 'Resi', o.trackingNo),
      ]),
    ));
    children.add(const SizedBox(height: 14));

    // ---- Pihak
    children.add(GlassCard(
      child: Column(children: [
        Row(children: [
          Avatar(name: o.buyerName, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pembeli', style: tx(11, color: p.muted)),
              Text(o.buyerName, style: tx(14, w: FontWeight.w600, color: p.ink)),
            ]),
          ),
          if (!isBuyer && me != null)
            GlassIconButton(Icons.chat_bubble_outline_rounded, onTap: () => openChatForOrder(context, o)),
        ]),
        if (o.sellerId.isNotEmpty) ...[
          Divider(height: 24, color: p.line),
          Row(children: [
            Avatar(name: o.sellerName, size: 38, verified: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Penjastip', style: tx(11, color: p.muted)),
                Text(o.sellerName, style: tx(14, w: FontWeight.w600, color: p.ink)),
              ]),
            ),
            if (isBuyer)
              GlassIconButton(Icons.chat_bubble_outline_rounded, onTap: () => openChatForOrder(context, o)),
          ]),
        ],
      ]),
    ));
    children.add(const SizedBox(height: 14));

    // ---- Rincian biaya
    if (o.hasFees) {
      children.add(GlassCard(child: _Breakdown(order: o, seller: isSeller)));
      children.add(const SizedBox(height: 14));
    }

    // ---- Bukti
    if (o.evidence.isNotEmpty) {
      children.add(GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          title('Bukti', i: Icons.receipt_long_outlined),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final e in o.evidence)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SmartImage('${e['url'] ?? ''}', size: 82, radius: 16, fallbackIcon: Icons.image_outlined),
                const SizedBox(height: 4),
                Text(
                    e['type'] == 'purchase'
                        ? 'Pembelian'
                        : e['type'] == 'shipping'
                            ? 'Pengiriman'
                            : 'Komplain',
                    style: tx(10, color: p.muted)),
              ]),
          ]),
        ]),
      ));
      children.add(const SizedBox(height: 14));
    }

    // ---- Riwayat dana
    if (me != null) {
      children.add(StreamBuilder<List<LedgerEntry>>(
        stream: s.repo.watchOrderLedger(o.id),
        builder: (context, snap) {
          final l = (snap.data ?? const <LedgerEntry>[]).where((e) => e.userId == me.id).toList();
          if (l.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GlassCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                title('Riwayat dana', i: Icons.account_balance_wallet_outlined),
                for (final e in l)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.note, style: tx(12, w: FontWeight.w500, color: p.ink)),
                          Text(dateTimeFull(e.createdAt), style: tx(10, color: p.muted)),
                        ]),
                      ),
                      Text('${e.amount >= 0 ? '+' : ''}${rupiah(e.amount)}',
                          style: tx(12, w: FontWeight.w700, color: e.amount >= 0 ? p.accent : p.dangerInk)),
                    ]),
                  ),
              ]),
            ),
          );
        },
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      children: [for (var i = 0; i < children.length; i++) children[i]],
    );
  }

  Widget _kv(P p, IconData i, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i, size: 15, color: p.muted),
          const SizedBox(width: 8),
          SizedBox(width: 86, child: Text(k, style: tx(12, color: p.muted))),
          Expanded(child: Text(v, style: tx(12, w: FontWeight.w500, color: p.ink, h: 1.35))),
        ]),
      );

  Widget? _actions(BuildContext context, Order o, bool isBuyer, bool isSeller) {
    final s = context.read<AppState>();
    final me = s.user;
    if (me == null) return null;
    final p = P.of(context);

    // ---------- Pembeli
    if (isBuyer) {
      switch (o.status) {
        case OrderStatus.waiting:
          return GlassCard(
            child: Row(children: [
              Expanded(child: Btn('Edit', kind: BtnKind.outline, expand: true,
                  onTap: () => pushPage(context, OrderFormScreen(edit: o)))),
              const SizedBox(width: 10),
              Expanded(child: Btn('Batalkan', kind: BtnKind.danger, expand: true, busy: _busy, onTap: () async {
                if (await _confirm('Batalkan order?', 'Order akan dibatalkan sebelum diambil penjastip.', 'Ya, Batalkan')) {
                  await _run(() => s.repo.cancelOrder(o, me.name), 'Order dibatalkan.');
                }
              })),
            ]),
          );
        case OrderStatus.taken:
          return GlassCard(
            child: Btn('Batalkan Order', kind: BtnKind.danger, expand: true, busy: _busy, onTap: () async {
              if (await _confirm('Batalkan order?', 'Penjastip akan diberi tahu.', 'Ya, Batalkan')) {
                await _run(() => s.repo.cancelOrder(o, me.name), 'Order dibatalkan.');
              }
            }),
          );
        case OrderStatus.awaitingPayment:
          return _PayPanel(order: o);
        case OrderStatus.held:
          return GlassCard(
            child: Btn('Batalkan & Refund Penuh', kind: BtnKind.danger, expand: true, busy: _busy, onTap: () async {
              if (await _confirm('Batalkan & refund?',
                  'Selama penjastip belum membeli barang, dana dikembalikan penuh ke kamu.', 'Ya, Refund')) {
                await _run(() => s.repo.cancelOrder(o, me.name), 'Dana dikembalikan penuh.');
              }
            }),
          );
        case OrderStatus.shipped:
        case OrderStatus.received:
          return GlassCard(
            child: Column(children: [
              Btn('Konfirmasi Diterima', icon: Icons.check_circle_outline_rounded, expand: true, large: true,
                  busy: _busy, onTap: () async {
                if (await _confirm('Barang sudah diterima?',
                    'Dana ${rupiah(o.sellerNet)} akan dilepas ke penjastip (dikurangi komisi aplikasi).', 'Ya, Diterima')) {
                  await _run(() => s.repo.confirmReceived(o), 'Terima kasih! Dana dilepas ke penjastip.');
                }
              }),
              const SizedBox(height: 10),
              Btn('Ajukan Komplain', icon: Icons.flag_outlined, kind: BtnKind.danger, expand: true,
                  onTap: () => pushPage(context, ComplaintScreen(order: o))),
            ]),
          );
        case OrderStatus.complaint:
          return _demoAdmin(context, o);
        default:
          return null;
      }
    }

    // ---------- Penjastip
    if (isSeller) {
      switch (o.status) {
        case OrderStatus.taken:
          return GlassCard(
            child: Column(children: [
              Btn('Kirim Rincian Biaya', icon: Icons.request_quote_outlined, expand: true, large: true,
                  onTap: () => showFeesSheet(context, o)),
              const SizedBox(height: 10),
              Btn('Lepas Order', kind: BtnKind.danger, expand: true, busy: _busy, onTap: () async {
                if (await _confirm('Batalkan order?', 'Order dibatalkan dan pembeli diberi tahu.', 'Ya, Batalkan')) {
                  await _run(() => s.repo.cancelOrder(o, me.name), 'Order dibatalkan.');
                }
              }),
            ]),
          );
        case OrderStatus.awaitingPayment:
          return GlassCard(
            child: Row(children: [
              Icon(Icons.hourglass_top_rounded, color: p.amberText),
              const SizedBox(width: 12),
              Expanded(child: Text('Menunggu pembeli menyetujui & membayar rincian biaya.', style: tx(12, color: p.muted, h: 1.4))),
              Btn('Ubah', kind: BtnKind.outline, onTap: () => showFeesSheet(context, o)),
            ]),
          );
        case OrderStatus.held:
          return GlassCard(
            child: Btn('Unggah Bukti Pembelian', icon: Icons.upload_file_rounded, expand: true, large: true,
                onTap: () => pushPage(context, EvidenceScreen(order: o, shipping: false))),
          );
        case OrderStatus.purchased:
          return GlassCard(
            child: Btn('Kirim Barang & Unggah Resi', icon: Icons.local_shipping_outlined, expand: true, large: true,
                onTap: () => pushPage(context, EvidenceScreen(order: o, shipping: true))),
          );
        case OrderStatus.complaint:
          return _demoAdmin(context, o);
        default:
          return null;
      }
    }
    return null;
  }

  /// Panel admin berada di web (di luar cakupan app); di mode demo disimulasikan di sini.
  Widget? _demoAdmin(BuildContext context, Order o) {
    final s = context.read<AppState>();
    if (!s.repo.demo) {
      return GlassCard(
        child: Text('Komplain sedang ditinjau tim admin melalui panel admin (web).',
            style: tx(12, color: P.of(context).muted, h: 1.4)),
      );
    }
    return GlassCard(
      tint: P.indigo.withOpacity(0.10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Simulasi keputusan admin (mode demo)',
            style: tx(13, w: FontWeight.w700, color: P.of(context).ink)),
        const SizedBox(height: 4),
        Text('"${o.complaintReason}": ${o.complaintDesc}',
            style: tx(12, color: P.of(context).muted, h: 1.4)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Btn('Refund Penuh', kind: BtnKind.danger, expand: true, busy: _busy,
              onTap: () => _run(() => s.repo.adminDecide(o, true), 'Refund penuh ke pembeli.'))),
          const SizedBox(width: 10),
          Expanded(child: Btn('Rilis ke Penjastip', expand: true, busy: _busy,
              onTap: () => _run(() => s.repo.adminDecide(o, false), 'Dana dirilis ke penjastip.'))),
        ]),
      ]),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    const labels = ['Menunggu', 'Diambil', 'Bayar', 'Dibeli', 'Dikirim', 'Selesai'];
    final cancelled = status == OrderStatus.cancelled;
    final cur = status.step;
    return Row(children: [
      for (var i = 0; i < labels.length; i++) ...[
        Expanded(
          child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: i == cur ? 26 : 20,
              height: i == cur ? 26 : 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cancelled
                    ? p.line
                    : i <= cur
                        ? P.emerald
                        : p.field,
                border: Border.all(color: i <= cur && !cancelled ? P.emerald : p.line),
                boxShadow: i == cur && !cancelled
                    ? [BoxShadow(color: P.emerald.withOpacity(0.45), blurRadius: 12)]
                    : null,
              ),
              child: Icon(i < cur && !cancelled ? Icons.check_rounded : Icons.circle,
                  size: i < cur && !cancelled ? 13 : 6,
                  color: i <= cur && !cancelled ? Colors.white : Colors.transparent),
            ),
            const SizedBox(height: 5),
            Text(labels[i],
                style: tx(9, w: i == cur ? FontWeight.w700 : FontWeight.w500,
                    color: i <= cur && !cancelled ? p.ink : p.muted)),
          ]),
        ),
      ],
    ]);
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.order, this.seller = false});
  final Order order;
  final bool seller;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final o = order;
    Widget row(String l, String v, {bool bold = false, Color? c}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(l, style: tx(12, color: bold ? p.ink : p.muted, w: bold ? FontWeight.w700 : FontWeight.w400))),
            Text(v, style: tx(bold ? 15 : 12, w: bold ? FontWeight.w700 : FontWeight.w500, color: c ?? p.ink)),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.receipt_outlined, size: 17, color: p.accent),
        const SizedBox(width: 8),
        Text('Rincian biaya', style: tx(15, w: FontWeight.w700, color: p.ink)),
      ]),
      const SizedBox(height: 8),
      row('Harga barang', rupiah(o.itemPrice)),
      row('Fee jasa', rupiah(o.serviceFee)),
      row('Ongkos kirim', rupiah(o.shippingFee)),
      row('Biaya payment gateway', rupiah(o.gatewayFee)),
      Divider(color: p.line, height: 16),
      row('Total tagihan', rupiah(o.total), bold: true),
      if (seller) ...[
        const SizedBox(height: 6),
        row('Komisi aplikasi (5% fee)', '- ${rupiah(o.commission)}'),
        row('Pendapatan bersih', rupiah(o.sellerNet), bold: true, c: p.accent),
      ],
      if (o.payMethod.isNotEmpty) ...[
        const SizedBox(height: 6),
        row('Metode bayar', o.payMethod),
      ],
    ]);
  }
}

/// Persetujuan biaya + pembayaran escrow (simulasi sandbox) - FR-70/71/72.
class _PayPanel extends StatefulWidget {
  const _PayPanel({required this.order});
  final Order order;
  @override
  State<_PayPanel> createState() => _PayPanelState();
}

class _PayPanelState extends State<_PayPanel> {
  static const _methods = [
    ['Virtual Account BCA', Icons.account_balance_outlined],
    ['GoPay / e-wallet', Icons.account_balance_wallet_outlined],
    ['QRIS', Icons.qr_code_2_rounded],
  ];
  int _m = 0;
  bool _agree = false;
  bool _busy = false;

  Future<void> _pay() async {
    final s = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await Future.delayed(const Duration(milliseconds: 900)); // simulasi gateway
      await s.repo.payOrder(widget.order, _methods[_m][0] as String);
      if (mounted) toast(context, 'Pembayaran berhasil. Dana ditahan Justips.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await context.read<AppState>().repo.rejectFees(widget.order);
      if (mounted) toast(context, 'Rincian biaya ditolak.');
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
    return GlassCard(
      tint: P.amber.withOpacity(0.10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.verified_user_outlined, size: 18, color: p.amberText),
          const SizedBox(width: 8),
          Text('Persetujuan & Pembayaran', style: tx(15, w: FontWeight.w700, color: p.ink)),
        ]),
        const SizedBox(height: 4),
        Text('Total ${rupiah(o.total)} ditahan aplikasi (escrow) sampai barang kamu terima.',
            style: tx(12, color: p.muted, h: 1.4)),
        const SizedBox(height: 14),
        for (var i = 0; i < _methods.length; i++)
          PressScale(
            onTap: () => setState(() => _m = i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _m == i ? P.emerald.withOpacity(0.14) : p.field,
                border: Border.all(color: _m == i ? P.emerald : p.line, width: _m == i ? 1.5 : 1),
              ),
              child: Row(children: [
                Icon(_methods[i][1] as IconData, size: 19, color: _m == i ? p.accent : p.muted),
                const SizedBox(width: 12),
                Expanded(child: Text(_methods[i][0] as String, style: tx(13, w: FontWeight.w600, color: p.ink))),
                Icon(_m == i ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 19, color: _m == i ? p.accent : p.muted),
              ]),
            ),
          ),
        const SizedBox(height: 4),
        PressScale(
          onTap: () => setState(() => _agree = !_agree),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(_agree ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 22, color: _agree ? p.accent : p.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Saya menyetujui rincian biaya & kebijakan refund: batal sebelum barang dibeli = refund penuh; barang salah/rusak = sesuai mediasi; berubah pikiran (barang sesuai) = tidak dapat dikembalikan.',
                  style: tx(11, color: p.muted, h: 1.4)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Btn('Tolak', kind: BtnKind.danger, expand: true, large: true, onTap: _busy ? null : _reject)),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Btn('Bayar ${rupiah(o.total)}', kind: BtnKind.amber, expand: true, large: true,
                busy: _busy, onTap: _agree ? _pay : null),
          ),
        ]),
        const SizedBox(height: 8),
        Text('Pembayaran simulasi (sandbox) - tanpa dana nyata.', style: tx(10, color: p.muted)),
      ]),
    );
  }
}
