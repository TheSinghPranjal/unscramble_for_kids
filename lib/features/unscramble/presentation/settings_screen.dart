import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/prefs/app_settings.dart';
import '../../../shared/theme/kids_palette.dart';
import '../../../shared/widgets/clay.dart';
import '../application/rewards_controller.dart';
import '../data/image_assets.dart';
import '../data/word_repository.dart';
import '../domain/game_state.dart';
import '../domain/word_entry.dart';
import 'widgets/kids_scaffold.dart';
import 'word_library_screen.dart';

const appVersion = '1.0.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final bank = ref.watch(wordBankProvider).value;
    final audit = ref.watch(imageAuditProvider).value;
    final needsArt = audit?.values.where((v) => v != ImageStatus.ok).length;

    return KidsScaffold(
      title: 'Settings',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              const SectionTitle('Play', emoji: '🎮'),
              ClayCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Default word length',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final m in LengthMode.values) ...[
                          if (m != LengthMode.three) const SizedBox(width: 10),
                          Expanded(
                            child: ClayButton.label(
                              onPressed: () => ctrl.setDefaultLength(m.length),
                              label: m.shortLabel,
                              icon: s.defaultLength == m.length
                                  ? Icons.check_rounded
                                  : null,
                              color: s.defaultLength == m.length
                                  ? KidsColors.mint
                                  : KidsColors.cream,
                              fontSize: 16,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Divider(height: 28),
                    for (final m in LengthMode.values)
                      _SwitchRow(
                        title: 'Timer for ${m.shortLabel.toLowerCase()}',
                        subtitle: m == LengthMode.three
                            ? 'Off is best for little ones'
                            : '${GameState.timeLimitFor(m.length)} seconds per word',
                        value: s.timerFor(m.length),
                        onChanged: (v) => ctrl.setTimer(m.length, v),
                      ),
                    _SwitchRow(
                      title: 'Sound',
                      value: s.sound,
                      onChanged: ctrl.setSound,
                    ),
                    _SwitchRow(
                      title: 'Haptics (buzz)',
                      value: s.haptics,
                      onChanged: ctrl.setHaptics,
                    ),
                    _ActionRow(
                      title: 'Show “How to Play” again',
                      icon: Icons.school_rounded,
                      onTap: () {
                        ctrl.setCoachSeen(false);
                        _toast(context, 'How to Play will show next game.');
                      },
                    ),
                  ],
                ),
              ),
              const SectionTitle('Parents & learning', emoji: '👪'),
              ClayCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Default topic',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DropdownButton<String?>(
                          value: s.defaultCategory,
                          borderRadius: BorderRadius.circular(18),
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 17,
                            color: KidsColors.ink,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            for (final c
                                in bank?.categories ?? const <String>[])
                              DropdownMenuItem(
                                value: c,
                                child: Text(
                                  '${KidsColors.categoryEmoji[c] ?? ''} $c',
                                ),
                              ),
                          ],
                          onChanged: ctrl.setDefaultCategory,
                        ),
                      ],
                    ),
                    _SwitchRow(
                      title: 'Show hint text under picture',
                      subtitle: 'e.g. “Says meow and loves to nap”',
                      value: s.showHintText,
                      onChanged: ctrl.setShowHintText,
                    ),
                    _SwitchRow(
                      title: 'Easy words first',
                      subtitle: 'Start each round with the easiest words',
                      value: s.easyFirst,
                      onChanged: ctrl.setEasyFirst,
                    ),
                  ],
                ),
              ),
              const SectionTitle('Word & Image Library', emoji: '🖼️'),
              ClayCard(
                color: KidsColors.sky,
                child: _ActionRow(
                  key: const Key('open-library'),
                  title: 'Check every word’s picture',
                  subtitle: bank == null
                      ? null
                      : '${bank.words.length} words'
                            '${needsArt == null ? '' : ' · $needsArt need final art'}',
                  icon: Icons.photo_library_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WordLibraryScreen(),
                    ),
                  ),
                ),
              ),
              const SectionTitle('Data', emoji: '💾'),
              ClayCard(
                child: Column(
                  children: [
                    _ActionRow(
                      title: 'Reset progress',
                      subtitle: 'Stars, stickers, badges and high score',
                      icon: Icons.restart_alt_rounded,
                      onTap: () => _confirmReset(context, ref),
                    ),
                    const _ActionRow(
                      title: 'About',
                      subtitle: 'Unscramble for Kids · version $appVersion',
                      icon: Icons.info_rounded,
                    ),
                  ],
                ),
              ),
              const SectionTitle('Privacy', emoji: '🔒'),
              const ClayCard(
                child: Text(
                  'No accounts, no ads, no chat and no internet needed. '
                  'All progress stays on this device.',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'This clears stars, stickers, badges, streaks and the high score. '
          'It can’t be undone.',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(fontSize: 18, color: KidsColors.wrong),
            ),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(rewardsControllerProvider.notifier).reset();
      if (context.mounted) _toast(context, 'Progress reset. Fresh start!');
    }
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(fontSize: 14, color: KidsColors.inkSoft),
              ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 56,
      leading: Icon(icon, size: 28, color: KidsColors.ink),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(fontSize: 14, color: KidsColors.inkSoft),
            ),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
