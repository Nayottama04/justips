import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  AppState(this.repo) {
    _sub = repo.auth.uidStream.listen(_onUid);
  }

  final Repository repo;
  StreamSubscription<String?>? _sub;
  StreamSubscription<AppUser?>? _userSub;

  String? uid;
  AppUser? user;
  bool seller = false;
  int tab = 0;

  bool get loggedIn => uid != null;

  void _onUid(String? id) {
    uid = id;
    _userSub?.cancel();
    user = null;
    if (id == null) {
      seller = false;
      tab = 0;
      notifyListeners();
      return;
    }
    _userSub = repo.watchUser(id).listen((u) {
      user = u;
      notifyListeners();
    });
    repo.sweep(id);
    notifyListeners();
  }

  void setTab(int i) {
    if (tab == i) return;
    tab = i;
    notifyListeners();
  }

  void setSeller(bool v) {
    seller = v;
    tab = 0;
    notifyListeners();
  }

  Future<void> signOut() => repo.auth.signOut();

  @override
  void dispose() {
    _sub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
