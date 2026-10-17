import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/prefs/app_settings.dart';
import '../../../shared/theme/kids_palette.dart';
import '../../../shared/widgets/clay.dart';
import 'widgets/kids_scaffold.dart';

/// Three simple coach steps: look → drag → win stars.
class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key, this.firstRun = false});

  /// Shown automatically before the very first game.
  final bool firstRun;

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen> {
  final _pages = PageController();
  int _page = 0;
  late bool _dontShowAgain = widget.firstRun;

  static const _steps = [
    (
      'Look at the picture',
      'The picture tells you the secret word.',
      KidsColors.peach,
    ),
    (
      'Drag or tap the letters',
      'Put the letters in the boxes to spell the word.',
      KidsColors.sky,
    ),
    (
      'Win stars!',
      'Collect stars to unlock stickers and badges.',
      KidsColors.yellow,
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    if (_dontShowAgain) ref.read(settingsProvider.notifier).setCoachSeen(true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _steps.length - 1;
    return KidsScaffold(
      title: 'How to Play',
      actions: [
        TextButton(
          onPressed: _finish,
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          child: const Text(
            'Skip',
            style: TextStyle(fontSize: 18, color: KidsColors.inkSoft),
          ),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final (title, body, color) = _steps[i];
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: ClayCard(
                        color: color,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: Center(child: _illustration(i))),
                            Text(
                              '${i + 1}. $title',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 28 : 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? KidsColors.coral
                            : KidsColors.locked,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
              CheckboxListTile(
                value: _dontShowAgain,
                onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
                title: const Text(
                  'Don’t show this again',
                  style: TextStyle(fontSize: 18),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ClayButton.label(
                  onPressed: last
                      ? _finish
                      : () => _pages.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                  label: last ? 'Let’s play!' : 'Next',
                  icon: last
                      ? Icons.play_arrow_rounded
                      : Icons.arrow_forward_rounded,
                  color: KidsColors.mint,
                  expand: true,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _illustration(int step) {
    switch (step) {
      case 0:
        return const ClayCard(
          padding: EdgeInsets.all(24),
          child: Text('🐱', style: TextStyle(fontSize: 96)),
        );
      case 1:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, l) in 'CAT'.split('').indexed)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Transform.rotate(
                  angle: (i - 1) * 0.12,
                  child: ClayLetterTile(
                    letter: l,
                    size: 72,
                    color: KidsColors.tileFills[i + 2],
                  ),
                ),
              ),
          ],
        );
      default:
        return const StarRow(filled: 3, total: 3, size: 72);
    }
  }
}
