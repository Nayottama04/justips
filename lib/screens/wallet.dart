import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'kyc.dart';
import 'nav.dart';

/// Saldo penjastip: tertahan vs tersedia, rekening, pencairan, riwayat (FR-80..84).
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  IconData _icon(String t) => switch (t) {
        'release' => Icons.south_west_rounded,
        'escrow_in' => Icons.lock_outline_rounded,
        'withdraw' => Icons.north_east_rounded,
        'refund' => Icons.undo_rounded,
        _ => Icons.swap_horiz_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = P.of(context);
    final u = s.user;
    if (u == null) return const PageShell(title: 'Saldo', child: Loading());

    return PageShell(
      title: 'Saldo & Pencairan',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          Reveal(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [P.emeraldDeep, P.emerald, Color(0xFF14B8A6)]),
                boxShadow: [BoxShadow(color: P.emerald.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 12))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SALDO TERSEDIA', style: tx(11, w: FontWeight.w600, color: Colors.white70, ls: 0.8)),
                const SizedBox(height: 6),
                Text(rupiah(u.availableBalance), style: tx(32, w: FontWeight.w800, color: Colors.white, ls: -1)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.lock_clock_outlined, size: 18, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Saldo tertahan (menunggu konfirmasi)', style: tx(12, color: Colors.white))),
                    Text(rupiah(u.pendingBalance), style: tx(14, w: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
                const SizedBox(height: 16),
                PressScale(
                  onTap: () => showGlassSheet<void>(context, const _WithdrawSheet()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Text('Tarik Saldo', style: tx(14, w: FontWeight.w700, color: P.emeraldDeep)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            index: 1,
            child: GlassCard(
              onTap: () => showGlassSheet<void>(context, const _BankSheet()),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: P.emerald.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.account_balance_outlined, color: p.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u.bankNumber.isEmpty ? 'Tambah rekening pencairan' : '${u.bankName} • ${u.bankNumber}',
                        style: tx(14, w: FontWeight.w600, color: p.ink)),
                    Text(u.bankNumber.isEmpty ? 'Nama pemilik harus sama dengan nama KYC' : 'a.n. ${u.bankOwner}',
                        style: tx(12, color: p.muted)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: p.muted),
              ]),
            ),
          ),
          if (!u.kycOk) ...[
            const SizedBox(height: 14),
            GlassCard(
              tint: P.amber.withOpacity(0.14),
              onTap: () => pushPage(context, const KycScreen()),
              child: Row(children: [
                Icon(Icons.badge_outlined, color: p.amberText),
                const SizedBox(width: 12),
                Expanded(child: Text('Selesaikan KYC untuk mencairkan dana.', style: tx(13, w: FontWeight.w600, color: p.ink))),
                Icon(Icons.chevron_right_rounded, color: p.muted),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          Text('Pencairan', style: tx(18, w: FontWeight.w700, color: p.ink, ls: -0.3)),
          const SizedBox(height: 10),
          StreamBuilder<List<Withdrawal>>(
            stream: s.repo.watchWithdrawals(u.id),
            builder: (context, snap) {
              final l = snap.data ?? const <Withdrawal>[];
              if (l.isEmpty) {
                return const EmptyState(icon: Icons.south_east_rounded, title: 'Belum ada pencairan', message: 'Riwayat pencairan akan tampil di sini.');
              }
              return Column(children: [
                for (final w in l)
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    radius: 18,
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(rupiah(w.amount), style: tx(14, w: FontWeight.w700, color: p.ink)),
                          Text('${w.bank} • ${dateTimeFull(w.createdAt)}', style: tx(11, color: p.muted)),
                        ]),
                      ),
                      Builder(builder: (_) {
                        final c = w.status == 'success' ? P.emerald : w.status == 'failed' ? P.danger : P.amber;
                        final lbl = w.status == 'success' ? 'Berhasil' : w.status == 'failed' ? 'Gagal' : 'Diproses';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
                          child: Text(lbl, style: tx(11, w: FontWeight.w600, color: c)),
                        );
                      }),
                    ]),
                  ),
              ]);
            },
          ),
          const SizedBox(height: 16),
          Text('Mutasi saldo', style: tx(18, w: FontWeight.w700, color: p.ink, ls: -0.3)),
          const SizedBox(height: 10),
          StreamBuilder<List<LedgerEntry>>(
            stream: s.repo.watchLedger(u.id),
            builder: (context, snap) {
              final l = snap.data ?? const <LedgerEntry>[];
              if (l.isEmpty) {
                return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Belum ada mutasi', message: 'Dana tertahan, rilis, dan pencairan tercatat di sini.');
              }
              return GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(children: [
                  for (var i = 0; i < l.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: (l[i].amount >= 0 ? P.emerald : P.danger).withOpacity(0.13),
                              borderRadius: BorderRadius.circular(11)),
                          child: Icon(_icon(l[i].type), size: 17, color: l[i].amount >= 0 ? p.accent : p.dangerInk),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l[i].note, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: tx(12, w: FontWeight.w600, color: p.ink, h: 1.3)),
                            Text(dateTimeFull(l[i].createdAt), style: tx(10, color: p.muted)),
                          ]),
                        ),
                        Text('${l[i].amount >= 0 ? '+' : ''}${rupiah(l[i].amount)}',
                            style: tx(12, w: FontWeight.w700, color: l[i].amount >= 0 ? p.accent : p.dangerInk)),
                      ]),
                    ),
                    if (i != l.length - 1) Divider(height: 1, color: p.line),
                  ],
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BankSheet extends StatefulWidget {
  const _BankSheet();
  @override
  State<_BankSheet> createState() => _BankSheetState();
}

class _BankSheetState extends State<_BankSheet> {
  static const _banks = ['BCA', 'BRI', 'BNI', 'Mandiri', 'GoPay', 'OVO', 'DANA'];
  late String _bank;
  late final TextEditingController _no, _owner;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user!;
    _bank = u.bankName.isEmpty ? _banks.first : u.bankName;
    _no = TextEditingController(text: u.bankNumber);
    _owner = TextEditingController(text: u.bankOwner.isEmpty ? u.name : u.bankOwner);
  }

  @override
  void dispose() {
    _no.dispose();
    _owner.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await s.repo.saveBank(s.user!, _bank, _no.text, _owner.text);
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, 'Rekening disimpan. Ada masa tunggu sebelum pencairan berikutnya.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Rekening pencairan', style: tx(20, w: FontWeight.w700, color: p.ink, ls: -0.4)),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final b in _banks) FilterPill(b, selected: _bank == b, onTap: () => setState(() => _bank = b)),
      ]),
      const SizedBox(height: 14),
      GlassField(controller: _no, label: 'Nomor rekening / e-wallet', hint: '1234567890',
          keyboard: TextInputType.number, icon: Icons.numbers_rounded),
      const SizedBox(height: 12),
      GlassField(controller: _owner, label: 'Nama pemilik rekening', hint: 'Sesuai KTP', icon: Icons.person_outline_rounded),
      const SizedBox(height: 6),
      Text('Nama pemilik harus sama dengan nama pada verifikasi identitas.', style: tx(11, color: p.muted)),
      const SizedBox(height: 16),
      Btn('Simpan Rekening', expand: true, large: true, busy: _busy, onTap: _save),
    ]);
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();
  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amt = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amt.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final s = context.read<AppState>();
    final u = s.user!;
    // FR-83: verifikasi tambahan (PIN/OTP) - simulasi.
    if (_pin.text.trim() != AppConfig.demoOtp) {
      toast(context, 'PIN/OTP salah.');
      return;
    }
    setState(() => _busy = true);
    try {
      await s.repo.withdraw(u, parseRupiah(_amt.text));
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, 'Pencairan diproses.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final u = context.watch<AppState>().user!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tarik saldo', style: tx(20, w: FontWeight.w700, color: p.ink, ls: -0.4)),
      const SizedBox(height: 4),
      Text('Tersedia ${rupiah(u.availableBalance)}', style: tx(13, color: p.muted)),
      const SizedBox(height: 14),
      GlassField(controller: _amt, label: 'Jumlah', hint: '0', icon: Icons.payments_outlined,
          keyboard: TextInputType.number, formatters: [RupiahInputFormatter()]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: [
        for (final v in [100000, 500000, 1000000])
          FilterPill(rupiah(v).substring(3), selected: false,
              onTap: () => setState(() => _amt.text = rupiah(v).substring(3))),
        FilterPill('Semua', selected: false, onTap: () {
          final all = u.availableBalance - AppConfig.withdrawFee;
          setState(() => _amt.text = all > 0 ? rupiah(all).substring(3) : '');
        }),
      ]),
      const SizedBox(height: 12),
      Text('Minimal ${rupiah(AppConfig.minWithdraw)} • biaya admin ${rupiah(AppConfig.withdrawFee)}',
          style: tx(11, color: p.muted)),
      const SizedBox(height: 14),
      GlassField(controller: _pin, label: 'PIN / OTP', hint: 'Simulasi: ${AppConfig.demoOtp}',
          keyboard: TextInputType.number, obscure: true, icon: Icons.password_rounded),
      const SizedBox(height: 18),
      Btn(u.bankNumber.isEmpty ? 'Tambahkan rekening dulu' : 'Cairkan ke ${u.bankName}',
          expand: true, large: true, busy: _busy, onTap: u.bankNumber.isEmpty ? null : _go),
    ]);
  }
}
