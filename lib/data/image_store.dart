import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'doc_store.dart';

/// Foto disimpan sebagai base64 di koleksi Firestore `images` (tanpa Firebase Storage).
/// Dokumen lain hanya menyimpan referensi `img:<id>`; gambar dimuat sekali lalu di-cache di memori.
class ImageStore {
  static DocStore? store;
  static final Map<String, Uint8List> _mem = {};
  static final Map<String, Future<Uint8List?>> _pending = {};

  static Uint8List? cached(String id) => _mem[id];
  static void put(String id, Uint8List bytes) => _mem[id] = bytes;

  static Future<Uint8List?> load(String id) {
    final c = _mem[id];
    if (c != null) return Future.value(c);
    return _pending.putIfAbsent(id, () async {
      try {
        final d = await store?.getDoc('images', id);
        final s = d?['data'];
        if (s is! String) return null;
        final b = base64Decode(s);
        _mem[id] = b;
        return b;
      } catch (_) {
        return null;
      } finally {
        _pending.remove(id);
      }
    });
  }
}

class DbImage extends StatefulWidget {
  const DbImage({super.key, required this.id, required this.placeholder, this.cacheWidth});
  final String id;
  final Widget placeholder;
  final int? cacheWidth;

  @override
  State<DbImage> createState() => _DbImageState();
}

class _DbImageState extends State<DbImage> {
  late Future<Uint8List?> _f;

  @override
  void initState() {
    super.initState();
    _f = ImageStore.load(widget.id);
  }

  @override
  void didUpdateWidget(covariant DbImage old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) _f = ImageStore.load(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _f,
      initialData: ImageStore.cached(widget.id),
      builder: (context, snap) {
        final b = snap.data;
        if (b == null) return widget.placeholder;
        return Image.memory(b,
            fit: BoxFit.cover, cacheWidth: widget.cacheWidth, gaplessPlayback: true);
      },
    );
  }
}
