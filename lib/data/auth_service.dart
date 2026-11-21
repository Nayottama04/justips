import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../models/models.dart';

abstract class AuthService {
  Stream<String?> get uidStream;
  Future<String> signIn(String email, String password);
  Future<String> register(String email, String password);
  Future<void> signOut();
  Future<void> deleteCurrent();
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _a = FirebaseAuth.instance;

  @override
  Stream<String?> get uidStream => _a.authStateChanges().map((u) => u?.uid);

  String _msg(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Kata sandi minimal 6 karakter.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan ($code).';
    }
  }

  @override
  Future<String> signIn(String email, String password) async {
    try {
      final c = await _a.signInWithEmailAndPassword(email: email, password: password);
      return c.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AppException(_msg(e.code));
    }
  }

  @override
  Future<String> register(String email, String password) async {
    try {
      final c = await _a.createUserWithEmailAndPassword(email: email, password: password);
      return c.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AppException(_msg(e.code));
    }
  }

  @override
  Future<void> signOut() => _a.signOut();

  @override
  Future<void> deleteCurrent() async {
    try {
      await _a.currentUser?.delete();
    } catch (_) {
      await _a.signOut();
    }
  }
}

/// Autentikasi lokal untuk mode demo (tanpa Firebase).
class DemoAuthService implements AuthService {
  final BehaviorSubject<String?> _uid = BehaviorSubject<String?>.seeded(null);
  // email -> [password, uid]
  final Map<String, List<String>> _accounts = {
    'alex@demo.id': ['123456', 'u_alex'],
    'rina@demo.id': ['123456', 'u_rina'],
  };
  int _n = 0;

  @override
  Stream<String?> get uidStream => _uid.stream;

  @override
  Future<String> signIn(String email, String password) async {
    final a = _accounts[email.trim().toLowerCase()];
    if (a == null || a[0] != password) {
      throw AppException('Email atau kata sandi salah.');
    }
    _uid.add(a[1]);
    return a[1];
  }

  @override
  Future<String> register(String email, String password) async {
    final e = email.trim().toLowerCase();
    if (_accounts.containsKey(e)) throw AppException('Email sudah terdaftar.');
    if (password.length < 6) throw AppException('Kata sandi minimal 6 karakter.');
    final uid = 'u_new${_n++}';
    _accounts[e] = [password, uid];
    _uid.add(uid);
    return uid;
  }

  @override
  Future<void> signOut() async => _uid.add(null);

  @override
  Future<void> deleteCurrent() async {
    final cur = _uid.valueOrNull;
    _accounts.removeWhere((k, v) => v[1] == cur);
    _uid.add(null);
  }
}
