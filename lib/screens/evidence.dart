import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/picker.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

/// Unggah bukti wajib: pembelian (struk + foto barang) atau pengiriman (resi) - FR-91.
class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key, required this.order, required this.shipping});
  final Order order;
  final bool shipping;

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  List<String> _files = [];
  final _resi = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _resi.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.read<AppState>();
    setState(() => _busy = true);
    try {
      if (widget.shipping) {
        await s.repo.markShipped(widget.order, _resi.text, _files);
      } else {
        await s.repo.markPurchased(widget.order, _files, _note.text);
      }
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, widget.shipping ? 'Barang ditandai dikirim.' : 'Bukti pembelian terunggah.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final ship = widget.shipping;
    return PageShell(
      title: ship ? 'Bukti Pengiriman' : 'Bukti Pembelian',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          GlassCard(
            child: Row(children: [
              SmartImage('', size: 48, radius: 14, fallbackIcon: iconForItem(widget.order.itemName)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.order.itemName, style: tx(15, w: FontWeight.w600, color: p.ink)),
                  Text(widget.order.code, style: tx(12, color: p.muted)),
                ]),
              ),
              StatusBadge(widget.order.status),
            ]),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ship ? 'Resi & foto paket' : 'Foto struk/nota & barang',
                  style: tx(15, w: FontWeight.w700, color: p.ink)),
              const SizedBox(height: 4),
              Text(
                  ship
                      ? 'Isi nomor resi atau unggah foto bukti pengiriman. Status tidak dapat maju tanpa bukti.'
                      : 'Wajib unggah minimal 1 foto (struk/nota dan foto barang saat dibeli).',
                  style: tx(12, color: p.muted, h: 1.4)),
              const SizedBox(height: 14),
              if (ship) ...[
                GlassField(controller: _resi, label: 'Nomor resi', hint: 'Mis. JNE 0123456789',
                    icon: Icons.local_shipping_outlined),
                const SizedBox(height: 14),
              ] else ...[
                GlassField(controller: _note, label: 'Catatan (opsional)', hint: 'Mis. beli di toko A, diskon 10%', maxLines: 2),
                const SizedBox(height: 14),
              ],
              PhotoPicker(paths: _files, onChanged: (v) => setState(() => _files = v)),
            ]),
          ),
          const SizedBox(height: 14),
          GlassCard(
            tint: P.emerald.withOpacity(0.10),
            child: Row(children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: p.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Dana pembeli tetap ditahan Justips sampai barang diterima.',
                    style: tx(12, color: p.muted, h: 1.4)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Btn(ship ? 'Tandai Dikirim' : 'Unggah Bukti', expand: true, large: true,
              busy: _busy, icon: Icons.cloud_upload_outlined, onTap: _submit),
        ],
      ),
    );
  }
}
