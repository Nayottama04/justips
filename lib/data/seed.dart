import '../models/models.dart';
import 'memory_store.dart';

int _ago(Duration d) => DateTime.now().subtract(d).millisecondsSinceEpoch;

/// Data contoh untuk mode demo (nama & nominal mengikuti desain Figma).
MemoryStore buildDemoStore() {
  final s = MemoryStore();

  void user(AppUser u) => s.seedDoc('users', u.id, u.toMap());

  user(AppUser(
      id: 'u_alex', name: 'Alex Pratama', email: 'alex@demo.id', username: 'alex',
      address: 'Jl. Kemang Raya No. 12, Jakarta Selatan', phone: '081234567890',
      bio: 'Suka titip barang dari luar kota.', completedOrders: 12));
  user(AppUser(
      id: 'u_rina', name: 'Rina Kusuma', email: 'rina@demo.id', username: 'rina',
      address: 'Jl. Dago No. 88, Bandung', phone: '081298765432',
      bio: 'Penjastip Bandung - Jakarta - Singapura.',
      completedOrders: 14, kycStatus: 'approved', bankName: 'BCA',
      bankNumber: '1234567890', bankOwner: 'Rina Kusuma',
      availableBalance: 1450000, pendingBalance: 1967000));
  user(AppUser(
      id: 'u_dewi', name: 'Dewi Anggraini', email: 'dewi@demo.id', username: 'dewi',
      address: 'Jl. Pemuda No. 5, Surabaya', phone: '081311112222'));
  user(AppUser(
      id: 'u_budi', name: 'Budi Santoso', email: 'budi@demo.id', username: 'budi',
      address: 'Jl. Sudirman No. 20, Jakarta', phone: '081355556666'));

  void order(Order o) => s.seedDoc('orders', o.id, o.toMap());

  final ev = (String type, Duration ago) => {
        'type': type,
        'url': '',
        'at': _ago(ago),
      };

  order(Order(
      id: 'o1', code: '#ORD-89241', buyerId: 'u_alex', buyerName: 'Alex Pratama',
      buyerUsername: 'alex', itemName: 'Kemeja Linen Casual',
      description: 'Warna: Sage Green, Ukuran: L (1 barang)',
      locationLabel: 'Bandung', locationNote: 'Cihampelas Walk lt. 2, toko Uniqlo',
      estimatedPrice: 220000, status: OrderStatus.shipped, sellerId: 'u_rina',
      sellerName: 'Rina Kusuma', itemPrice: 220000, serviceFee: 40000, shippingFee: 25000,
      gatewayFee: 4000, createdAt: DateTime.now().subtract(const Duration(days: 3)),
      takenAt: DateTime.now().subtract(const Duration(days: 3)),
      paidAt: DateTime.now().subtract(const Duration(days: 2, hours: 20)),
      shippedAt: DateTime.now().subtract(const Duration(hours: 20)),
      trackingNo: 'JNE 0123456789', payMethod: 'QRIS',
      evidence: [ev('purchase', const Duration(days: 2)), ev('shipping', const Duration(hours: 20))],
      deliveryAddress: 'Jl. Kemang Raya No. 12, Jakarta Selatan'));

  order(Order(
      id: 'o2', code: '#ORD-90112', buyerId: 'u_alex', buyerName: 'Alex Pratama',
      buyerUsername: 'alex', itemName: 'Sneakers Retro Minimalist',
      description: 'Warna: Cream/Emerald, Ukuran: 42 (1 pasang)',
      locationLabel: 'Bandung', locationNote: 'Cihampelas, factory outlet',
      estimatedPrice: 450000, status: OrderStatus.awaitingPayment, sellerId: 'u_rina',
      sellerName: 'Rina Kusuma', itemPrice: 450000, serviceFee: 60000, shippingFee: 25000,
      gatewayFee: 5000, createdAt: DateTime.now().subtract(const Duration(days: 1)),
      takenAt: DateTime.now().subtract(const Duration(hours: 6)),
      deliveryAddress: 'Jl. Kemang Raya No. 12, Jakarta Selatan'));

  order(Order(
      id: 'o3', code: '#ORD-87140', buyerId: 'u_alex', buyerName: 'Alex Pratama',
      buyerUsername: 'alex', itemName: 'Headphone ANC Wireless',
      description: 'Warna: Space Grey (1 unit)', locationLabel: 'Jakarta',
      locationNote: 'Erafone Grand Indonesia', estimatedPrice: 1000000,
      status: OrderStatus.received, sellerId: 'u_rina', sellerName: 'Rina Kusuma',
      itemPrice: 1000000, serviceFee: 70000, shippingFee: 40000, gatewayFee: 10000,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      takenAt: DateTime.now().subtract(const Duration(days: 8)),
      paidAt: DateTime.now().subtract(const Duration(days: 7)),
      shippedAt: DateTime.now().subtract(const Duration(days: 4)),
      receivedAt: DateTime.now().subtract(const Duration(hours: 5)),
      trackingNo: 'SICEPAT 8800112233', payMethod: 'Virtual Account',
      evidence: [ev('purchase', const Duration(days: 6)), ev('shipping', const Duration(days: 4))],
      deliveryAddress: 'Jl. Kemang Raya No. 12, Jakarta Selatan'));

  order(Order(
      id: 'o4', code: '#ORD-81099', buyerId: 'u_alex', buyerName: 'Alex Pratama',
      buyerUsername: 'alex', itemName: 'Tumbler Keramik Insulated',
      description: 'Warna: Stone White 450ml (1 barang)', locationLabel: 'Bandung',
      locationNote: 'Miniso Paris Van Java', estimatedPrice: 120000,
      status: OrderStatus.done, sellerId: 'u_rina', sellerName: 'Rina Kusuma',
      itemPrice: 120000, serviceFee: 30000, shippingFee: 20000, gatewayFee: 5000,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      takenAt: DateTime.now().subtract(const Duration(days: 20)),
      paidAt: DateTime.now().subtract(const Duration(days: 19)),
      shippedAt: DateTime.now().subtract(const Duration(days: 16)),
      receivedAt: DateTime.now().subtract(const Duration(days: 14)),
      trackingNo: 'JNT 55667788', payMethod: 'GoPay',
      deliveryAddress: 'Jl. Kemang Raya No. 12, Jakarta Selatan'));

  order(Order(
      id: 'o5', code: '#ORD-90500', buyerId: 'u_dewi', buyerName: 'Dewi Anggraini',
      buyerUsername: 'dewi', itemName: 'Laneige Skincare Set',
      description: 'Water Sleeping Mask + Cream Skin, segel', locationLabel: 'Jakarta',
      locationNote: 'Sephora Plaza Indonesia', estimatedPrice: 500000,
      status: OrderStatus.held, sellerId: 'u_rina', sellerName: 'Rina Kusuma',
      itemPrice: 500000, serviceFee: 50000, shippingFee: 30000, gatewayFee: 5000,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      takenAt: DateTime.now().subtract(const Duration(days: 2)),
      paidAt: DateTime.now().subtract(const Duration(hours: 10)),
      payMethod: 'QRIS', deliveryAddress: 'Jl. Pemuda No. 5, Surabaya'));

  order(Order(
      id: 'o6', code: '#ORD-91001', buyerId: 'u_dewi', buyerName: 'Dewi Anggraini',
      buyerUsername: 'dewi', itemName: 'Matcha Premium Uji 100g',
      description: 'Merk Ippodo, 2 kaleng, kemasan segel',
      linkUrl: 'https://example.com/matcha-ippodo', locationLabel: 'Singapura',
      locationNote: 'Don Don Donki Jem lt. 1', estimatedPrice: 360000,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      deliveryAddress: 'Jl. Pemuda No. 5, Surabaya'));

  order(Order(
      id: 'o7', code: '#ORD-91002', buyerId: 'u_budi', buyerName: 'Budi Santoso',
      buyerUsername: 'budi', itemName: 'Lego Botanical Bonsai',
      description: 'Set 10281, kondisi box mulus', locationLabel: 'Jakarta',
      locationNote: 'Toys Kingdom Grand Indonesia lt. 3', estimatedPrice: 1250000,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      deliveryAddress: 'Jl. Sudirman No. 20, Jakarta'));

  order(Order(
      id: 'o8', code: '#ORD-91003', buyerId: 'u_dewi', buyerName: 'Dewi Anggraini',
      buyerUsername: 'dewi', itemName: 'Parfum Jo Malone 100ml',
      description: 'English Pear & Freesia, duty free', linkUrl: 'https://example.com/jo-malone',
      locationLabel: 'Kuala Lumpur', locationNote: 'KLIA Duty Free', estimatedPrice: 2400000,
      createdAt: DateTime.now().subtract(const Duration(hours: 9)),
      deliveryAddress: 'Jl. Pemuda No. 5, Surabaya'));

  order(Order(
      id: 'o9', code: '#ORD-91004', buyerId: 'u_budi', buyerName: 'Budi Santoso',
      buyerUsername: 'budi', itemName: 'Kopi Arabika Gayo 1kg',
      description: 'Roasted bean, medium roast', locationLabel: 'Surabaya',
      locationNote: 'Pasar Atom lt. 1', estimatedPrice: 280000,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      deliveryAddress: 'Jl. Sudirman No. 20, Jakarta'));

  // Ruang chat
  s.seedDoc('rooms', 'o1_u_rina', {
    'orderId': 'o1', 'itemName': 'Kemeja Linen Casual', 'buyerId': 'u_alex',
    'buyerName': 'Alex Pratama', 'sellerId': 'u_rina', 'sellerName': 'Rina Kusuma',
    'members': ['u_alex', 'u_rina'], 'lastText': 'Sudah dikirim ya, resi sudah aku upload.',
    'lastAt': _ago(const Duration(hours: 20)),
    'unread': {'u_alex': 1, 'u_rina': 0}, 'readAt': {'u_rina': _ago(const Duration(hours: 19))},
  });
  s.seedDoc('rooms', 'o2_u_rina', {
    'orderId': 'o2', 'itemName': 'Sneakers Retro Minimalist', 'buyerId': 'u_alex',
    'buyerName': 'Alex Pratama', 'sellerId': 'u_rina', 'sellerName': 'Rina Kusuma',
    'members': ['u_alex', 'u_rina'], 'lastText': 'Rincian biaya sudah aku kirim, cek dulu ya.',
    'lastAt': _ago(const Duration(hours: 2)),
    'unread': {'u_alex': 2, 'u_rina': 0}, 'readAt': {},
  });

  void msg(String room, String sender, String text, Duration ago) =>
      s.seedDoc('messages', 'm_${room}_${ago.inMinutes}', {
        'roomId': room, 'senderId': sender, 'text': text, 'createdAt': _ago(ago),
      });
  msg('o1_u_rina', 'u_alex', 'Kak, ukuran L masih ada?', const Duration(days: 3));
  msg('o1_u_rina', 'u_rina', 'Ada kak, warna Sage Green juga ready.', const Duration(days: 3, minutes: -5));
  msg('o1_u_rina', 'u_rina', 'Sudah dikirim ya, resi sudah aku upload.', const Duration(hours: 20));
  msg('o2_u_rina', 'u_alex', 'Halo kak, mau titip sneakers ukuran 42.', const Duration(hours: 7));
  msg('o2_u_rina', 'u_rina', 'Siap kak, aku ambil ya.', const Duration(hours: 6));
  msg('o2_u_rina', 'u_rina', 'Rincian biaya sudah aku kirim, cek dulu ya.', const Duration(hours: 2));

  // Notifikasi Alex (5 belum dibaca)
  void notif(String type, String title, String body, String ref, Duration ago, bool read) =>
      s.seedDoc('notifications', 'n_${title.hashCode}_${ago.inMinutes}', {
        'userId': 'u_alex', 'type': type, 'title': title, 'body': body, 'refId': ref,
        'isRead': read, 'createdAt': _ago(ago),
      });
  notif('fees', 'Rincian biaya dikirim', 'Rina mengirim rincian biaya untuk Sneakers Retro Minimalist.', 'o2', const Duration(hours: 2), false);
  notif('status', 'Pesanan dikirim', 'Kemeja Linen Casual sudah dikirim. Resi JNE 0123456789.', 'o1', const Duration(hours: 20), false);
  notif('status', 'Barang tiba', 'Headphone ANC Wireless tercatat diterima.', 'o3', const Duration(hours: 5), false);
  notif('take', 'Order diambil penjastip', 'Rina mengambil order Sneakers Retro Minimalist.', 'o2', const Duration(hours: 6), false);
  notif('chat', 'Rina Kusuma', 'Rincian biaya sudah aku kirim, cek dulu ya.', 'o2_u_rina', const Duration(hours: 2), false);
  notif('wallet', 'Order selesai', 'Tumbler Keramik Insulated selesai. Terima kasih!', 'o4', const Duration(days: 14), true);

  // Mutasi saldo Rina
  void led(String type, int amount, String note, String ref, Duration ago) =>
      s.seedDoc('ledger', 'l_${note.hashCode}_${ago.inMinutes}', {
        'userId': 'u_rina', 'type': type, 'amount': amount, 'note': note, 'refId': ref,
        'createdAt': _ago(ago),
      });
  led('escrow_in', 283000, 'Dana tertahan - Kemeja Linen Casual', 'o1', const Duration(days: 2));
  led('escrow_in', 1106500, 'Dana tertahan - Headphone ANC Wireless', 'o3', const Duration(days: 7));
  led('escrow_in', 577500, 'Dana tertahan - Laneige Skincare Set', 'o5', const Duration(hours: 10));
  led('release', 143000, 'Dana dilepas - Tumbler Keramik Insulated', 'o4', const Duration(days: 14));
  led('withdraw', -502500, 'Pencairan ke BCA', 'w0', const Duration(days: 10));

  s.seedDoc('withdrawals', 'w0', {
    'userId': 'u_rina', 'amount': 500000, 'fee': 2500, 'status': 'success',
    'bank': 'BCA 1234567890', 'createdAt': _ago(const Duration(days: 10)),
  });

  return s;
}
