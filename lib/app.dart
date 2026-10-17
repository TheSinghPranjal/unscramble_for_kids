import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/unscramble/application/rewards_controller.dart';
import 'features/unscramble/presentation/boot_screen.dart';
import 'shared/theme/clay_theme.dart';

class UnscrambleApp extends ConsumerWidget {
  const UnscrambleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);
    return MaterialApp(
      title: 'Unscramble for Kids',
      debugShowCheckedModeBanner: false,
      theme: ClayTheme.build(palette),
      home: const BootScreen(),
    );
  }
}
