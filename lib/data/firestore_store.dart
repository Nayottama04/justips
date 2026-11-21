import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'doc_store.dart';
import 'image_store.dart';

class FirestoreStore implements DocStore {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic> _m(DocumentSnapshot<Map<String, dynamic>> d) =>
      {...(d.data() ?? <String, dynamic>{}), 'id': d.id};

  @override
  String newId() => _db.collection('_ids').doc().id;

  Query<Map<String, dynamic>> _q(String col, String? field, Object? equals, Object? contains) {
    Query<Map<String, dynamic>> q = _db.collection(col);
    if (field != null) {
      if (contains != null) {
        q = q.where(field, arrayContains: contains);
      } else {
        q = q.where(field, isEqualTo: equals);
      }
    }
    return q;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchWhere(String col,
          {String? field, Object? equals, Object? contains}) =>
      _q(col, field, equals, contains)
          .snapshots()
          .map((s) => s.docs.map((d) => _m(d)).toList());

  @override
  Stream<Map<String, dynamic>?> watchDoc(String col, String id) => _db
      .collection(col)
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? _m(d) : null);

  @override
  Future<Map<String, dynamic>?> getDoc(String col, String id) async {
    final d = await _db.collection(col).doc(id).get();
    return d.exists ? _m(d) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> findWhere(
      String col, String field, Object equals) async {
    final s = await _q(col, field, equals, null).get();
    return s.docs.map((d) => _m(d)).toList();
  }

  @override
  Future<void> set(String col, String id, Map<String, dynamic> data) =>
      _db.collection(col).doc(id).set(data, SetOptions(merge: true));

  @override
  Future<void> update(String col, String id, Map<String, dynamic> data) =>
      _db.collection(col).doc(id).update(data);

  @override
  Future<void> increment(String col, String id, String field, num delta) =>
      _db.collection(col).doc(id).update({field: FieldValue.increment(delta)});

  @override
  Future<bool> updateIf(String col, String id, Map<String, dynamic> expected,
      Map<String, dynamic> updates) {
    final ref = _db.collection(col).doc(id);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      final d = snap.data();
      if (d == null) return false;
      for (final e in expected.entries) {
        if (d[e.key] != e.value) return false;
      }
      tx.update(ref, updates);
      return true;
    });
  }

  /// Tanpa Firebase Storage: foto (sudah dikompres picker) disimpan base64 di koleksi `images`.
  @override
  Future<String> upload(String folder, String localPath) async {
    final bytes = await File(localPath).readAsBytes();
    final b64 = base64Encode(bytes);
    if (b64.length > 900000) {
      throw AppException('Foto terlalu besar. Pilih foto yang lebih kecil.');
    }
    final id = newId();
    await _db.collection('images').doc(id).set({
      'data': b64,
      'folder': folder,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    ImageStore.put(id, bytes);
    return 'img:$id';
  }
}
