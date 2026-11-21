import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String rupiah(num v) {
  final n = v.round();
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}Rp ${b.toString()}';
}

int parseRupiah(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

String dateShort(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
String dateTimeFull(DateTime d) => DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d);
String hm(DateTime d) => DateFormat('HH:mm').format(d);

String relTime(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt';
  if (diff.inHours < 24) return hm(d);
  if (diff.inDays < 2) return 'Kemarin';
  return DateFormat('d MMM', 'id_ID').format(d);
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final f = rupiah(int.parse(digits)).substring(3);
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

/// Deteksi pola ajakan transaksi di luar aplikasi (FR-94).
bool looksOffApp(String t) {
  final s = t.toLowerCase();
  if (RegExp(r'\d{9,}').hasMatch(s.replaceAll(RegExp(r'[\s\-.]'), ''))) return true;
  const words = ['rekening', 'no rek', 'norek', 'transfer langsung', 'whatsapp', ' wa ', 'wa:', 'telegram'];
  return words.any(s.contains);
}
