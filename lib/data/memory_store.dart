import 'dart:async';

import 'doc_store.dart';

class MemoryStore implements DocStore {
  final Map<String, Map<String, Map<String, dynamic>>> _db = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _n = 0;

  Map<String, Map<String, dynamic>> _col(String c) => _db.putIfAbsent(c, () => {});

  @override
  String newId() => 'id${DateTime.now().microsecondsSinceEpoch}_${_n++}';

  /// Dipakai oleh seeder (tanpa memicu stream).
  void seedDoc(String col, String id, Map<String, dynamic> data) {
    _col(col)[id] = {...data};
  }

  Map<String, dynamic> _merge(Map<String, dynamic> a, Map<String, dynamic> b) {
    final r = <String, dynamic>{...a};
    b.forEach((k, v) {
      final o = r[k];
      if (o is Map && v is Map) {
        r[k] = _merge(Map<String, dynamic>.from(o), Map<String, dynamic>.from(v));
      } else {
        r[k] = v;
      }
    });
    return r;
  }

  bool _match(Map<String, dynamic> m, String? field, Object? equals, Object? contains) {
    if (field == null) return true;
    final v = m[field];
    if (contains != null) return v is List && v.contains(contains);
    return v == equals;
  }

  List<Map<String, dynamic>> _query(
      String col, String? field, Object? equals, Object? contains) {
    final out = <Map<String, dynamic>>[];
    _col(col).forEach((id, m) {
      if (_match(m, field, equals, contains)) out.add({...m, 'id': id});
    });
    return out;
  }

  Stream<T> _watch<T>(T Function() read) {
    late StreamController<T> c;
    StreamSubscription<void>? sub;
    c = StreamController<T>(
      onListen: () {
        c.add(read());
        sub = _changes.stream.listen((_) {
          if (!c.isClosed) c.add(read());
        });
      },
      onCancel: () => sub?.cancel(),
    );
    return c.stream;
  }

  void _emit() => _changes.add(null);

  @override
  Stream<List<Map<String, dynamic>>> watchWhere(String col,
          {String? field, Object? equals, Object? contains}) =>
      _watch(() => _query(col, field, equals, contains));

  @override
  Stream<Map<String, dynamic>?> watchDoc(String col, String id) => _watch(() {
        final m = _col(col)[id];
        return m == null ? null : {...m, 'id': id};
      });

  @override
  Future<Map<String, dynamic>?> getDoc(String col, String id) async {
    final m = _col(col)[id];
    return m == null ? null : {...m, 'id': id};
  }

  @override
  Future<List<Map<String, dynamic>>> findWhere(
          String col, String field, Object equals) async =>
      _query(col, field, equals, null);

  @override
  Future<void> set(String col, String id, Map<String, dynamic> data) async {
    final cur = _col(col)[id];
    _col(col)[id] = cur == null ? {...data} : _merge(cur, data);
    _emit();
  }

  @override
  Future<void> update(String col, String id, Map<String, dynamic> data) async {
    final cur = _col(col)[id];
    if (cur == null) return;
    _col(col)[id] = _merge(cur, data);
    _emit();
  }

  @override
  Future<void> increment(String col, String id, String field, num delta) async {
    final cur = _col(col)[id];
    if (cur == null) return;
    final v = cur[field];
    cur[field] = (v is num ? v : 0) + delta;
    _emit();
  }

  @override
  Future<bool> updateIf(String col, String id, Map<String, dynamic> expected,
      Map<String, dynamic> updates) async {
    final cur = _col(col)[id];
    if (cur == null) return false;
    for (final e in expected.entries) {
      if (cur[e.key] != e.value) return false;
    }
    _col(col)[id] = _merge(cur, updates);
    _emit();
    return true;
  }

  @override
  Future<String> upload(String folder, String localPath) async => localPath;
}
