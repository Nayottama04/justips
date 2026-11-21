import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/picker.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

/// Verifikasi identitas penjastip: OTP, foto KTP, swafoto (FR-90).
class KycScreen extends StatefulWidget {
  const KycScreen({super.key});
  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _otp = TextEditingController();
  bool _otpOk = false;
  String _ktp = '';
  String _selfie = '';
  bool _busy = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _pick(bool ktp) async {
    try {
      final path = await pickPhoto(camera: !ktp);
      if (path != null) setState(() => ktp ? _ktp = path : _selfie = path);
    } catch (_) {
      if (mounted) toast(context, 'Tidak dapat membuka kamera/galeri.');
    }
  }

  Future<void> _submit() async {
    final s = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await s.repo.submitKyc(s.uid!, _ktp, _selfie);
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, AppConfig.autoApproveKyc ? 'KYC disetujui.' : 'KYC dikirim untuk ditinjau.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final u = context.watch<AppState>().user!;

    Widget stepHead(int n, String t, bool done) => Row(children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: done ? P.emerald : p.field,
                border: Border.all(color: done ? P.emerald : p.line)),
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text('$n', style: tx(12, w: FontWeight.w700, color: p.muted)),
          ),
          const SizedBox(width: 10),
          Text(t, style: tx(15, w: FontWeight.w700, color: p.ink)),
        ]);

    Widget photoBox(String path, String hint, IconData icon, VoidCallback onTap) => PressScale(
          onTap: onTap,
          child: path.isEmpty
              ? Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: p.field,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: P.emerald.withOpacity(0.5), width: 1.4),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, color: p.accent, size: 28),
                    const SizedBox(height: 6),
                    Text(hint, style: tx(12, color: p.muted)),
                  ]),
                )
              : SmartImage(path, size: 150, radius: 18, fill: true),
        );

    if (u.kycStatus == 'approved' || u.kycStatus == 'pending') {
      final ok = u.kycStatus == 'approved';
      return PageShell(
        title: 'Verifikasi Identitas',
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 40), children: [
          EmptyState(
            icon: ok ? Icons.verified_user_rounded : Icons.hourglass_top_rounded,
            title: ok ? 'Identitas terverifikasi' : 'Sedang ditinjau admin',
            message: ok
                ? 'Kamu dapat mengambil order dan mencairkan saldo.'
                : 'Kami akan memberi tahu kamu setelah data KYC ditinjau.',
          ),
        ]),
      );
    }

    return PageShell(
      title: 'Verifikasi Identitas',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          GlassCard(
            tint: P.amber.withOpacity(0.10),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: p.amberText),
              const SizedBox(width: 12),
              Expanded(
                child: Text('KYC wajib sebelum mengambil order atau mencairkan dana. Data KTP dienkripsi dan aksesnya dibatasi.',
                    style: tx(12, color: p.muted, h: 1.4)),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              stepHead(1, 'Verifikasi nomor HP (OTP)', _otpOk),
              const SizedBox(height: 12),
              if (!_otpOk) ...[
                Text('Kode OTP dikirim ke ${u.phone.isEmpty ? 'nomor HP-mu' : u.phone}. '
                    'Untuk simulasi tugas kuliah, gunakan kode ${AppConfig.demoOtp}.',
                    style: tx(12, color: p.muted, h: 1.4)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: GlassField(controller: _otp, hint: '6 digit kode', keyboard: TextInputType.number,
                        icon: Icons.sms_outlined),
                  ),
                  const SizedBox(width: 10),
                  Btn('Verifikasi', onTap: () {
                    if (_otp.text.trim() == AppConfig.demoOtp) {
                      setState(() => _otpOk = true);
                    } else {
                      toast(context, 'Kode OTP salah.');
                    }
                  }),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              stepHead(2, 'Foto KTP', _ktp.isNotEmpty),
              const SizedBox(height: 12),
              photoBox(_ktp, 'Ketuk untuk unggah foto KTP', Icons.badge_outlined, () => _pick(true)),
            ]),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              stepHead(3, 'Swafoto', _selfie.isNotEmpty),
              const SizedBox(height: 12),
              photoBox(_selfie, 'Ketuk untuk ambil swafoto', Icons.face_retouching_natural_outlined, () => _pick(false)),
            ]),
          ),
          const SizedBox(height: 20),
          Btn('Kirim Verifikasi', expand: true, large: true, busy: _busy,
              onTap: _otpOk && _ktp.isNotEmpty && _selfie.isNotEmpty ? _submit : null),
        ],
      ),
    );
  }
}
