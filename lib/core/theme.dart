import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Palet warna Justips (diambil dari desain Figma: emerald + slate, font Inter).
class P {
  const P(this.dark);
  final bool dark;
  static P of(BuildContext c) => P(Theme.of(c).brightness == Brightness.dark);

  static const emerald = Color(0xFF10B981);
  static const emeraldDeep = Color(0xFF059669);
  static const amber = Color(0xFFD97706);
  static const amberInk = Color(0xFFB45309);
  static const indigo = Color(0xFF4338CA);
  static const danger = Color(0xFFBA1A1A);
  static const gold = Color(0xFFE29100);

  Color get bg => dark ? const Color(0xFF080D14) : const Color(0xFFF4F7FA);
  Color get ink => dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get muted => dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get line => dark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0);
  Color get accent => dark ? emerald : emeraldDeep;
  Color get glassFill => dark ? const Color(0x14FFFFFF) : const Color(0xA6FFFFFF);
  Color get glassHi => dark ? const Color(0x26FFFFFF) : const Color(0xD9FFFFFF);
  Color get glassEdge => dark ? const Color(0x33FFFFFF) : const Color(0xB3FFFFFF);
  Color get field => dark ? const Color(0x14FFFFFF) : const Color(0xB3FFFFFF);
  Color get dangerInk => dark ? const Color(0xFFFF8A80) : danger;
  Color get amberText => dark ? const Color(0xFFFBBF24) : amberInk;
  Color get indigoText => dark ? const Color(0xFFA5B4FC) : indigo;
}

TextStyle tx(double size,
        {FontWeight w = FontWeight.w400, Color? color, double? ls, double? h}) =>
    TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: w,
        color: color,
        letterSpacing: ls,
        height: h);

ThemeData buildTheme(Brightness b) {
  final p = P(b == Brightness.dark);
  final scheme = ColorScheme.fromSeed(seedColor: P.emerald, brightness: b)
      .copyWith(primary: p.accent, surface: p.bg);
  final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      fontFamily: 'Inter');
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.dark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
      contentTextStyle: tx(13, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    final v = _prefs.getString('theme_mode');
    _mode = v == 'dark'
        ? ThemeMode.dark
        : v == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
  }
  final SharedPreferences _prefs;
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  void setMode(ThemeMode m) {
    _mode = m;
    _prefs.setString('theme_mode', m.name);
    notifyListeners();
  }

  void toggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
