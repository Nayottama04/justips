import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/shell.dart';

class JustipsApp extends StatelessWidget {
  const JustipsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = context.watch<ThemeController>();
    return MaterialApp(
      title: 'Justips',
      debugShowCheckedModeBanner: false,
      themeMode: tc.mode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const Shell(),
    );
  }
}
