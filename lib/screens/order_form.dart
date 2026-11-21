import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

/// Form buat/edit order (nama item, deskripsi, link contoh, lokasi + catatan).
class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key, this.edit, this.copyFrom});
  final Order? edit;
  final Order? copyFrom;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _link = TextEditingController();
  final _price = TextEditingController();
  final _loc = TextEditingController();
  final _note = TextEditingController();
  final _addr = TextEditingController();
  bool _busy = false;

  static const _places = [
    'Bandung', 'Jakarta', 'Surabaya', 'Yogyakarta', 'Bali', 'Medan', 'Singapura',
    'Kuala Lumpur', 'Bangkok', 'Tokyo', 'Seoul', 'Hong Kong', 'Sydney',
  ];

  @override
  void initState() {
    super.initState();
    final src = widget.edit ?? widget.copyFrom;
    if (src != null) {
      _name.text = src.itemName;
      _desc.text = src.description;
      _link.text = src.linkUrl;
      _price.text = src.estimatedPrice == 0 ? '' : rupiah(src.estimatedPrice).substring(3);
      _loc.text = src.locationLabel;
      _note.text = src.locationNote;
      _addr.text = src.deliveryAddress;
    } else {
      _addr.text = context.read<AppState>().user?.address ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _link, _price, _loc, _note, _addr]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final me = s.user;
    if (me == null) return;
    setState(() => _busy = true);
    try {
      if (widget.edit != null) {
        await s.repo.updateOrder(widget.edit!, {
          'itemName': _name.text.trim(),
          'description': _desc.text.trim(),
          'linkUrl': _link.text.trim(),
          'locationLabel': _loc.text.trim(),
          'locationNote': _note.text.trim(),
          'estimatedPrice': parseRupiah(_price.text),
          'deliveryAddress': _addr.text.trim(),
        });
      } else {
        await s.repo.createOrder(
          me,
          itemName: _name.text,
          description: _desc.text,
          link: _link.text,
          locationLabel: _loc.text,
          locationNote: _note.text,
          estimatedPrice: parseRupiah(_price.text),
          deliveryAddress: _addr.text,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, widget.edit != null ? 'Order diperbarui.' : 'Order dibuat. Penjastip akan segera melihatnya.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final q = _loc.text.trim().toLowerCase();
    final suggestions = _places.where((e) => q.isEmpty || e.toLowerCase().contains(q)).take(8).toList();

    return PageShell(
      title: widget.edit != null ? 'Edit Order' : 'Buat Order',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Reveal(
                child: GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    GlassField(controller: _name, label: 'Nama item', hint: 'Mis. Sneakers Retro Minimalist',
                        icon: Icons.shopping_bag_outlined, action: TextInputAction.next, validator: _req),
                    const SizedBox(height: 14),
                    GlassField(controller: _desc, label: 'Deskripsi', maxLines: 3,
                        hint: 'Varian, ukuran, jumlah, catatan khusus', validator: _req),
                    const SizedBox(height: 14),
                    GlassField(controller: _link, label: 'Link contoh item (opsional)', hint: 'https://...',
                        icon: Icons.link_rounded, keyboard: TextInputType.url, action: TextInputAction.next),
                    const SizedBox(height: 14),
                    GlassField(
                      controller: _price,
                      label: 'Estimasi harga barang',
                      hint: '0',
                      icon: Icons.payments_outlined,
                      keyboard: TextInputType.number,
                      formatters: [RupiahInputFormatter()],
                      validator: (v) => parseRupiah(v ?? '') <= 0 ? 'Isi perkiraan harga' : null,
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              Reveal(
                index: 1,
                child: GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.place_outlined, size: 18, color: p.accent),
                      const SizedBox(width: 8),
                      Text('Lokasi pembelian', style: tx(15, w: FontWeight.w700, color: p.ink)),
                    ]),
                    const SizedBox(height: 12),
                    GlassField(
                      controller: _loc,
                      hint: 'Cari kota / alamat',
                      icon: Icons.search_rounded,
                      onChanged: (_) => setState(() {}),
                      validator: _req,
                    ),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final e in suggestions)
                        FilterPill(e, selected: _loc.text.trim() == e, onTap: () => setState(() => _loc.text = e)),
                    ]),
                    const SizedBox(height: 14),
                    GlassField(controller: _note, label: 'Catatan lokasi', maxLines: 2,
                        hint: 'Nama toko, lantai, patokan'),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              Reveal(
                index: 2,
                child: GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: GlassField(controller: _addr, label: 'Alamat pengiriman', maxLines: 2,
                      hint: 'Alamat tujuan barang', icon: Icons.home_outlined, validator: _req),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                  'Pemilihan lokasi lewat peta interaktif membutuhkan API key Google Maps; pada versi ini lokasi dipilih lewat pencarian kota/alamat + catatan teks.',
                  style: tx(11, color: p.muted, h: 1.4)),
              const SizedBox(height: 20),
              Btn(widget.edit != null ? 'Simpan Perubahan' : 'Kirim Order',
                  expand: true, large: true, busy: _busy, icon: Icons.send_rounded, onTap: _submit),
            ]),
          ),
        ],
      ),
    );
  }
}
