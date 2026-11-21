import 'dart:async';
import 'dart:math';

import 'package:rxdart/rxdart.dart';

import '../core/format.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'doc_store.dart';

/// Seluruh logika bisnis Justips: order, escrow, chat, notifikasi, saldo.
///
/// CATATAN KEAMANAN: untuk mock tugas kuliah, logika uang berjalan di klien.
/// Pada produksi, pindahkan escrow/saldo/pencairan ke Cloud Functions + payment
/// gateway berizin (Midtrans/Xendit) dan perketat Firestore Rules.
class Repository {
  Repository(this.store, this.auth, {required this.demo});
  final DocStore store;
  final AuthService auth;
  final bool demo;

  final Map<String, Stream<dynamic>> _cache = {};
  Stream<T> _c<T>(String key, Stream<T> Function() make) =>
      _cache.putIfAbsent(key, () => make().shareReplay(maxSize: 1)) as Stream<T>;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ------------------------------------------------------------ Streams
  Stream<AppUser?> watchUser(String uid) => _c<AppUser?>('user:$uid',
      () => store.watchDoc('users', uid).map((m) => m == null ? null : AppUser.fromMap(m)));

  List<Order> _orders(List<Map<String, dynamic>> l) {
    final r = l.map(Order.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return r;
  }

  Stream<List<Order>> watchBuyerOrders(String uid) => _c<List<Order>>('bo:$uid',
      () => store.watchWhere('orders', field: 'buyerId', equals: uid).map(_orders));

  Stream<List<Order>> watchSellerOrders(String uid) => _c<List<Order>>('so:$uid',
      () => store.watchWhere('orders', field: 'sellerId', equals: uid).map(_orders));

  Stream<List<Order>> watchOpenOrders() => _c<List<Order>>('open',
      () => store.watchWhere('orders', field: 'status', equals: 'waiting').map(_orders));

  Stream<Order?> watchOrder(String id) => _c<Order?>('order:$id',
      () => store.watchDoc('orders', id).map((m) => m == null ? null : Order.fromMap(m)));

  Stream<List<LedgerEntry>> watchOrderLedger(String orderId) => _c<List<LedgerEntry>>(
      'lo:$orderId',
      () => store.watchWhere('ledger', field: 'refId', equals: orderId).map(_ledgerList));

  Stream<List<LedgerEntry>> watchLedger(String uid) => _c<List<LedgerEntry>>('l:$uid',
      () => store.watchWhere('ledger', field: 'userId', equals: uid).map(_ledgerList));

  List<LedgerEntry> _ledgerList(List<Map<String, dynamic>> l) =>
      l.map(LedgerEntry.fromMap).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Stream<List<Withdrawal>> watchWithdrawals(String uid) => _c<List<Withdrawal>>(
      'w:$uid',
      () => store.watchWhere('withdrawals', field: 'userId', equals: uid).map((l) =>
          l.map(Withdrawal.fromMap).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt))));

  Stream<List<ChatRoom>> watchRooms(String uid) => _c<List<ChatRoom>>(
      'rooms:$uid',
      () => store.watchWhere('rooms', field: 'members', contains: uid).map((l) =>
          l.map(ChatRoom.fromMap).toList()
            ..sort((a, b) => (b.lastAt ?? DateTime(2000)).compareTo(a.lastAt ?? DateTime(2000)))));

  Stream<ChatRoom?> watchRoom(String id) => _c<ChatRoom?>('room:$id',
      () => store.watchDoc('rooms', id).map((m) => m == null ? null : ChatRoom.fromMap(m)));

  Stream<List<ChatMessage>> watchMessages(String roomId) => _c<List<ChatMessage>>(
      'msg:$roomId',
      () => store.watchWhere('messages', field: 'roomId', equals: roomId).map((l) =>
          l.map(ChatMessage.fromMap).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt))));

  Stream<List<NotificationItem>> watchNotifications(String uid) =>
      _c<List<NotificationItem>>(
          'n:$uid',
          () => store.watchWhere('notifications', field: 'userId', equals: uid).map((l) =>
              l.map(NotificationItem.fromMap).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt))));

  // ------------------------------------------------------------ Auth & profil
  Future<void> signIn(String identifier, String password) async {
    var email = identifier.trim();
    if (email.isEmpty || password.isEmpty) {
      throw AppException('Isi email dan kata sandi.');
    }
    if (!email.contains('@')) {
      if (!demo) throw AppException('Masuk menggunakan email.');
      final found = await store.findWhere('users', 'username', email.toLowerCase());
      if (found.isEmpty) throw AppException('Akun tidak ditemukan.');
      email = _s(found.first['email']);
    }
    await auth.signIn(email, password);
  }

  String _s(dynamic v) => v is String ? v : '';

  Future<void> register({
    required String name,
    required String email,
    required String username,
    required String address,
    required String phone,
    required String password,
  }) async {
    final uid = await auth.register(email.trim(), password);
    final uname = username.trim().toLowerCase();
    final dup = await store.findWhere('users', 'username', uname);
    if (dup.any((d) => d['id'] != uid)) {
      await auth.deleteCurrent();
      throw AppException('Username sudah dipakai.');
    }
    await store.set('users', uid, AppUser(
          id: uid,
          name: name.trim(),
          email: email.trim().toLowerCase(),
          username: uname,
          address: address.trim(),
          phone: phone.trim(),
        ).toMap());
    await _notify(uid, 'account', 'Selamat datang di Justips',
        'Akunmu siap dipakai. Lengkapi profil agar transaksi lebih lancar.', uid);
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) =>
      store.set('users', uid, data);

  Future<String> upload(String folder, String path) => store.upload(folder, path);

  Future<void> submitKyc(String uid, String ktpPath, String selfiePath) async {
    final ktp = await store.upload('kyc/$uid', ktpPath);
    final selfie = await store.upload('kyc/$uid', selfiePath);
    final id = store.newId();
    await store.set('kyc', id, {
      'userId': uid, 'ktp': ktp, 'selfie': selfie,
      'status': AppConfig.autoApproveKyc ? 'approved' : 'pending', 'createdAt': _now,
    });
    await store.set('users', uid,
        {'kycStatus': AppConfig.autoApproveKyc ? 'approved' : 'pending'});
    await _notify(uid, 'account',
        AppConfig.autoApproveKyc ? 'Verifikasi identitas disetujui' : 'Verifikasi sedang ditinjau',
        AppConfig.autoApproveKyc
            ? 'Kamu sekarang dapat mengambil order dan mencairkan saldo.'
            : 'Admin akan meninjau data KYC-mu.',
        uid);
  }

  Future<void> saveBank(AppUser me, String bank, String number, String owner) async {
    if (bank.trim().isEmpty || number.trim().length < 6) {
      throw AppException('Lengkapi bank dan nomor rekening.');
    }
    if (owner.trim().toLowerCase() != me.name.trim().toLowerCase()) {
      throw AppException('Nama pemilik rekening harus sama dengan nama pada verifikasi identitas (${me.name}).');
    }
    await store.set('users', me.id, {
      'bankName': bank.trim(), 'bankNumber': number.trim(), 'bankOwner': owner.trim(),
      'bankChangedAt': _now,
    });
  }

  // ------------------------------------------------------------ Order
  Future<String> createOrder(
    AppUser buyer, {
    required String itemName,
    required String description,
    required String link,
    required String locationLabel,
    required String locationNote,
    required int estimatedPrice,
    required String deliveryAddress,
  }) async {
    final id = store.newId();
    final code = '#ORD-${10000 + Random().nextInt(89999)}';
    final o = Order(
      id: id, code: code, buyerId: buyer.id, buyerName: buyer.name,
      buyerUsername: buyer.username, itemName: itemName.trim(),
      description: description.trim(), linkUrl: link.trim(),
      locationLabel: locationLabel.trim(), locationNote: locationNote.trim(),
      estimatedPrice: estimatedPrice, createdAt: DateTime.now(),
      deliveryAddress: deliveryAddress.trim(),
    );
    await store.set('orders', id, o.toMap());
    return id;
  }

  Future<void> updateOrder(Order o, Map<String, dynamic> data) async {
    if (o.status != OrderStatus.waiting) {
      throw AppException('Order tidak dapat diubah setelah diambil penjastip.');
    }
    await store.set('orders', o.id, data);
  }

  Future<void> takeOrder(Order o, AppUser me) async {
    if (!me.kycOk) {
      throw AppException('Selesaikan verifikasi identitas (KYC) sebelum mengambil order.');
    }
    if (o.buyerId == me.id) {
      throw AppException('Kamu tidak dapat mengambil order milikmu sendiri.');
    }
    if (o.estimatedPrice > me.maxOrderValue) {
      throw AppException('Melebihi batas level kamu (${rupiah(me.maxOrderValue)} per order).');
    }
    final mine = (await store.findWhere('orders', 'sellerId', me.id))
        .map(Order.fromMap)
        .where((x) => x.isActiveForSeller)
        .length;
    if (mine >= me.maxActive) {
      throw AppException('Batas order aktif level ${me.level} tercapai (${me.maxActive}).');
    }
    final ok = await store.updateIf('orders', o.id, {'status': 'waiting'}, {
      'status': 'taken', 'sellerId': me.id, 'sellerName': me.name, 'takenAt': _now,
    });
    if (!ok) throw AppException('Order sudah diambil penjastip lain.');
    final room = await ensureRoom(o, me.id, me.name);
    await _system(room.id, '${me.name} mengambil order ini. Kirim rincian biaya setelah menyepakati detail barang.');
    await _notify(o.buyerId, 'take', 'Order diambil penjastip',
        '${me.name} mengambil ${o.itemName}.', o.id);
  }

  Future<void> submitFees(Order o, int item, int fee, int ship) async {
    if (item <= 0) throw AppException('Isi harga barang.');
    final sub = item + fee + ship;
    final gateway = max(2500, (sub * 0.007).round());
    final ok = await store.updateIf('orders', o.id, {'status': o.status.name}, {
      'status': 'awaitingPayment', 'itemPrice': item, 'serviceFee': fee,
      'shippingFee': ship, 'gatewayFee': gateway,
    });
    if (!ok) throw AppException('Status order sudah berubah. Muat ulang halaman.');
    await _notify(o.buyerId, 'fees', 'Rincian biaya dikirim',
        'Setujui rincian biaya ${o.itemName} sebesar ${rupiah(sub + gateway)}.', o.id);
    await _system('${o.id}_${o.sellerId}', 'Rincian biaya dikirim: ${rupiah(sub + gateway)}.');
  }

  Future<void> rejectFees(Order o) async {
    await store.set('orders', o.id, {
      'status': 'taken', 'itemPrice': 0, 'serviceFee': 0, 'shippingFee': 0, 'gatewayFee': 0,
    });
    await _notify(o.sellerId, 'fees', 'Rincian biaya ditolak',
        '${o.buyerName} menolak rincian biaya ${o.itemName}. Ajukan ulang.', o.id);
    await _system('${o.id}_${o.sellerId}', 'Pembeli menolak rincian biaya. Silakan negosiasi lalu ajukan ulang.');
  }

  /// Simulasi pembayaran (sandbox) -> dana ditahan aplikasi (escrow).
  Future<void> payOrder(Order o, String method) async {
    final ok = await store.updateIf('orders', o.id, {'status': 'awaitingPayment'},
        {'status': 'held', 'payMethod': method, 'paidAt': _now});
    if (!ok) throw AppException('Order sudah dibayar atau berubah status.');
    await store.increment('users', o.sellerId, 'pendingBalance', o.sellerNet);
    await _ledger(o.sellerId, 'escrow_in', o.sellerNet, 'Dana tertahan - ${o.itemName}', o.id);
    await _ledger(o.buyerId, 'pay', -o.total, 'Pembayaran escrow - ${o.itemName}', o.id);
    await _notify(o.buyerId, 'pay', 'Pembayaran berhasil',
        'Dana ${rupiah(o.total)} ditahan Justips hingga barang diterima.', o.id);
    await _notify(o.sellerId, 'pay', 'Dana ditahan',
        'Pembeli sudah membayar ${o.itemName}. Silakan beli barangnya.', o.id);
    await _system('${o.id}_${o.sellerId}', 'Pembayaran diterima. Dana ditahan aplikasi.');
  }

  Future<void> cancelOrder(Order o, String byName) async {
    const allowed = [
      OrderStatus.waiting, OrderStatus.taken, OrderStatus.awaitingPayment, OrderStatus.held
    ];
    if (!allowed.contains(o.status)) {
      throw AppException('Order tidak dapat dibatalkan pada status ini.');
    }
    final ok = await store.updateIf('orders', o.id, {'status': o.status.name}, {'status': 'cancelled'});
    if (!ok) throw AppException('Status order sudah berubah.');
    if (o.status == OrderStatus.held) {
      await store.increment('users', o.sellerId, 'pendingBalance', -o.sellerNet);
      await _ledger(o.sellerId, 'refund', -o.sellerNet, 'Dana dikembalikan - ${o.itemName}', o.id);
      await _ledger(o.buyerId, 'refund', o.total, 'Refund penuh - ${o.itemName}', o.id);
    }
    final other = byName == o.buyerName ? o.sellerId : o.buyerId;
    if (other.isNotEmpty) {
      await _notify(other, 'status', 'Order dibatalkan', '${o.itemName} dibatalkan oleh $byName.', o.id);
    }
  }

  Future<void> markPurchased(Order o, List<String> files, String note) async {
    if (o.status != OrderStatus.held) {
      throw AppException('Order belum berstatus Dana Ditahan.');
    }
    if (files.isEmpty) throw AppException('Unggah foto struk/nota dan foto barang (wajib).');
    final ev = [...o.evidence];
    for (final f in files) {
      ev.add({'type': 'purchase', 'url': await store.upload('evidence/${o.id}', f), 'at': _now, 'note': note});
    }
    await store.set('orders', o.id, {'status': 'purchased', 'evidence': ev});
    await _notify(o.buyerId, 'status', 'Barang sudah dibeli',
        '${o.sellerName} sudah membeli ${o.itemName} dan mengunggah bukti.', o.id);
  }

  Future<void> markShipped(Order o, String tracking, List<String> files) async {
    if (o.status != OrderStatus.purchased) {
      throw AppException('Unggah bukti pembelian terlebih dahulu.');
    }
    if (tracking.trim().isEmpty && files.isEmpty) {
      throw AppException('Isi nomor resi atau unggah bukti pengiriman (wajib).');
    }
    final ev = [...o.evidence];
    for (final f in files) {
      ev.add({'type': 'shipping', 'url': await store.upload('evidence/${o.id}', f), 'at': _now, 'note': tracking});
    }
    await store.set('orders', o.id, {
      'status': 'shipped', 'shippedAt': _now, 'trackingNo': tracking.trim(), 'evidence': ev,
    });
    await _notify(o.buyerId, 'status', 'Pesanan dikirim',
        '${o.itemName} dikirim${tracking.trim().isEmpty ? '' : '. Resi ${tracking.trim()}'}.', o.id);
  }

  Future<void> confirmReceived(Order o) async {
    if (o.status != OrderStatus.shipped && o.status != OrderStatus.received) {
      throw AppException('Barang belum dikirim.');
    }
    await _release(o);
  }

  Future<void> _release(Order o) async {
    final ok = await store.updateIf('orders', o.id, {'status': o.status.name},
        {'status': 'done', 'receivedAt': o.receivedAt?.millisecondsSinceEpoch ?? _now});
    if (!ok) return;
    await store.increment('users', o.sellerId, 'pendingBalance', -o.sellerNet);
    await store.increment('users', o.sellerId, 'availableBalance', o.sellerNet);
    await store.increment('users', o.sellerId, 'completedOrders', 1);
    await _ledger(o.sellerId, 'release', o.sellerNet,
        'Dana dilepas (komisi ${rupiah(o.commission)}) - ${o.itemName}', o.id);
    await _notify(o.sellerId, 'wallet', 'Dana dilepas ke saldo',
        '${rupiah(o.sellerNet)} masuk ke Saldo Tersedia.', o.id);
    await _notify(o.buyerId, 'status', 'Order selesai', '${o.itemName} selesai. Terima kasih!', o.id);
  }

  Future<void> fileComplaint(Order o, String reason, String desc, List<String> files) async {
    if (desc.trim().length < 10) throw AppException('Jelaskan masalahmu minimal 10 karakter.');
    final ev = [...o.evidence];
    for (final f in files) {
      ev.add({'type': 'complaint', 'url': await store.upload('evidence/${o.id}', f), 'at': _now, 'note': reason});
    }
    await store.set('orders', o.id, {
      'status': 'complaint', 'complaintReason': reason, 'complaintDesc': desc.trim(), 'evidence': ev,
    });
    await _notify(o.buyerId, 'complaint', 'Komplain diajukan', 'Dana tetap ditahan selama komplain ditinjau.', o.id);
    await _notify(o.sellerId, 'complaint', 'Komplain diajukan',
        '${o.buyerName} mengajukan komplain untuk ${o.itemName}.', o.id);
  }

  /// Simulasi keputusan admin (panel admin web berada di luar cakupan aplikasi mobile).
  Future<void> adminDecide(Order o, bool refund) async {
    if (o.status != OrderStatus.complaint) return;
    if (!refund) {
      await _release(o);
      return;
    }
    await store.set('orders', o.id, {'status': 'cancelled'});
    await store.increment('users', o.sellerId, 'pendingBalance', -o.sellerNet);
    await store.increment('users', o.sellerId, 'complaints', 1);
    await _ledger(o.sellerId, 'refund', -o.sellerNet, 'Refund keputusan mediasi - ${o.itemName}', o.id);
    await _ledger(o.buyerId, 'refund', o.total, 'Refund keputusan mediasi - ${o.itemName}', o.id);
    await _notify(o.buyerId, 'complaint', 'Komplain diputuskan', 'Refund penuh disetujui admin.', o.id);
    await _notify(o.sellerId, 'complaint', 'Komplain diputuskan', 'Admin memutuskan refund ke pembeli.', o.id);
  }

  /// Konfirmasi otomatis (3x24 jam) dan rilis setelah jendela komplain (2x24 jam).
  Future<void> sweep(String uid) async {
    try {
      final all = <String, Order>{};
      for (final f in ['sellerId', 'buyerId']) {
        for (final m in await store.findWhere('orders', f, uid)) {
          final o = Order.fromMap(m);
          all[o.id] = o;
        }
      }
      final now = DateTime.now();
      for (final o in all.values) {
        if (o.status == OrderStatus.shipped &&
            o.shippedAt != null &&
            now.difference(o.shippedAt!) > AppConfig.autoConfirm) {
          final ok = await store.updateIf('orders', o.id, {'status': 'shipped'},
              {'status': 'received', 'receivedAt': _now});
          if (ok) {
            await _notify(o.buyerId, 'status', 'Konfirmasi otomatis',
                '${o.itemName} dikonfirmasi otomatis. Kamu masih bisa komplain 2x24 jam.', o.id);
            await _notify(o.sellerId, 'status', 'Konfirmasi otomatis',
                '${o.itemName} dikonfirmasi otomatis.', o.id);
          }
        } else if (o.status == OrderStatus.received &&
            o.receivedAt != null &&
            now.difference(o.receivedAt!) > AppConfig.complaintWindow) {
          await _release(o);
        }
      }
    } catch (_) {}
  }

  // ------------------------------------------------------------ Chat
  Future<ChatRoom> ensureRoom(Order o, String sellerId, String sellerName) async {
    final id = '${o.id}_$sellerId';
    final ex = await store.getDoc('rooms', id);
    if (ex != null) return ChatRoom.fromMap(ex);
    final data = <String, dynamic>{
      'orderId': o.id, 'itemName': o.itemName, 'buyerId': o.buyerId,
      'buyerName': o.buyerName, 'sellerId': sellerId, 'sellerName': sellerName,
      'members': [o.buyerId, sellerId], 'lastText': '', 'lastAt': _now,
      'unread': <String, dynamic>{o.buyerId: 0, sellerId: 0}, 'readAt': <String, dynamic>{},
    };
    await store.set('rooms', id, data);
    return ChatRoom.fromMap({...data, 'id': id});
  }

  Future<void> _system(String roomId, String text) async {
    await store.set('messages', store.newId(), {
      'roomId': roomId, 'senderId': 'system', 'text': text, 'system': true, 'createdAt': _now,
    });
    await store.set('rooms', roomId, {'lastText': text, 'lastAt': _now});
  }

  Future<void> sendMessage(ChatRoom room, AppUser me, {String text = '', String? imagePath}) async {
    final t = text.trim();
    if (t.isEmpty && imagePath == null) return;
    String url = '';
    if (imagePath != null) url = await store.upload('chat/${room.id}', imagePath);
    await store.set('messages', store.newId(), {
      'roomId': room.id, 'senderId': me.id, 'text': t, 'imageUrl': url,
      'createdAt': _now, 'flagged': looksOffApp(t),
    });
    final other = room.otherId(me.id);
    final fresh = await store.getDoc('rooms', room.id);
    final prev = fresh == null ? 0 : ChatRoom.fromMap(fresh).unreadFor(other);
    await store.set('rooms', room.id, {
      'lastText': t.isEmpty ? 'Foto' : t,
      'lastAt': _now,
      'unread': {other: prev + 1, me.id: 0},
      'readAt': {me.id: _now},
    });
    await _notify(other, 'chat', me.name, t.isEmpty ? 'Mengirim foto' : t, room.id);
  }

  Future<void> markRoomRead(String roomId, String uid) =>
      store.set('rooms', roomId, {'unread': {uid: 0}, 'readAt': {uid: _now}});

  // ------------------------------------------------------------ Notifikasi
  Future<void> _notify(String uid, String type, String title, String body, String refId) {
    if (uid.isEmpty) return Future.value();
    return store.set('notifications', store.newId(), {
      'userId': uid, 'type': type, 'title': title, 'body': body, 'refId': refId,
      'isRead': false, 'createdAt': _now,
    });
  }

  Future<void> markNotificationRead(String id) =>
      store.set('notifications', id, {'isRead': true});

  Future<void> markAllRead(List<NotificationItem> items) async {
    for (final n in items.where((n) => !n.isRead)) {
      await store.set('notifications', n.id, {'isRead': true});
    }
  }

  // ------------------------------------------------------------ Saldo
  Future<void> _ledger(String uid, String type, int amount, String note, String ref) =>
      store.set('ledger', store.newId(), {
        'userId': uid, 'type': type, 'amount': amount, 'note': note, 'refId': ref,
        'createdAt': _now,
      });

  Future<void> withdraw(AppUser me, int amount) async {
    if (!me.kycOk) throw AppException('Selesaikan verifikasi identitas (KYC) terlebih dahulu.');
    if (me.bankNumber.isEmpty) throw AppException('Tambahkan rekening pencairan terlebih dahulu.');
    if (me.bankChangedAt != null &&
        DateTime.now().difference(me.bankChangedAt!) < AppConfig.bankCooldown) {
      throw AppException('Rekening baru diubah. Tunggu masa verifikasi sebelum mencairkan.');
    }
    if (amount < AppConfig.minWithdraw) {
      throw AppException('Minimal pencairan ${rupiah(AppConfig.minWithdraw)}.');
    }
    if (amount + AppConfig.withdrawFee > me.availableBalance) {
      throw AppException('Saldo tersedia tidak cukup (termasuk biaya admin ${rupiah(AppConfig.withdrawFee)}).');
    }
    final id = store.newId();
    await store.set('withdrawals', id, {
      'userId': me.id, 'amount': amount, 'fee': AppConfig.withdrawFee,
      'status': 'processing', 'bank': '${me.bankName} ${me.bankNumber}', 'createdAt': _now,
    });
    await store.increment('users', me.id, 'availableBalance', -(amount + AppConfig.withdrawFee));
    await _ledger(me.id, 'withdraw', -(amount + AppConfig.withdrawFee), 'Pencairan ke ${me.bankName}', id);
    await _notify(me.id, 'wallet', 'Pencairan diproses', '${rupiah(amount)} sedang diproses ke ${me.bankName}.', id);
    // Simulasi sandbox: pencairan berhasil beberapa detik kemudian.
    Timer(const Duration(seconds: 5), () async {
      try {
        await store.set('withdrawals', id, {'status': 'success'});
        await _notify(me.id, 'wallet', 'Pencairan berhasil', '${rupiah(amount)} masuk ke rekeningmu.', id);
      } catch (_) {}
    });
  }
}
