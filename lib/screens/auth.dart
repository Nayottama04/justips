import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'nav.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;
  bool _hide = true;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit([String? id, String? pw]) async {
    if (id != null) {
      _id.text = id;
      _pw.text = pw ?? '';
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AppState>().repo.signIn(_id.text, _pw.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final demo = context.read<AppState>().repo.demo;
    return PageShell(
      title: 'Masuk',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Reveal(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Selamat datang kembali', style: tx(28, w: FontWeight.w800, color: p.ink, ls: -0.9)),
              const SizedBox(height: 6),
              Text('Masuk untuk membuat order atau mulai menjastip.', style: tx(14, color: p.muted)),
            ]),
          ),
          const SizedBox(height: 24),
          Reveal(
            index: 1,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(children: [
                  GlassField(
                    controller: _id,
                    label: demo ? 'Email atau username' : 'Email',
                    hint: 'nama@email.com',
                    icon: Icons.alternate_email_rounded,
                    keyboard: TextInputType.emailAddress,
                    action: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  GlassField(
                    controller: _pw,
                    label: 'Kata sandi',
                    hint: 'Minimal 6 karakter',
                    icon: Icons.lock_outline_rounded,
                    obscure: _hide,
                    action: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 19, color: p.muted),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  Btn('Masuk', expand: true, large: true, busy: _busy, onTap: _submit),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('Belum punya akun? ', style: tx(13, color: p.muted)),
              PressScale(
                onTap: () async {
                  final ok = await pushPage<bool>(context, const RegisterScreen());
                  if (ok == true && context.mounted) Navigator.pop(context, true);
                },
                child: Text('Registrasi', style: tx(13, w: FontWeight.w700, color: p.accent)),
              ),
            ]),
          ),
          if (demo) ...[
            const SizedBox(height: 28),
            Reveal(
              index: 2,
              child: GlassCard(
                tint: P.indigo.withOpacity(0.10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.science_outlined, size: 18, color: p.indigoText),
                    const SizedBox(width: 8),
                    Text('Mode demo (tanpa Firebase)', style: tx(13, w: FontWeight.w700, color: p.ink)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Firebase belum dikonfigurasi, jadi data disimpan lokal di memori. Masuk cepat:',
                      style: tx(12, color: p.muted, h: 1.4)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: Btn('Alex (Pembeli)', kind: BtnKind.outline, expand: true,
                          onTap: () => _submit('alex@demo.id', '123456')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Btn('Rina (Penjastip)', kind: BtnKind.soft, expand: true,
                          onTap: () => _submit('rina@demo.id', '123456')),
                    ),
                  ]),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _user = TextEditingController();
  final _addr = TextEditingController();
  final _phone = TextEditingController();
  final _pw = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _user, _addr, _phone, _pw]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AppState>().repo.register(
            name: _name.text,
            email: _email.text,
            username: _user.text,
            address: _addr.text,
            phone: _phone.text,
            password: _pw.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return PageShell(
      title: 'Registrasi',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text('Buat akun baru', style: tx(28, w: FontWeight.w800, color: p.ink, ls: -0.9)),
          const SizedBox(height: 6),
          Text('Satu akun bisa jadi pembeli sekaligus penjastip.', style: tx(14, color: p.muted)),
          const SizedBox(height: 22),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(children: [
                GlassField(controller: _name, label: 'Nama lengkap', hint: 'Nama sesuai KTP',
                    icon: Icons.person_outline_rounded, action: TextInputAction.next, validator: _req),
                const SizedBox(height: 14),
                GlassField(
                  controller: _email, label: 'Email', hint: 'nama@email.com',
                  icon: Icons.mail_outline_rounded, keyboard: TextInputType.emailAddress,
                  action: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                        ? null
                        : 'Format email tidak valid';
                  },
                ),
                const SizedBox(height: 14),
                GlassField(
                  controller: _user, label: 'Username', hint: 'huruf kecil, tanpa spasi',
                  icon: Icons.alternate_email_rounded, action: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                    return RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(v.trim())
                        ? null
                        : '3-20 karakter: huruf, angka, _ atau .';
                  },
                ),
                const SizedBox(height: 14),
                GlassField(controller: _addr, label: 'Alamat', hint: 'Alamat lengkap pengiriman',
                    icon: Icons.home_outlined, maxLines: 2, validator: _req),
                const SizedBox(height: 14),
                GlassField(
                  controller: _phone, label: 'No. telepon', hint: '08xxxxxxxxxx',
                  icon: Icons.phone_outlined, keyboard: TextInputType.phone,
                  action: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                    return RegExp(r'^(\+62|62|0)8[0-9]{8,12}$').hasMatch(v.trim().replaceAll(RegExp(r'[\s-]'), ''))
                        ? null
                        : 'No. telepon tidak valid';
                  },
                ),
                const SizedBox(height: 14),
                GlassField(
                  controller: _pw, label: 'Kata sandi', hint: 'Minimal 6 karakter',
                  icon: Icons.lock_outline_rounded, obscure: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                ),
                const SizedBox(height: 22),
                Btn('Buat Akun', expand: true, large: true, busy: _busy, onTap: _submit),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
