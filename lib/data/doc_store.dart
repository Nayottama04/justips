/// Abstraksi penyimpanan dokumen. Implementasi: Firestore (produksi) dan
/// MemoryStore (mode demo tanpa konfigurasi Firebase).
abstract class DocStore {
  String newId();

  Stream<List<Map<String, dynamic>>> watchWhere(String col,
      {String? field, Object? equals, Object? contains});

  Stream<Map<String, dynamic>?> watchDoc(String col, String id);

  Future<Map<String, dynamic>?> getDoc(String col, String id);

  Future<List<Map<String, dynamic>>> findWhere(String col, String field, Object equals);

  /// Upsert dengan merge (map bersarang digabung).
  Future<void> set(String col, String id, Map<String, dynamic> data);

  Future<void> update(String col, String id, Map<String, dynamic> data);

  Future<void> increment(String col, String id, String field, num delta);

  /// Atomic compare-and-set: update hanya bila semua field [expected] cocok.
  Future<bool> updateIf(String col, String id, Map<String, dynamic> expected,
      Map<String, dynamic> updates);

  /// Unggah berkas; mengembalikan URL (atau path lokal pada mode demo).
  Future<String> upload(String folder, String localPath);
}
