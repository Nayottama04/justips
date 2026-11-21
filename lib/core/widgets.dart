import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/image_store.dart';
import '../models/models.dart';
import 'theme.dart';

// ---------------------------------------------------------------- Background
/// Latar "aurora": warna dasar + gradien radial lembut agar efek glass terlihat.
/// Blob digambar sekali di dalam RepaintBoundary supaya tidak ikut digambar ulang saat scroll.
class Aurora extends StatelessWidget {
  const Aurora({super.key, required this.child});
  final Widget child;

  Widget _blob(Color c, double a, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c.withOpacity(a), c.withOpacity(0)]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Container(
      color: p.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: Stack(children: [
                Positioned(top: -140, right: -90, child: _blob(P.emerald, p.dark ? 0.30 : 0.24, 380)),
                Positioned(top: 300, left: -170, child: _blob(const Color(0xFF6366F1), p.dark ? 0.24 : 0.13, 420)),
                Positioned(bottom: -120, right: -80, child: _blob(const Color(0xFFF59E0B), p.dark ? 0.15 : 0.11, 340)),
              ]),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Interaction
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap, this.scale = 0.97});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    final i = widget.index > 6 ? 6 : widget.index;
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: 300 + i * 50));
    _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------- Glass
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 22,
    this.onTap,
    this.blur = 0,
    this.tint,
  });
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double radius;
  final VoidCallback? onTap;

  /// 0 = tanpa blur latar (cepat). Latar aplikasi berupa gradien halus sehingga
  /// tampilannya hampir identik; blur sungguhan hanya dipakai di navbar & sheet.
  final double blur;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final br = BorderRadius.circular(radius);
    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.glassHi, tint ?? p.glassFill],
        ),
        border: Border.all(color: p.glassEdge, width: 1),
      ),
      child: child,
    );
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(p.dark ? 0.30 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: blur > 0
            ? BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: inner)
            : inner,
      ),
    );
    card = RepaintBoundary(child: card);
    if (onTap != null) card = PressScale(onTap: onTap, scale: 0.985, child: card);
    if (margin != null) card = Padding(padding: margin!, child: card);
    return card;
  }
}

Future<T?> showGlassSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (ctx) {
      final p = P.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: p.dark ? const Color(0xE60F172A) : const Color(0xEBFFFFFF),
                border: Border(top: BorderSide(color: p.glassEdge)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              color: p.line, borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

// ---------------------------------------------------------------- Buttons
enum BtnKind { primary, outline, soft, danger, amber }

class Btn extends StatelessWidget {
  const Btn(this.label,
      {super.key,
      this.onTap,
      this.icon,
      this.kind = BtnKind.primary,
      this.busy = false,
      this.expand = false,
      this.large = false});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final BtnKind kind;
  final bool busy;
  final bool expand;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    Color fg;
    Decoration deco;
    final br = BorderRadius.circular(large ? 16 : 12);
    switch (kind) {
      case BtnKind.primary:
        fg = Colors.white;
        deco = BoxDecoration(
          borderRadius: br,
          gradient: const LinearGradient(colors: [P.emeraldDeep, P.emerald]),
          boxShadow: [BoxShadow(color: P.emerald.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
        );
        break;
      case BtnKind.amber:
        fg = Colors.white;
        deco = BoxDecoration(
          borderRadius: br,
          gradient: const LinearGradient(colors: [P.amberInk, P.amber]),
          boxShadow: [BoxShadow(color: P.amber.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
        );
        break;
      case BtnKind.soft:
        fg = p.accent;
        deco = BoxDecoration(borderRadius: br, color: P.emerald.withOpacity(0.16));
        break;
      case BtnKind.danger:
        fg = p.dangerInk;
        deco = BoxDecoration(
            borderRadius: br,
            color: P.danger.withOpacity(0.08),
            border: Border.all(color: P.danger.withOpacity(0.35)));
        break;
      case BtnKind.outline:
        fg = p.ink;
        deco = BoxDecoration(
            borderRadius: br, color: p.field, border: Border.all(color: p.line));
        break;
    }
    final enabled = onTap != null && !busy;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else ...[
          if (icon != null) ...[Icon(icon, size: large ? 18 : 14, color: fg), const SizedBox(width: 6)],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tx(large ? 14 : 12, w: FontWeight.w600, color: fg, ls: 0.2)),
          ),
        ],
      ],
    );
    return Opacity(
      opacity: onTap == null && !busy ? 0.45 : 1,
      child: PressScale(
        onTap: enabled ? onTap : null,
        child: Container(
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: large ? 22 : 14, vertical: large ? 15 : 9),
          decoration: deco,
          child: content,
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton(this.icon, {super.key, this.onTap, this.badge = false});
  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          radius: 20,
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 19, color: p.ink)),
        ),
        if (badge)
          Positioned(
            right: 9,
            top: 9,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: P.danger,
                shape: BoxShape.circle,
                border: Border.all(color: p.bg, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Small parts
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.label});
  final OrderStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final c = status.color;
    final text = p.dark ? Color.lerp(c, Colors.white, 0.4)! : c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withOpacity(0.28)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(status.icon, size: 12, color: text),
        const SizedBox(width: 4),
        Text(label ?? status.label, style: tx(11, w: FontWeight.w600, color: text, ls: 0.3)),
      ]),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color, this.icon});
  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final c = color ?? const Color(0xFF6366F1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withOpacity(0.16), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 11, color: p.ink), const SizedBox(width: 3)],
        Text(text, style: tx(11, w: FontWeight.w600, color: p.dark ? Colors.white70 : const Color(0xFF475569), ls: 0.3)),
      ]),
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill(this.label, {super.key, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? (p.dark ? Colors.white : const Color(0xFF0F172A)) : p.field,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? Colors.transparent : p.line),
        ),
        child: Text(label,
            style: tx(12,
                w: FontWeight.w600,
                color: selected ? (p.dark ? const Color(0xFF0F172A) : Colors.white) : p.muted,
                ls: 0.2)),
      ),
    );
  }
}

IconData iconForItem(String name) {
  final n = name.toLowerCase();
  if (RegExp(r'kemeja|baju|jaket|kaos|dress').hasMatch(n)) return Icons.checkroom_rounded;
  if (RegExp(r'sneaker|sepatu|sandal').hasMatch(n)) return Icons.hiking_rounded;
  if (RegExp(r'headphone|earphone|speaker|airpods').hasMatch(n)) return Icons.headphones_rounded;
  if (RegExp(r'tumbler|botol|gelas|kopi|matcha|teh').hasMatch(n)) return Icons.local_cafe_rounded;
  if (RegExp(r'parfum|skincare|laneige|serum|cream').hasMatch(n)) return Icons.spa_rounded;
  if (RegExp(r'lego|mainan|toy|figure').hasMatch(n)) return Icons.toys_rounded;
  return Icons.shopping_bag_rounded;
}

class SmartImage extends StatelessWidget {
  const SmartImage(this.url, {super.key, this.size = 72, this.radius = 14, this.fallbackIcon = Icons.shopping_bag_rounded, this.fill = false});
  final String url;
  final double size;
  final double radius;
  final IconData fallbackIcon;
  final bool fill;

  Widget _placeholder(P p) => Container(
        color: P.emerald.withOpacity(p.dark ? 0.12 : 0.10),
        alignment: Alignment.center,
        child: Icon(fallbackIcon, size: size * 0.4, color: p.accent),
      );

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final int? cw = fill ? null : (size * dpr).round();
    Widget img;
    if (url.isEmpty) {
      img = _placeholder(p);
    } else if (url.startsWith('img:')) {
      img = DbImage(id: url.substring(4), cacheWidth: cw, placeholder: _placeholder(p));
    } else if (url.startsWith('http')) {
      img = Image.network(url,
          fit: BoxFit.cover, cacheWidth: cw, errorBuilder: (_, __, ___) => _placeholder(p));
    } else {
      img = Image.file(File(url),
          fit: BoxFit.cover, cacheWidth: cw, errorBuilder: (_, __, ___) => _placeholder(p));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: fill ? double.infinity : size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: p.line)),
          child: img,
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.photoUrl = '', this.size = 40, this.verified = false});
  final String name;
  final String photoUrl;
  final double size;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    Widget face = photoUrl.isNotEmpty
        ? SmartImage(photoUrl, size: size, radius: size / 2)
        : Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [P.emerald, Color(0xFF0D9488)]),
            ),
            child: Text(initial, style: tx(size * 0.4, w: FontWeight.w700, color: Colors.white)),
          );
    if (!verified) return face;
    return Stack(clipBehavior: Clip.none, children: [
      face,
      Positioned(
        right: -2,
        bottom: -2,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
              color: P.emerald,
              shape: BoxShape.circle,
              border: Border.all(color: p.bg, width: 2)),
          child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
        ),
      ),
    ]);
  }
}

class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.icon,
    this.obscure = false,
    this.keyboard,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.suffix,
    this.formatters,
    this.readOnly = false,
    this.onTap,
    this.action,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboard;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final List<TextInputFormatter>? formatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;

  OutlineInputBorder _b(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    final field = TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      maxLines: obscure ? 1 : maxLines,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: formatters,
      readOnly: readOnly,
      onTap: onTap,
      textInputAction: action,
      onFieldSubmitted: onSubmitted,
      style: tx(14, color: p.ink),
      cursorColor: P.emerald,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: tx(14, color: p.muted),
        prefixIcon: icon == null ? null : Icon(icon, size: 19, color: p.muted),
        suffixIcon: suffix,
        filled: true,
        fillColor: p.field,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: _b(p.line),
        enabledBorder: _b(p.line),
        focusedBorder: _b(P.emerald, 1.6),
        errorBorder: _b(P.danger.withOpacity(0.6)),
        focusedErrorBorder: _b(P.danger, 1.6),
        errorStyle: tx(11, color: p.dangerInk),
      ),
    );
    if (label == null) return field;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(label!, style: tx(12, w: FontWeight.w600, color: p.muted, ls: 0.2)),
      ),
      field,
    ]);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing, this.sub});
  final String title;
  final String? sub;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Flexible(child: Text(title, style: tx(22, w: FontWeight.w700, color: p.ink, ls: -0.5))),
          if (sub != null) ...[
            const SizedBox(width: 8),
            Text(sub!, style: tx(12, w: FontWeight.w600, color: p.muted)),
          ],
        ]),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: P.emerald.withOpacity(0.14)),
          child: Icon(icon, size: 30, color: p.accent),
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: tx(16, w: FontWeight.w700, color: p.ink)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: tx(13, color: p.muted, h: 1.45)),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ]),
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(strokeWidth: 2.5, color: P.emerald),
        ),
      );
}

/// Kerangka halaman dengan tombol kembali + judul (untuk layar yang di-push).
class PageShell extends StatelessWidget {
  const PageShell({super.key, required this.title, required this.child, this.actions = const [], this.bottom});
  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Aurora(
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(children: [
                GlassIconButton(Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tx(18, w: FontWeight.w700, color: p.ink, ls: -0.3)),
                ),
                ...actions,
              ]),
            ),
            Expanded(child: child),
            if (bottom != null) bottom!,
          ]),
        ),
      ),
    );
  }
}
