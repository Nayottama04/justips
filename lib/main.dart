import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/theme.dart';
import 'data/auth_service.dart';
import 'data/doc_store.dart';
import 'data/firestore_store.dart';
import 'data/image_store.dart';
import 'data/repository.dart';
import 'data/seed.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Bila Firebase sudah dikonfigurasi (google-services.json) -> mode Firebase.
  // Bila belum -> mode DEMO (data lokal) supaya aplikasi tetap bisa dijalankan.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  final prefs = await SharedPreferences.getInstance();
  final DocStore store = firebaseReady ? FirestoreStore() : buildDemoStore();
  ImageStore.store = store;
  final AuthService auth = firebaseReady ? FirebaseAuthService() : DemoAuthService();
  final repo = Repository(store, auth, demo: !firebaseReady);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
      ChangeNotifierProvider(create: (_) => AppState(repo)),
    ],
    child: const JustipsApp(),
  ));
}
