import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'nav.dart';

/// Pencarian order/barang berdasarkan nama item atau lokasi, mengikuti konteks Home aktif.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = P.of(context);
    final buyerMode = s.loggedIn && !s.seller;
    final stream = buyerMode ? s.repo.watchBuyerOrders(s.uid!) : s.repo.watchOpenOrders();
    final q = _q.text.trim().toLowerCase();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
        children: [
          Text('Cari', style: tx(28, w: FontWeight.w800, color: p.ink, ls: -0.9)),
          const SizedBox(height: 4),
          Text(buyerMode ? 'Cari di order milikmu' : 'Cari order terbuka berdasarkan barang atau lokasi',
              style: tx(13, color: p.muted)),
          const SizedBox(height: 14),
          GlassField(
            controller: _q,
            hint: 'Nama item atau lokasi...',
            icon: Icons.search_rounded,
            onChanged: (_) => setState(() {}),
            suffix: q.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: p.muted),
                    onPressed: () => setState(() => _q.clear()),
                  ),
          ),
          const SizedBox(height: 12),
          if (q.isEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in ['Bandung', 'Singapura', 'Sneakers', 'Jakarta', 'Kopi'])
                FilterPill(e, selected: false, onTap: () => setState(() => _q.text = e)),
            ]),
          const SizedBox(height: 14),
          StreamBuilder<List<Order>>(
            stream: stream,
            builder: (context, snap) {
              if (!snap.hasData) return const Loading();
              var list = snap.data!;
              if (q.isNotEmpty) {
                list = list
                    .where((o) =>
                        o.itemName.toLowerCase().contains(q) ||
                        o.locationLabel.toLowerCase().contains(q) ||
                        o.locationNote.toLowerCase().contains(q))
                    .toList();
              }
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Tidak ada hasil',
                  message: q.isEmpty ? 'Belum ada order untuk ditampilkan.' : 'Coba kata kunci lain.',
                );
              }
              return Column(children: [
                for (var i = 0; i < list.length; i++)
                  Reveal(
                    index: i,
                    child: GlassCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      radius: 20,
                      onTap: () async {
                        if (!await requireLogin(context)) return;
                        if (context.mounted) openOrder(context, list[i].id);
                      },
                      child: Row(children: [
                        SmartImage(list[i].imageUrl, size: 54, radius: 14, fallbackIcon: iconForItem(list[i].itemName)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(list[i].itemName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: tx(14, w: FontWeight.w600, color: p.ink)),
                            const SizedBox(height: 2),
                            Row(children: [
                              Icon(Icons.place_outlined, size: 12, color: p.muted),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(list[i].locationFull, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: tx(11, color: p.muted)),
                              ),
                            ]),
                            const SizedBox(height: 3),
                            Text(rupiah(list[i].estimatedPrice), style: tx(12, w: FontWeight.w700, color: p.ink)),
                          ]),
                        ),
                        StatusBadge(list[i].status),
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
