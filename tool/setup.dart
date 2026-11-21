// Setup sekali jalan: membuat folder android/ (via `flutter create`), menyesuaikan
// minSdk untuk Firebase, menambahkan izin INTERNET, lalu `flutter pub get`.
//
// Jalankan dari root proyek:   dart run tool/setup.dart
import 'dart:io';

Future<int> run(String cmd, List<String> args) async {
  final p = await Process.start(cmd, args, runInShell: true, mode: ProcessStartMode.inheritStdio);
  return p.exitCode;
}

Future<void> main() async {
  final lib = File('lib/main.dart').readAsStringSync();
  final pub = File('pubspec.yaml').readAsStringSync();

  if (!Directory('android').existsSync()) {
    stdout.writeln('> flutter create (membuat folder android)...');
    final code = await run('flutter', [
      'create', '--platforms=android', '--project-name', 'justips', '--org', 'com.justips', '.'
    ]);
    if (code != 0) {
      stderr.writeln('flutter create gagal. Pastikan Flutter SDK ada di PATH.');
      exit(code);
    }
  }

  // Pulihkan file proyek bila ter-overwrite oleh template.
  File('lib/main.dart').writeAsStringSync(lib);
  File('pubspec.yaml').writeAsStringSync(pub);
  final t = File('test/widget_test.dart');
  if (t.existsSync() && t.readAsStringSync().contains('MyApp')) t.deleteSync();

  // Firebase membutuhkan minSdk 23.
  for (final name in ['android/app/build.gradle', 'android/app/build.gradle.kts']) {
    final f = File(name);
    if (!f.existsSync()) continue;
    final text = f.readAsStringSync().replaceAllMapped(
        RegExp(r'minSdk(Version)?(\s*=\s*|\s+)flutter\.minSdkVersion'),
        (m) => 'minSdk${m[1] ?? ''}${m[2]}23');
    f.writeAsStringSync(text);
    stdout.writeln('> minSdk diatur ke 23 di $name');
  }

  // Izin INTERNET untuk build release.
  final mf = File('android/app/src/main/AndroidManifest.xml');
  if (mf.existsSync()) {
    var m = mf.readAsStringSync();
    if (!m.contains('android.permission.INTERNET')) {
      m = m.replaceFirst('<application',
          '<uses-permission android:name="android.permission.INTERNET"/>\n    <application');
      mf.writeAsStringSync(m);
      stdout.writeln('> izin INTERNET ditambahkan');
    }
  }

  stdout.writeln('> flutter pub get');
  exit(await run('flutter', ['pub', 'get']));
}
