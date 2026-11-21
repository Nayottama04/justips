import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'theme.dart';
import 'widgets.dart';

Future<String?> pickPhoto({bool camera = false}) async {
  final x = await ImagePicker().pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 960,
    imageQuality: 60,
  );
  return x?.path;
}

/// Deretan foto + tombol tambah (galeri / kamera).
class PhotoPicker extends StatelessWidget {
  const PhotoPicker({super.key, required this.paths, required this.onChanged, this.max = 4});
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;
  final int max;

  Future<void> _add(BuildContext context) async {
    final camera = await showGlassSheet<bool>(
      context,
      Builder(builder: (ctx) {
        final p = P.of(ctx);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tambah foto', style: tx(18, w: FontWeight.w700, color: p.ink)),
          const SizedBox(height: 14),
          Btn('Ambil dengan kamera', icon: Icons.photo_camera_outlined, expand: true, large: true,
              kind: BtnKind.soft, onTap: () => Navigator.pop(ctx, true)),
          const SizedBox(height: 10),
          Btn('Pilih dari galeri', icon: Icons.photo_library_outlined, expand: true, large: true,
              kind: BtnKind.outline, onTap: () => Navigator.pop(ctx, false)),
        ]);
      }),
    );
    if (camera == null) return;
    try {
      final path = await pickPhoto(camera: camera);
      if (path != null) onChanged([...paths, path]);
    } catch (_) {
      if (context.mounted) toast(context, 'Tidak dapat membuka kamera/galeri.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = P.of(context);
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (var i = 0; i < paths.length; i++)
        Stack(clipBehavior: Clip.none, children: [
          SmartImage(paths[i], size: 82, radius: 16),
          Positioned(
            right: -6,
            top: -6,
            child: PressScale(
              onTap: () => onChanged([...paths]..removeAt(i)),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: P.danger, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ]),
      if (paths.length < max)
        PressScale(
          onTap: () => _add(context),
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: p.field,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: P.emerald.withOpacity(0.5), width: 1.4),
            ),
            child: Icon(Icons.add_a_photo_outlined, color: p.accent),
          ),
        ),
    ]);
  }
}
