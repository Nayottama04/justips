import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/picker.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key, required this.order});
  final Order order;

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  static const _reasons = ['Barang salah', 'Barang rusak', 'Tidak sesuai bukti', 'Barang tidak sampai', 'Lainnya'];
  String _reason = _reasons.first;
  final _desc = TextEditingController();
  List<String> _files = [];
  bool _busy = false;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await context.read<AppState>().repo.fileComplaint(widget.order, _reason, _desc.text, _files);
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, 'Komplain diajukan. Dana tetap ditahan selama ditinjau.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return PageShell(
      title: 'Ajukan Komplain',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          GlassCard(
            tint: P.danger.withOpacity(0.08),
            child: Row(children: [
              Icon(Icons.shield_outlined, color: p.dangerInk),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Selama komplain terbuka, dana tetap ditahan. Admin menilai bukti & chat lalu memutuskan refund, rilis, atau sebagian.',
                    style: tx(12, color: p.muted, h: 1.4)),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.order.itemName, style: tx(15, w: FontWeight.w700, color: p.ink)),
              const SizedBox(height: 14),
              Text('Alasan', style: tx(12, w: FontWeight.w600, color: p.muted)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final r in _reasons)
                  FilterPill(r, selected: _reason == r, onTap: () => setState(() => _reason = r)),
              ]),
              const SizedBox(height: 16),
              GlassField(controller: _desc, label: 'Deskripsi masalah', maxLines: 4,
                  hint: 'Ceritakan detail masalahnya (min. 10 karakter)'),
              const SizedBox(height: 16),
              Text('Foto bukti', style: tx(12, w: FontWeight.w600, color: p.muted)),
              const SizedBox(height: 8),
              PhotoPicker(paths: _files, onChanged: (v) => setState(() => _files = v)),
            ]),
          ),
          const SizedBox(height: 20),
          Btn('Kirim Komplain', expand: true, large: true, kind: BtnKind.danger,
              busy: _busy, icon: Icons.flag_outlined, onTap: _submit),
        ],
      ),
    );
  }
}
