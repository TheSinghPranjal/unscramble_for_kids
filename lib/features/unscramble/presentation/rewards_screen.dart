import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/kids_palette.dart';
import '../../../shared/widgets/clay.dart';
import '../../../shared/widgets/confetti.dart';
import '../application/rewards_controller.dart';
import '../data/image_assets.dart';
import '../domain/rewards.dart';
import 'widgets/kids_scaffold.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(rewardsControllerProvider);
    final next = RewardsController.nextStarReward(progress);
    return KidsScaffold(
      title: 'My Rewards',
      body: DefaultTabController(
        length: 3,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ClayCard(
                    color: KidsColors.yellow,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 56,
                          color: KidsColors.ink,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${progress.totalStars} stars',
                                key: const Key('rewards-total-stars'),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              if (next != null) ...[
                                Text(
                                  '${next.starsNeeded! - progress.totalStars} '
                                  'more for ${next.emoji} ${next.name}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                ClayProgressBar(
                                  value:
                                      progress.totalStars / next.starsNeeded!,
                                  color: KidsColors.coral,
                                ),
                              ] else
                                const Text(
                                  'You unlocked every sticker! 🎉',
                                  style: TextStyle(fontSize: 16),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (progress.isFresh)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ClayCard(
                      key: Key('rewards-empty'),
                      color: KidsColors.mint,
                      child: Row(
                        children: [
                          Text('🌱', style: TextStyle(fontSize: 32)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Play to earn your first star!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: clayInsetDecoration(
                      KidsColors.slot,
                      radius: 24,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: clayDecoration(KidsColors.cream, radius: 20),
                      labelColor: KidsColors.ink,
                      unselectedLabelColor: KidsColors.inkSoft,
                      labelStyle: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [
                        Tab(text: 'Stickers'),
                        Tab(text: 'Badges'),
                        Tab(text: 'Themes'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _StickerGrid(progress: progress),
                      _BadgeList(progress: progress),
                      _ThemeList(progress: progress),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Emoji on a clay disc, or final art when the asset is bundled.
class RewardArt extends ConsumerWidget {
  const RewardArt({
    super.key,
    required this.item,
    required this.size,
    required this.unlocked,
  });

  final RewardItem item;
  final double size;
  final bool unlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = item.assetPath;
    // Optional final art: used only when the file is actually bundled.
    final hasArt =
        path != null &&
        (ref.watch(assetKeysProvider).value?.contains(path) ?? false);
    Widget art = hasArt
        ? Image.asset(path, width: size * 0.7, height: size * 0.7)
        : Text(item.emoji, style: TextStyle(fontSize: size * 0.5, height: 1));
    if (!unlocked) {
      // Greyed silhouette for locked rewards.
      art = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFFB8B2BF), BlendMode.srcIn),
        child: Opacity(opacity: 0.6, child: art),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: clayDecoration(
        unlocked ? KidsColors.cream : KidsColors.locked,
        radius: size / 2,
        depth: 0.7,
      ),
      child: art,
    );
  }
}

class _StickerGrid extends StatelessWidget {
  const _StickerGrid({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 200,
      ),
      itemCount: RewardCatalog.stickers.length,
      itemBuilder: (context, i) {
        final item = RewardCatalog.stickers[i];
        final unlocked = RewardCatalog.isEarned(item, progress);
        return Semantics(
          button: true,
          label: unlocked
              ? '${item.name} sticker'
              : '${item.name}, locked, needs ${item.starsNeeded} stars',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => _preview(context, item, unlocked),
            child: ClayCard(
              color: unlocked ? KidsColors.peach : KidsColors.slot,
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RewardArt(item: item, size: 76, unlocked: unlocked),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!unlocked)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          const Icon(Icons.lock_rounded, size: 16),
                          Text(
                            ' ${item.starsNeeded} ⭐',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _preview(BuildContext context, RewardItem item, bool unlocked) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Bounce(
                    trigger: 1,
                    playOnMount: true,
                    from: 0.4,
                    child: RewardArt(item: item, size: 160, unlocked: unlocked),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    unlocked
                        ? item.description
                        : 'Collect ${item.starsNeeded} stars to unlock!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ClayButton.label(
                    onPressed: () => Navigator.of(context).pop(),
                    label: unlocked ? 'In my collection!' : 'OK',
                    icon: unlocked ? Icons.check_rounded : null,
                    color: KidsColors.mint,
                  ),
                ],
              ),
            ),
            if (unlocked)
              const Positioned.fill(child: ConfettiBurst(pieces: 30)),
          ],
        ),
      ),
    );
  }
}

class _BadgeList extends StatelessWidget {
  const _BadgeList({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final badges = [
      for (final rule in RewardCatalog.badges) rule.progressFor(progress),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: badges.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final b = badges[i];
        return Semantics(
          label:
              '${b.item.name}: ${b.item.description} '
              '${b.earned ? 'Earned' : '${b.current} of ${b.target}'}',
          excludeSemantics: true,
          child: ClayCard(
            color: b.earned ? KidsColors.mint : KidsColors.cream,
            child: Row(
              children: [
                RewardArt(item: b.item, size: 60, unlocked: b.earned),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.item.name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (b.earned)
                            const Icon(Icons.verified_rounded, size: 24),
                        ],
                      ),
                      Text(
                        b.item.description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: KidsColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClayProgressBar(
                              value: b.fraction,
                              color: b.earned
                                  ? KidsColors.success
                                  : KidsColors.sky,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${b.current.clamp(0, b.target)}/${b.target}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeList extends ConsumerWidget {
  const _ThemeList({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palettes = ClayPalette.all;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: palettes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final palette = palettes[i];
        final item = RewardCatalog.byId(palette.id);
        final unlocked = item == null || RewardCatalog.isEarned(item, progress);
        final equipped = progress.equippedTheme == palette.id;
        return ClayCard(
          color: equipped ? palette.bgTop : KidsColors.cream,
          child: Row(
            children: [
              for (final c in [
                palette.primary,
                palette.secondary,
                palette.accent,
              ])
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: clayDecoration(c, radius: 14, depth: 0.4),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      unlocked
                          ? (item?.description ?? 'The original clay look.')
                          : 'Unlocks at ${item.starsNeeded} ⭐',
                      style: const TextStyle(
                        fontSize: 15,
                        color: KidsColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (equipped)
                const ClayChip(
                  label: 'Equipped',
                  leading: Icon(Icons.check_rounded, size: 18),
                  color: KidsColors.mint,
                  fontSize: 15,
                )
              else
                ClayButton.label(
                  onPressed: unlocked
                      ? () => ref
                            .read(rewardsControllerProvider.notifier)
                            .equipTheme(palette.id)
                      : null,
                  label: unlocked ? 'Use' : 'Locked',
                  icon: unlocked ? null : Icons.lock_rounded,
                  color: KidsColors.yellow,
                  fontSize: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
