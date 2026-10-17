import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/kids_palette.dart';
import '../../../../shared/widgets/clay.dart';
import '../../application/rewards_controller.dart';

/// Scaffold with the themed pastel background and a clay back button.
class KidsScaffold extends ConsumerWidget {
  const KidsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);
    return Scaffold(
      body: KidsBackground(
        palette: palette,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    ClayIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: KidsColors.ink),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section title used on Settings / Rewards.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.emoji});

  final String text;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        emoji == null ? text : '$emoji  $text',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
