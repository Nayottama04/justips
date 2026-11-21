import 'package:flutter/material.dart';

class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Konfigurasi bisnis (nilai awal dari PRD, dapat diubah admin pada versi produksi).
class AppConfig {
  static const commissionRate = 0.05;
  static const minWithdraw = 50000;
  static const withdrawFee = 2500;
  static const autoConfirm = Duration(hours: 72);
  static const complaintWindow = Duration(hours: 48);
  // Produksi: 24 jam. Untuk demo tugas kuliah dibuat singkat.
  static const bankCooldown = Duration(seconds: 30);
  // Mock tugas kuliah: KYC otomatis disetujui (produksi: ditinjau admin).
  static const autoApproveKyc = true;
  static const demoOtp = '123456';
}

int _i(dynamic v) => v is num ? v.toInt() : 0;
String _s(dynamic v) => v is String ? v : '';
DateTime _d(dynamic v) => DateTime.fromMillisecondsSinceEpoch(v is num ? v.toInt() : 0);
DateTime? _dn(dynamic v) => v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;

enum OrderStatus {
  waiting,
  taken,
  awaitingPayment,
  held,
  purchased,
  shipped,
  received,
  done,
  cancelled,
  complaint
}

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.waiting => 'Menunggu',
        OrderStatus.taken => 'Diambil',
        OrderStatus.awaitingPayment => 'Menunggu Bayar',
        OrderStatus.held => 'Dana Ditahan',
        OrderStatus.purchased => 'Dibeli',
        OrderStatus.shipped => 'Dikirim',
        OrderStatus.received => 'Diterima',
        OrderStatus.done => 'Selesai',
        OrderStatus.cancelled => 'Dibatalkan',
        OrderStatus.complaint => 'Komplain',
      };

  Color get color => switch (this) {
        OrderStatus.waiting => const Color(0xFF64748B),
        OrderStatus.taken => const Color(0xFF0284C7),
        OrderStatus.awaitingPayment => const Color(0xFFD97706),
        OrderStatus.held => const Color(0xFF0D9488),
        OrderStatus.purchased => const Color(0xFF7C3AED),
        OrderStatus.shipped => const Color(0xFF059669),
        OrderStatus.received => const Color(0xFF4338CA),
        OrderStatus.done => const Color(0xFF565E74),
        OrderStatus.cancelled => const Color(0xFFBA1A1A),
        OrderStatus.complaint => const Color(0xFFE11D48),
      };

  IconData get icon => switch (this) {
        OrderStatus.waiting => Icons.hourglass_empty_rounded,
        OrderStatus.taken => Icons.how_to_reg_outlined,
        OrderStatus.awaitingPayment => Icons.schedule_rounded,
        OrderStatus.held => Icons.lock_outline_rounded,
        OrderStatus.purchased => Icons.shopping_bag_outlined,
        OrderStatus.shipped => Icons.local_shipping_outlined,
        OrderStatus.received => Icons.inventory_2_outlined,
        OrderStatus.done => Icons.verified_outlined,
        OrderStatus.cancelled => Icons.cancel_outlined,
        OrderStatus.complaint => Icons.flag_outlined,
      };

  /// Langkah pada stepper (0..5).
  int get step => switch (this) {
        OrderStatus.waiting => 0,
        OrderStatus.taken => 1,
        OrderStatus.awaitingPayment => 2,
        OrderStatus.held => 3,
        OrderStatus.purchased => 3,
        OrderStatus.shipped => 4,
        OrderStatus.received => 5,
        OrderStatus.done => 5,
        OrderStatus.cancelled => 0,
        OrderStatus.complaint => 4,
      };
}

OrderStatus parseStatus(String s) =>
    OrderStatus.values.firstWhere((e) => e.name == s, orElse: () => OrderStatus.waiting);

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.address = '',
    this.phone = '',
    this.bio = '',
    this.photoUrl = '',
    this.pendingBalance = 0,
    this.availableBalance = 0,
    this.completedOrders = 0,
    this.complaints = 0,
    this.kycStatus = 'none',
    this.bankName = '',
    this.bankNumber = '',
    this.bankOwner = '',
    this.bankChangedAt,
    this.pushEnabled = true,
  });

  final String id, name, email, username, address, phone, bio, photoUrl;
  final int pendingBalance, availableBalance, completedOrders, complaints;
  final String kycStatus; // none | pending | approved | rejected
  final String bankName, bankNumber, bankOwner;
  final DateTime? bankChangedAt;
  final bool pushEnabled;

  static const levelNames = ['Baru', 'Berkembang', 'Terpercaya', 'Senior'];
  static const levelMax = [500000, 1500000, 5000000, 10000000];
  static const levelActive = [2, 4, 8, 15];

  int get level {
    final c = completedOrders;
    final rate = c == 0 ? 0.0 : complaints / c;
    if (c >= 25 && rate < 0.05) return 4;
    if (c >= 10 && rate < 0.05) return 3;
    if (c >= 3 && complaints == 0) return 2;
    return 1;
  }

  String get levelName => levelNames[level - 1];
  int get maxOrderValue => levelMax[level - 1];
  int get maxActive => levelActive[level - 1];
  bool get kycOk => kycStatus == 'approved';
  String get firstName => name.trim().split(' ').first;

  String get nextLevelHint {
    switch (level) {
      case 1:
        return '3 order selesai tanpa komplain untuk naik ke Level 2';
      case 2:
        return '10 order selesai (komplain < 5%) untuk naik ke Level 3';
      case 3:
        return '25 order selesai (komplain < 5%) untuk naik ke Level 4';
      default:
        return 'Level tertinggi tercapai';
    }
  }

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: _s(m['id']),
        name: _s(m['name']),
        email: _s(m['email']),
        username: _s(m['username']),
        address: _s(m['address']),
        phone: _s(m['phone']),
        bio: _s(m['bio']),
        photoUrl: _s(m['photoUrl']),
        pendingBalance: _i(m['pendingBalance']),
        availableBalance: _i(m['availableBalance']),
        completedOrders: _i(m['completedOrders']),
        complaints: _i(m['complaints']),
        kycStatus: m['kycStatus'] is String ? m['kycStatus'] as String : 'none',
        bankName: _s(m['bankName']),
        bankNumber: _s(m['bankNumber']),
        bankOwner: _s(m['bankOwner']),
        bankChangedAt: _dn(m['bankChangedAt']),
        pushEnabled: m['pushEnabled'] is bool ? m['pushEnabled'] as bool : true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'username': username,
        'address': address,
        'phone': phone,
        'bio': bio,
        'photoUrl': photoUrl,
        'pendingBalance': pendingBalance,
        'availableBalance': availableBalance,
        'completedOrders': completedOrders,
        'complaints': complaints,
        'kycStatus': kycStatus,
        'bankName': bankName,
        'bankNumber': bankNumber,
        'bankOwner': bankOwner,
        'bankChangedAt': bankChangedAt?.millisecondsSinceEpoch,
        'pushEnabled': pushEnabled,
      };
}

class Order {
  Order({
    required this.id,
    required this.code,
    required this.buyerId,
    required this.buyerName,
    this.buyerUsername = '',
    required this.itemName,
    this.description = '',
    this.linkUrl = '',
    this.imageUrl = '',
    this.locationLabel = '',
    this.locationNote = '',
    this.estimatedPrice = 0,
    this.status = OrderStatus.waiting,
    this.sellerId = '',
    this.sellerName = '',
    this.itemPrice = 0,
    this.serviceFee = 0,
    this.shippingFee = 0,
    this.gatewayFee = 0,
    required this.createdAt,
    this.takenAt,
    this.paidAt,
    this.shippedAt,
    this.receivedAt,
    this.trackingNo = '',
    this.payMethod = '',
    this.evidence = const [],
    this.complaintReason = '',
    this.complaintDesc = '',
    this.deliveryAddress = '',
  });

  final String id, code, buyerId, buyerName, buyerUsername, itemName, description;
  final String linkUrl, imageUrl, locationLabel, locationNote;
  final int estimatedPrice;
  final OrderStatus status;
  final String sellerId, sellerName;
  final int itemPrice, serviceFee, shippingFee, gatewayFee;
  final DateTime createdAt;
  final DateTime? takenAt, paidAt, shippedAt, receivedAt;
  final String trackingNo, payMethod;
  final List<Map<String, dynamic>> evidence;
  final String complaintReason, complaintDesc, deliveryAddress;

  bool get hasFees => itemPrice > 0 || serviceFee > 0 || shippingFee > 0;
  int get subtotal => itemPrice + serviceFee + shippingFee;
  int get total => subtotal + gatewayFee;
  int get commission => (serviceFee * AppConfig.commissionRate).round();
  int get sellerNet => subtotal - commission;
  bool get fundsHeld => const [
        OrderStatus.held,
        OrderStatus.purchased,
        OrderStatus.shipped,
        OrderStatus.received,
        OrderStatus.complaint
      ].contains(status);
  bool get isActiveForSeller => const [
        OrderStatus.taken,
        OrderStatus.awaitingPayment,
        OrderStatus.held,
        OrderStatus.purchased,
        OrderStatus.shipped,
        OrderStatus.received,
        OrderStatus.complaint
      ].contains(status);
  bool get isActiveForBuyer =>
      status != OrderStatus.done && status != OrderStatus.cancelled;
  String get locationFull =>
      locationNote.isEmpty ? locationLabel : '$locationLabel - $locationNote';

  factory Order.fromMap(Map<String, dynamic> m) => Order(
        id: _s(m['id']),
        code: _s(m['code']),
        buyerId: _s(m['buyerId']),
        buyerName: _s(m['buyerName']),
        buyerUsername: _s(m['buyerUsername']),
        itemName: _s(m['itemName']),
        description: _s(m['description']),
        linkUrl: _s(m['linkUrl']),
        imageUrl: _s(m['imageUrl']),
        locationLabel: _s(m['locationLabel']),
        locationNote: _s(m['locationNote']),
        estimatedPrice: _i(m['estimatedPrice']),
        status: parseStatus(_s(m['status'])),
        sellerId: _s(m['sellerId']),
        sellerName: _s(m['sellerName']),
        itemPrice: _i(m['itemPrice']),
        serviceFee: _i(m['serviceFee']),
        shippingFee: _i(m['shippingFee']),
        gatewayFee: _i(m['gatewayFee']),
        createdAt: _d(m['createdAt']),
        takenAt: _dn(m['takenAt']),
        paidAt: _dn(m['paidAt']),
        shippedAt: _dn(m['shippedAt']),
        receivedAt: _dn(m['receivedAt']),
        trackingNo: _s(m['trackingNo']),
        payMethod: _s(m['payMethod']),
        evidence: m['evidence'] is List
            ? (m['evidence'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : <Map<String, dynamic>>[],
        complaintReason: _s(m['complaintReason']),
        complaintDesc: _s(m['complaintDesc']),
        deliveryAddress: _s(m['deliveryAddress']),
      );

  Map<String, dynamic> toMap() => {
        'code': code,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'buyerUsername': buyerUsername,
        'itemName': itemName,
        'description': description,
        'linkUrl': linkUrl,
        'imageUrl': imageUrl,
        'locationLabel': locationLabel,
        'locationNote': locationNote,
        'estimatedPrice': estimatedPrice,
        'status': status.name,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'itemPrice': itemPrice,
        'serviceFee': serviceFee,
        'shippingFee': shippingFee,
        'gatewayFee': gatewayFee,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'takenAt': takenAt?.millisecondsSinceEpoch,
        'paidAt': paidAt?.millisecondsSinceEpoch,
        'shippedAt': shippedAt?.millisecondsSinceEpoch,
        'receivedAt': receivedAt?.millisecondsSinceEpoch,
        'trackingNo': trackingNo,
        'payMethod': payMethod,
        'evidence': evidence,
        'complaintReason': complaintReason,
        'complaintDesc': complaintDesc,
        'deliveryAddress': deliveryAddress,
      };
}

class ChatRoom {
  ChatRoom({
    required this.id,
    required this.orderId,
    required this.itemName,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.members,
    this.lastText = '',
    this.lastAt,
    this.unread = const {},
    this.readAt = const {},
  });

  final String id, orderId, itemName, buyerId, buyerName, sellerId, sellerName;
  final List<String> members;
  final String lastText;
  final DateTime? lastAt;
  final Map<String, int> unread;
  final Map<String, int> readAt;

  String otherId(String me) => me == buyerId ? sellerId : buyerId;
  String otherName(String me) => me == buyerId ? sellerName : buyerName;
  int unreadFor(String me) => unread[me] ?? 0;

  static Map<String, int> _intMap(dynamic v) {
    if (v is! Map) return {};
    return v.map((k, val) => MapEntry(k.toString(), _i(val)));
  }

  factory ChatRoom.fromMap(Map<String, dynamic> m) => ChatRoom(
        id: _s(m['id']),
        orderId: _s(m['orderId']),
        itemName: _s(m['itemName']),
        buyerId: _s(m['buyerId']),
        buyerName: _s(m['buyerName']),
        sellerId: _s(m['sellerId']),
        sellerName: _s(m['sellerName']),
        members: m['members'] is List
            ? (m['members'] as List).map((e) => e.toString()).toList()
            : <String>[],
        lastText: _s(m['lastText']),
        lastAt: _dn(m['lastAt']),
        unread: _intMap(m['unread']),
        readAt: _intMap(m['readAt']),
      );
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.text = '',
    this.imageUrl = '',
    required this.createdAt,
    this.flagged = false,
    this.system = false,
  });
  final String id, roomId, senderId, text, imageUrl;
  final DateTime createdAt;
  final bool flagged, system;

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: _s(m['id']),
        roomId: _s(m['roomId']),
        senderId: _s(m['senderId']),
        text: _s(m['text']),
        imageUrl: _s(m['imageUrl']),
        createdAt: _d(m['createdAt']),
        flagged: m['flagged'] == true,
        system: m['system'] == true,
      );
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.refId,
    required this.isRead,
    required this.createdAt,
  });
  final String id, type, title, body, refId;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationItem.fromMap(Map<String, dynamic> m) => NotificationItem(
        id: _s(m['id']),
        type: _s(m['type']),
        title: _s(m['title']),
        body: _s(m['body']),
        refId: _s(m['refId']),
        isRead: m['isRead'] == true,
        createdAt: _d(m['createdAt']),
      );
}

class LedgerEntry {
  LedgerEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.note,
    required this.refId,
    required this.createdAt,
  });
  final String id, userId, type, note, refId;
  final int amount;
  final DateTime createdAt;

  factory LedgerEntry.fromMap(Map<String, dynamic> m) => LedgerEntry(
        id: _s(m['id']),
        userId: _s(m['userId']),
        type: _s(m['type']),
        amount: _i(m['amount']),
        note: _s(m['note']),
        refId: _s(m['refId']),
        createdAt: _d(m['createdAt']),
      );
}

class Withdrawal {
  Withdrawal({
    required this.id,
    required this.amount,
    required this.fee,
    required this.status,
    required this.bank,
    required this.createdAt,
  });
  final String id, status, bank;
  final int amount, fee;
  final DateTime createdAt;

  factory Withdrawal.fromMap(Map<String, dynamic> m) => Withdrawal(
        id: _s(m['id']),
        amount: _i(m['amount']),
        fee: _i(m['fee']),
        status: _s(m['status']),
        bank: _s(m['bank']),
        createdAt: _d(m['createdAt']),
      );
}
