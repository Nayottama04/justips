import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/picker.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'kyc.dart';
import 'nav.dart';
import 'wallet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tc = context.watch<ThemeController>();
    final p = P.of(context);
    final u = s.user;

    if (!s.loggedIn || u == null) {
      return SafeArea(
        bottom: false,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 140), children: [
          Text('Profil', style: tx(28, w: FontWeight.w800, color: p.ink, ls: -0.9)),
          const SizedBox(height: 16),
          s.loggedIn
              ? const Loading()
              : EmptyState(
                  icon: Icons.person_outline_rounded,
                  title: 'Masuk ke akunmu',
                  message: 'Login untuk melihat profil, saldo, dan pengaturan.',
                  action: Btn('Masuk', onTap: () => requireLogin(context)),
                ),
        ]),
      );
    }

    final nextTarget = [3, 10, 25, 25][u.level - 1];
    final progress = (u.completedOrders / nextTarget).clamp(0.0, 1.0);

    Widget tile(IconData i, String t, {String? sub, Widget? trailing, VoidCallback? onTap, Color? color}) =>
        PressScale(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: (color ?? P.emerald).withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
                child: Icon(i, size: 18, color: color ?? p.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t, style: tx(14, w: FontWeight.w600, color: p.ink)),
                  if (sub != null) Text(sub, style: tx(11, color: p.muted)),
                ]),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, color: p.muted),
            ]),
          ),
        );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
        children: [
          Text('Profil', style: tx(28, w: FontWeight.w800, color: p.ink, ls: -0.9)),
          const SizedBox(height: 16),
          Reveal(
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(children: [
                  Avatar(name: u.name, photoUrl: u.photoUrl, size: 64, verified: u.kycOk),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.name, style: tx(18, w: FontWeight.w700, color: p.ink, ls: -0.3)),
                      Text('@${u.username}', style: tx(13, color: p.muted)),
                      const SizedBox(height: 6),
                      Pill('Level ${u.level} - ${u.levelName}', icon: Icons.workspace_premium_outlined),
                    ]),
                  ),
                  GlassIconButton(Icons.edit_outlined, onTap: () => pushPage(context, const EditProfileScreen())),
                ]),
                if (u.bio.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerLeft, child: Text(u.bio, style: tx(13, color: p.muted, h: 1.4))),
                ],
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: p.line,
                    valueColor: const AlwaysStoppedAnimation(P.emerald),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${u.completedOrders} order selesai • ${u.nextLevelHint}',
                      style: tx(11, color: p.muted, h: 1.35)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            index: 1,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(children: [
                _info(p, Icons.mail_outline_rounded, u.email),
                _info(p, Icons.phone_outlined, u.phone.isEmpty ? '-' : u.phone),
                _info(p, Icons.home_outlined, u.address.isEmpty ? '-' : u.address),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            index: 2,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(children: [
                tile(Icons.swap_horiz_rounded, s.seller ? 'Beralih ke mode Pembeli' : 'Beralih ke mode Penjastip',
                    sub: 'Satu akun untuk dua peran', onTap: () {
                  s.setSeller(!s.seller);
                  toast(context, s.seller ? 'Mode Penjastip aktif' : 'Mode Pembeli aktif');
                }),
                Divider(height: 1, color: p.line),
                tile(Icons.badge_outlined, 'Verifikasi Identitas (KYC)',
                    sub: switch (u.kycStatus) {
                      'approved' => 'Terverifikasi',
                      'pending' => 'Sedang ditinjau',
                      'rejected' => 'Ditolak - kirim ulang',
                      _ => 'Belum diverifikasi (wajib untuk menjastip)',
                    },
                    color: u.kycOk ? P.emerald : P.amber,
                    onTap: () => pushPage(context, const KycScreen())),
                Divider(height: 1, color: p.line),
                tile(Icons.account_balance_wallet_outlined, 'Saldo & Pencairan',
                    sub: 'Tersedia ${_rp(u.availableBalance)} • Tertahan ${_rp(u.pendingBalance)}',
                    onTap: () => pushPage(context, const WalletScreen())),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            index: 3,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tampilan', style: tx(13, w: FontWeight.w700, color: p.muted, ls: 0.4)),
                const SizedBox(height: 10),
                Row(children: [
                  for (final m in [
                    [ThemeMode.system, 'Sistem', Icons.brightness_auto_rounded],
                    [ThemeMode.light, 'Terang', Icons.light_mode_outlined],
                    [ThemeMode.dark, 'Gelap', Icons.dark_mode_outlined],
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: PressScale(
                          onTap: () => tc.setMode(m[0] as ThemeMode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: tc.mode == m[0] ? P.emerald.withOpacity(0.18) : p.field,
                              border: Border.all(color: tc.mode == m[0] ? P.emerald : p.line),
                            ),
                            child: Column(children: [
                              Icon(m[2] as IconData, size: 19, color: tc.mode == m[0] ? p.accent : p.muted),
                              const SizedBox(height: 4),
                              Text(m[1] as String,
                                  style: tx(11, w: FontWeight.w600, color: tc.mode == m[0] ? p.accent : p.muted)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text('Notifikasi push', style: tx(14, w: FontWeight.w600, color: p.ink))),
                  Switch(
                    value: u.pushEnabled,
                    activeColor: P.emerald,
                    onChanged: (v) => s.repo.updateProfile(u.id, {'pushEnabled': v}),
                  ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            index: 4,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: tile(Icons.logout_rounded, 'Keluar', color: P.danger, trailing: const SizedBox.shrink(),
                  onTap: () async {
                await s.signOut();
                if (context.mounted) toast(context, 'Kamu sudah keluar.');
              }),
            ),
          ),
          if (s.repo.demo) ...[
            const SizedBox(height: 14),
            Center(child: Pill('Mode demo - data lokal', color: P.indigo, icon: Icons.science_outlined)),
          ],
        ],
      ),
    );
  }

  String _rp(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return 'Rp $b';
  }

  Widget _info(P p, IconData i, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i, size: 17, color: p.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(t, style: tx(13, color: p.ink, h: 1.35))),
        ]),
      );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _bio, _addr, _phone;
  String _photo = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user!;
    _name = TextEditingController(text: u.name);
    _bio = TextEditingController(text: u.bio);
    _addr = TextEditingController(text: u.address);
    _phone = TextEditingController(text: u.phone);
    _photo = u.photoUrl;
  }

  @override
  void dispose() {
    for (final c in [_name, _bio, _addr, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final path = await pickPhoto();
      if (path != null) setState(() => _photo = path);
    } catch (_) {
      if (mounted) toast(context, 'Tidak dapat membuka galeri.');
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final u = s.user!;
    setState(() => _busy = true);
    try {
      var photo = _photo;
      if (photo.isNotEmpty && photo != u.photoUrl && !photo.startsWith('http')) {
        photo = await s.repo.upload('avatars/${u.id}', photo);
      }
      await s.repo.updateProfile(u.id, {
        'name': _name.text.trim(),
        'bio': _bio.text.trim(),
        'address': _addr.text.trim(),
        'phone': _phone.text.trim(),
        'photoUrl': photo,
      });
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, 'Profil diperbarui.');
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;
    return PageShell(
      title: 'Edit Profil',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Center(
            child: PressScale(
              onTap: _pickPhoto,
              child: Stack(children: [
                Avatar(name: _name.text, photoUrl: _photo, size: 96),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: P.emerald,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.bg, width: 3),
                    ),
                    child: const Icon(Icons.photo_camera_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Center(child: Text('Ketuk untuk ganti foto (JPG/PNG)', style: tx(11, color: p.muted))),
          const SizedBox(height: 18),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _form,
              child: Column(children: [
                GlassField(controller: _name, label: 'Nama', hint: 'Nama lengkap', icon: Icons.person_outline_rounded, validator: req),
                const SizedBox(height: 14),
                GlassField(controller: _bio, label: 'Bio', hint: 'Ceritakan sedikit tentangmu', maxLines: 3),
                const SizedBox(height: 14),
                GlassField(controller: _addr, label: 'Alamat', hint: 'Alamat lengkap', maxLines: 2, icon: Icons.home_outlined, validator: req),
                const SizedBox(height: 14),
                GlassField(controller: _phone, label: 'No. telepon', hint: '08xxxxxxxxxx', keyboard: TextInputType.phone,
                    icon: Icons.phone_outlined, validator: req),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Btn('Simpan', expand: true, large: true, busy: _busy, onTap: _save),
        ],
      ),
    );
  }
}
