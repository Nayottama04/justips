import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'auth.dart';
import 'evidence.dart';
import 'kyc.dart';
import 'nav.dart';
import 'order_card.dart';
import 'order_form.dart';
import 'seller_flow.dart';
import 'wallet.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (!s.loggedIn) return const VisitorHome();
    if (s.user == null) return const Loading();
    return s.seller ? const SellerHome() : const UserHome();
  }
}

// ---------------------------------------------------------------- Header
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = P.of(context);
    final u = s.user;
    final themeBtn = GlassIconButton(
      p.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      onTap: () => context.read<ThemeController>().toggle(context),
    );

    if (u == null) {
      return Row(children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [P.emeraldDeep, P.emerald]),
          ),
          child: Text('J', style: tx(20, w: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Justips', style: tx(18, w: FontWeight.w700, color: p.ink, ls: -0.4)),
            Text('Jasa titip, dana aman', style: tx(12, color: p.muted)),
          ]),
        ),
        themeBtn,
        const SizedBox(width: 8),
        Btn('Login', icon: Icons.login_rounded, onTap: () => requireLogin(context)),
      ]);
    }

    return Row(children: [
      Avatar(name: u.name, photoUrl: u.photoUrl, size: 42, verified: u.kycOk),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text('Halo, ${u.firstName}',
                  overflow: TextOverflow.ellipsis,
                  style: tx(18, w: FontWeight.w700, color: p.ink, ls: -0.4)),
            ),
            const SizedBox(width: 6),
            Pill('Lv.${u.level} ${u.levelName}'),
          ]),
          Text(s.seller ? 'Mode Penjastip' : 'Justips Buyer', style: tx(12, color: p.muted)),
        ]),
      ),
      GlassIconButton(Icons.swap_horiz_rounded, onTap: () {
        s.setSeller(!s.seller);
        toast(context, s.seller ? 'Beralih ke mode Penjastip' : 'Beralih ke mode Pembeli');
      }),
      const SizedBox(width: 8),
      themeBtn,
    ]);
  }
}

void showEscrowInfo(BuildContext context) {
  final p = P.of(context);
  Widget row(IconData i, String t, String d) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: P.emerald.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(i, size: 19, color: p.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: tx(14, w: FontWeight.w600, color: p.ink)),
              const SizedBox(height: 2),
              Text(d, style: tx(12, color: p.muted, h: 1.4)),
            ]),
          ),
        ]),
      );
  showGlassSheet<void>(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Dana Aman dengan Escrow', style: tx(20, w: FontWeight.w700, color: p.ink, ls: -0.4)),
      const SizedBox(height: 6),
      Text('Justips menjadi pihak ketiga yang menahan dana kamu.', style: tx(13, color: p.muted)),
      const SizedBox(height: 18),
      row(Icons.lock_outline_rounded, 'Dana ditahan', 'Uangmu tidak langsung ke penjastip, tetapi ditahan sampai barang kamu terima.'),
      row(Icons.verified_user_outlined, 'Penjastip terverifikasi', 'Penjastip wajib KYC (OTP, KTP, swafoto) dan dibatasi sistem level.'),
      row(Icons.receipt_long_outlined, 'Bukti wajib', 'Struk pembelian dan resi pengiriman wajib diunggah di setiap tahap.'),
      row(Icons.support_agent_outlined, 'Komplain & mediasi', 'Bila ada masalah, dana tetap ditahan sampai admin memutuskan.'),
      Text('Komisi aplikasi 5% dari fee jasa + biaya gateway yang ditampilkan transparan. Mode ini adalah simulasi (sandbox), tanpa dana nyata.',
          style: tx(11, color: p.muted, h: 1.4)),
    ]),
  );
}

// ---------------------------------------------------------------- Pengunjung
class VisitorHome extends StatelessWidget {
  const VisitorHome({super.key});

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    Widget step(int n, IconData i, String t, String d) => Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            radius: 20,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: P.emerald.withOpacity(0.16), borderRadius: BorderRadius.circular(11)),
                  child: Icon(i, size: 18, color: p.accent),
                ),
                const Spacer(),
                Text('0$n', style: tx(20, w: FontWeight.w800, color: p.muted.withOpacity(0.35))),
              ]),
              const SizedBox(height: 10),
              Text(t, style: tx(13, w: FontWeight.w700, color: p.ink)),
              const SizedBox(height: 3),
              Text(d, style: tx(11, color: p.muted, h: 1.35)),
            ]),
          ),
        );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
        children: [
          const TopBar(),
          const SizedBox(height: 22),
          Reveal(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [P.emeraldDeep, P.emerald, Color(0xFF14B8A6)]),
                boxShadow: [BoxShadow(color: P.emerald.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 14))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(99)),
                  child: Text('Escrow Justips', style: tx(11, w: FontWeight.w600, color: Colors.white, ls: 0.4)),
                ),
                const SizedBox(height: 14),
                Text('Titip belanjaan ke penjastip terpercaya',
                    style: tx(26, w: FontWeight.w800, color: Colors.white, ls: -0.8, h: 1.12)),
                const SizedBox(height: 10),
                Text('Uangmu ditahan aplikasi sampai barang tiba dengan selamat.',
                    style: tx(13, color: Colors.white.withOpacity(0.9), h: 1.45)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: PressScale(
                      onTap: () => requireLogin(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Text('Masuk', style: tx(14, w: FontWeight.w700, color: P.emeraldDeep)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressScale(
                      onTap: () => pushPage(context, const RegisterScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(16)),
                        child: Text('Daftar', style: tx(14, w: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 26),
          Text('Cara kerja', style: tx(22, w: FontWeight.w700, color: p.ink, ls: -0.5)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            step(1, Icons.edit_note_rounded, 'Buat order', 'Tulis barang & lokasi yang kamu mau.'),
            const SizedBox(width: 12),
            step(2, Icons.handshake_outlined, 'Penjastip ambil', 'Diskusi lewat chat, lalu setujui biaya.'),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            step(3, Icons.lock_outline_rounded, 'Bayar aman', 'Dana ditahan sampai barang diterima.'),
            const SizedBox(width: 12),
            step(4, Icons.inventory_2_outlined, 'Konfirmasi', 'Terima barang, dana diteruskan.'),
          ]),
          const SizedBox(height: 22),
          GlassCard(
            onTap: () => showEscrowInfo(context),
            child: Row(children: [
              Icon(Icons.shield_outlined, color: p.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kenapa dana saya aman?', style: tx(14, w: FontWeight.w700, color: p.ink)),
                  Text('Pelajari escrow, KYC, bukti wajib & mediasi.', style: tx(12, color: p.muted)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: p.muted),
            ]),
          ),
          const SizedBox(height: 14),
          EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Belum ada order',
            message: 'Masuk untuk membuat order pertamamu atau menjadi penjastip.',
            action: Btn('Masuk sekarang', onTap: () => requireLogin(context)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Pembeli
class UserHome extends StatefulWidget {
  const UserHome({super.key});
  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _filter = 0;
  static const _labels = ['Semua', 'Aktif', 'Menunggu Bayar', 'Selesai', 'Dibatalkan'];

  bool _match(Order o) {
    switch (_filter) {
      case 1:
        return o.isActiveForBuyer;
      case 2:
        return o.status == OrderStatus.awaitingPayment;
      case 3:
        return o.status == OrderStatus.done || o.status == OrderStatus.received;
      case 4:
        return o.status == OrderStatus.cancelled;
      default:
        return true;
    }
  }

  int _count(List<Order> l, int f) {
    final old = _filter;
    _filter = f;
    final n = l.where(_match).length;
    _filter = old;
    return n;
  }

  List<Widget> _actions(Order o) {
    void detail() => openOrder(context, o.id);
    switch (o.status) {
      case OrderStatus.awaitingPayment:
        return [
          Btn('Detail', kind: BtnKind.outline, onTap: detail),
          Btn('Bayar Sekarang', kind: BtnKind.amber, onTap: detail),
        ];
      case OrderStatus.shipped:
        return [
          Btn('Detail', kind: BtnKind.outline, onTap: detail),
          Btn('Lacak Pesanan', icon: Icons.local_shipping_outlined, onTap: detail),
        ];
      case OrderStatus.done:
      case OrderStatus.received:
      case OrderStatus.cancelled:
        return [
          Btn('Detail', kind: BtnKind.outline, onTap: detail),
          Btn('Beli Lagi', icon: Icons.refresh_rounded, kind: BtnKind.soft,
              onTap: () => pushPage(context, OrderFormScreen(copyFrom: o))),
        ];
      case OrderStatus.waiting:
        return [
          Btn('Edit', kind: BtnKind.outline,
              onTap: () => pushPage(context, OrderFormScreen(edit: o))),
          Btn('Detail', kind: BtnKind.soft, onTap: detail),
        ];
      default:
        return [
          Btn('Detail', kind: BtnKind.outline, onTap: detail),
          Btn('Chat', icon: Icons.chat_bubble_outline_rounded, kind: BtnKind.soft,
              onTap: () => openChatForOrder(context, o)),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = P.of(context);
    final me = s.user!;

    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<Order>>(
        stream: s.repo.watchBuyerOrders(me.id),
        builder: (context, snap) {
          final all = snap.data ?? const <Order>[];
          final shown = all.where(_match).toList();
          final held = all.where((o) => o.fundsHeld).fold<int>(0, (a, o) => a + o.total);
          final done = all.where((o) => o.status == OrderStatus.done).length;

          return RefreshIndicator(
            color: P.emerald,
            onRefresh: () => Future.delayed(const Duration(milliseconds: 600)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
              children: [
                const TopBar(),
                const SizedBox(height: 18),
                Reveal(
                  child: GlassCard(
                    child: Row(children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                            color: P.emerald.withOpacity(0.16), borderRadius: BorderRadius.circular(15)),
                        child: Icon(Icons.lock_outline_rounded, color: p.accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('DANA DITAHAN', style: tx(11, w: FontWeight.w600, color: p.muted, ls: 0.6)),
                          const SizedBox(height: 2),
                          Text(rupiah(held), style: tx(20, w: FontWeight.w700, color: p.ink, ls: -0.3)),
                        ]),
                      ),
                      Container(width: 1, height: 34, color: p.line),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('ORDER SELESAI', style: tx(11, w: FontWeight.w600, color: p.muted, ls: 0.6)),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.star_rounded, size: 16, color: P.gold),
                          const SizedBox(width: 3),
                          Text('$done', style: tx(18, w: FontWeight.w700, color: P.gold)),
                        ]),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Reveal(
                  index: 1,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    radius: 18,
                    onTap: () => s.setTab(1),
                    child: Row(children: [
                      Icon(Icons.search_rounded, size: 19, color: p.muted),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Cari pesanan, barang, lokasi...', style: tx(14, color: p.muted))),
                      Icon(Icons.tune_rounded, size: 18, color: p.muted),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Reveal(
                  index: 2,
                  child: PressScale(
                    onTap: () => showEscrowInfo(context),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                            begin: Alignment.centerLeft, end: Alignment.centerRight,
                            colors: [P.emeraldDeep, P.emerald]),
                        boxShadow: [BoxShadow(color: P.emerald.withOpacity(0.30), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(99)),
                              child: Text('Justips Guarantee', style: tx(11, w: FontWeight.w600, color: Colors.white, ls: 0.4)),
                            ),
                            const SizedBox(height: 8),
                            Text('Dana aman sampai barang tiba',
                                style: tx(17, w: FontWeight.w700, color: Colors.white, ls: -0.2, h: 1.2)),
                            const SizedBox(height: 4),
                            Text('Escrow, KYC penjastip & mediasi komplain.',
                                style: tx(12, color: Colors.white.withOpacity(0.9))),
                          ]),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Pelajari', style: tx(12, w: FontWeight.w700, color: P.emeraldDeep)),
                            const SizedBox(width: 3),
                            const Icon(Icons.arrow_forward_rounded, size: 13, color: P.emeraldDeep),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SectionTitle('Order Saya',
                    sub: '(${all.where((o) => o.isActiveForBuyer).length} Aktif)',
                    trailing: Btn('Buat Order', icon: Icons.add_rounded,
                        onTap: () => pushPage(context, const OrderFormScreen()))),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _labels.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (c, i) {
                      final n = i == 0 || i == 4 ? '' : ' (${_count(all, i)})';
                      return FilterPill('${_labels[i]}$n',
                          selected: _filter == i, onTap: () => setState(() => _filter = i));
                    },
                  ),
                ),
                const SizedBox(height: 14),
                if (snap.connectionState == ConnectionState.waiting && all.isEmpty)
                  const Loading()
                else if (shown.isEmpty)
                  EmptyState(
                    icon: Icons.add_shopping_cart_rounded,
                    title: all.isEmpty ? 'Belum ada order' : 'Tidak ada order di filter ini',
                    message: all.isEmpty
                        ? 'Buat order pertamamu dan biarkan penjastip membelikan barangnya.'
                        : 'Coba pilih filter lain.',
                    action: all.isEmpty
                        ? Btn('Buat Order', icon: Icons.add_rounded,
                            onTap: () => pushPage(context, const OrderFormScreen()))
                        : null,
                  )
                else
                  for (var i = 0; i < shown.length; i++)
                    OrderCard(
                      index: i,
                      order: shown[i],
                      actions: _actions(shown[i]),
                      amountLabel: shown[i].hasFees ? 'Total Tagihan' : 'Estimasi Harga',
                      amount: shown[i].hasFees ? shown[i].total : shown[i].estimatedPrice,
                      amountColor: shown[i].status == OrderStatus.awaitingPayment ? p.amberText : null,
                    ),
                const SizedBox(height: 6),
                const _FlowStrip(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FlowStrip extends StatelessWidget {
  const _FlowStrip();

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    const steps = ['Menunggu', 'Diambil', 'Bayar', 'Dibeli', 'Dikirim', 'Diterima', 'Selesai'];
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline_rounded, size: 14, color: p.ink),
          const SizedBox(width: 5),
          Text('Alur Status Pesanan', style: tx(11, w: FontWeight.w600, color: p.ink, ls: 0.4)),
        ]),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < steps.length; i++) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.field,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: p.line),
                ),
                child: Text(steps[i], style: tx(10, w: FontWeight.w500, color: p.muted)),
              ),
              if (i != steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right_rounded, size: 14, color: p.muted),
                ),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- Penjastip
class SellerHome extends StatefulWidget {
  const SellerHome({super.key});
  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  int _seg = 0;
  int _limit = 8;

  List<Widget> _actions(Order o) {
    void detail() => openOrder(context, o.id);
    switch (o.status) {
      case OrderStatus.taken:
        return [
          Btn('Chat', kind: BtnKind.outline, onTap: () => openChatForOrder(context, o)),
          Btn('Kirim Rincian Biaya', icon: Icons.request_quote_outlined,
              onTap: () => showFeesSheet(context, o)),
        ];
      case OrderStatus.held:
        return [
          Btn('Detail', kind: BtnKind.outline, onTap: detail),
          Btn('Unggah Bukti Beli', icon: Icons.upload_file_rounded,
              onTap: () => pushPage(context, EvidenceScreen(order: o, shipping: false))),
        ];
      case OrderStatus.purchased:
        return [
          Btn('Detail', kind: BtnKind.outline, onTap: detail),
          Btn('Kirim Barang', icon: Icons.local_shipping_outlined,
              onTap: () => pushPage(context, EvidenceScreen(order: o, shipping: true))),
        ];
      default:
        return [
          Btn('Detail', kind: BtnKind.outline, onTap: detail),
          Btn('Chat', icon: Icons.chat_bubble_outline_rounded, kind: BtnKind.soft,
              onTap: () => openChatForOrder(context, o)),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = P.of(context);
    final me = s.user!;

    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<Order>>(
        stream: s.repo.watchOpenOrders(),
        builder: (context, openSnap) {
          return StreamBuilder<List<Order>>(
            stream: s.repo.watchSellerOrders(me.id),
            builder: (context, mineSnap) {
              final open = (openSnap.data ?? const <Order>[]).where((o) => o.buyerId != me.id).toList();
              final mine = mineSnap.data ?? const <Order>[];
              final list = _seg == 0 ? open : mine;

              return RefreshIndicator(
                color: P.emerald,
                onRefresh: () => Future.delayed(const Duration(milliseconds: 600)),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                  children: [
                    const TopBar(),
                    const SizedBox(height: 18),
                    Reveal(
                      child: GlassCard(
                        onTap: () => pushPage(context, const WalletScreen()),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('SALDO TERSEDIA', style: tx(11, w: FontWeight.w600, color: p.muted, ls: 0.6)),
                              const SizedBox(height: 2),
                              Text(rupiah(me.availableBalance),
                                  style: tx(22, w: FontWeight.w700, color: p.ink, ls: -0.4)),
                            ]),
                          ),
                          Container(width: 1, height: 34, color: p.line),
                          const SizedBox(width: 14),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('TERTAHAN', style: tx(11, w: FontWeight.w600, color: p.muted, ls: 0.6)),
                            const SizedBox(height: 2),
                            Text(rupiah(me.pendingBalance),
                                style: tx(15, w: FontWeight.w700, color: p.amberText)),
                          ]),
                          const SizedBox(width: 6),
                          Icon(Icons.chevron_right_rounded, color: p.muted),
                        ]),
                      ),
                    ),
                    if (!me.kycOk) ...[
                      const SizedBox(height: 12),
                      Reveal(
                        index: 1,
                        child: GlassCard(
                          tint: P.amber.withOpacity(0.14),
                          onTap: () => pushPage(context, const KycScreen()),
                          child: Row(children: [
                            Icon(Icons.badge_outlined, color: p.amberText),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(me.kycStatus == 'pending' ? 'Verifikasi sedang ditinjau' : 'Verifikasi identitas diperlukan',
                                    style: tx(13, w: FontWeight.w700, color: p.ink)),
                                Text('Lengkapi KYC agar bisa mengambil order & mencairkan saldo.',
                                    style: tx(12, color: p.muted, h: 1.35)),
                              ]),
                            ),
                            Icon(Icons.chevron_right_rounded, color: p.muted),
                          ]),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text('Order Masuk', style: tx(22, w: FontWeight.w700, color: p.ink, ls: -0.5)),
                    const SizedBox(height: 12),
                    Row(children: [
                      FilterPill('Order Masuk (${open.length})', selected: _seg == 0,
                          onTap: () => setState(() { _seg = 0; _limit = 8; })),
                      const SizedBox(width: 8),
                      FilterPill('Barang Diterima (${mine.length})', selected: _seg == 1,
                          onTap: () => setState(() { _seg = 1; _limit = 8; })),
                    ]),
                    const SizedBox(height: 14),
                    if ((openSnap.connectionState == ConnectionState.waiting) && list.isEmpty)
                      const Loading()
                    else if (list.isEmpty)
                      EmptyState(
                        icon: _seg == 0 ? Icons.inbox_outlined : Icons.inventory_2_outlined,
                        title: _seg == 0 ? 'Belum ada order masuk' : 'Belum ada barang diterima',
                        message: _seg == 0
                            ? 'Tarik ke bawah untuk memuat ulang. Order baru dari pembeli akan muncul di sini.'
                            : 'Order yang kamu ambil akan tampil di sini beserta statusnya.',
                      )
                    else ...[
                      for (var i = 0; i < list.length && i < _limit; i++)
                        _seg == 0
                            ? IncomingOrderCard(
                                index: i,
                                order: list[i],
                                onTaken: () => setState(() => _seg = 1),
                              )
                            : OrderCard(
                                index: i,
                                order: list[i],
                                actions: _actions(list[i]),
                                infoIcon: Icons.person_outline_rounded,
                                info: 'Pembeli: @${list[i].buyerUsername} • ${list[i].locationLabel}',
                                amountLabel: list[i].hasFees ? 'Pendapatan Bersih' : 'Estimasi Harga',
                                amount: list[i].hasFees ? list[i].sellerNet : list[i].estimatedPrice,
                              ),
                      if (list.length > _limit)
                        Center(
                          child: Btn('Tampilkan lebih banyak', kind: BtnKind.outline,
                              onTap: () => setState(() => _limit += 8)),
                        ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
