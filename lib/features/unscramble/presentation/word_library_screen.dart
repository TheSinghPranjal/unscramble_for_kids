import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/kids_palette.dart';
import '../../../shared/widgets/clay.dart';
import '../data/image_assets.dart';
import '../data/word_repository.dart';
import '../domain/word_entry.dart';
import 'widgets/kids_scaffold.dart';
import 'widgets/word_picture.dart';

/// Grown-up tool: verify every word ↔ image mapping after dropping in art.
class WordLibraryScreen extends ConsumerStatefulWidget {
  const WordLibraryScreen({super.key});

  @override
  ConsumerState<WordLibraryScreen> createState() => _WordLibraryScreenState();
}

class _WordLibraryScreenState extends ConsumerState<WordLibraryScreen> {
  String _query = '';
  int? _length;
  String? _category;
  bool _needsArtOnly = false;

  List<WordEntry> _filter(List<WordEntry> words, Map<String, ImageStatus> a) {
    final q = _query.trim().toUpperCase();
    return [
      for (final w in words)
        if ((_length == null || w.length == _length) &&
            (_category == null || w.category == _category) &&
            (q.isEmpty ||
                w.word.contains(q) ||
                w.imagePath.toUpperCase().contains(q)) &&
            (!_needsArtOnly ||
                (a[w.imagePath] ?? ImageStatus.ok) != ImageStatus.ok))
          w,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(wordBankProvider).value;
    final audit = ref.watch(imageAuditProvider).value ?? const {};
    if (bank == null) {
      return const KidsScaffold(
        title: 'Word & Image Library',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final rows = _filter(bank.words, audit);
    final counts = {
      for (final s in ImageStatus.values)
        s: audit.values.where((v) => v == s).length,
    };

    return KidsScaffold(
      title: 'Word & Image Library',
      actions: [
        ClayIconButton(
          key: const Key('copy-report'),
          icon: Icons.copy_all_rounded,
          tooltip: 'Copy mapping report',
          onPressed: () => _copyReport(bank.words, audit),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              children: [
                TextField(
                  key: const Key('library-search'),
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Search words or paths',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: KidsColors.cream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      for (final n in const [null, 3, 4, 5])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(n == null ? 'All' : '$n letters'),
                            selected: _length == n,
                            onSelected: (_) => setState(() => _length = n),
                          ),
                        ),
                      const SizedBox(width: 4),
                      DropdownButton<String?>(
                        value: _category,
                        borderRadius: BorderRadius.circular(18),
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          color: KidsColors.ink,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All categories'),
                          ),
                          for (final c in bank.categories)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (c) => setState(() => _category = c),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        key: const Key('needs-art-filter'),
                        label: const Text('Needs art only'),
                        selected: _needsArtOnly,
                        onSelected: (v) => setState(() => _needsArtOnly = v),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Showing ${rows.length} of ${bank.words.length} words · '
                    '✅ ${counts[ImageStatus.ok]} OK · '
                    '🎨 ${counts[ImageStatus.placeholder]} placeholder · '
                    '⚠️ ${counts[ImageStatus.missing]} missing',
                    key: const Key('library-summary'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: KidsColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      'No words match these filters.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    key: const Key('library-list'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: rows.length,
                    itemBuilder: (context, i) => _LibraryRow(
                      entry: rows[i],
                      status: audit[rows[i].imagePath],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _copyReport(List<WordEntry> words, Map<String, ImageStatus> audit) {
    final b = StringBuffer()
      ..writeln('Unscramble image mapping report')
      ..writeln('words: ${words.length}');
    for (final s in ImageStatus.values) {
      b.writeln('${s.name}: ${audit.values.where((v) => v == s).length}');
    }
    b.writeln();
    for (final w in words) {
      final s = audit[w.imagePath] ?? ImageStatus.ok;
      if (s != ImageStatus.ok) {
        b.writeln('${s.name}\t${w.word}\t${w.imagePath}');
      }
    }
    Clipboard.setData(ClipboardData(text: b.toString()));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Mapping report copied')));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final ImageStatus? status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      ImageStatus.ok => ('OK', Icons.check_circle_rounded, KidsColors.mint),
      ImageStatus.placeholder => (
        'Placeholder',
        Icons.brush_rounded,
        KidsColors.yellow,
      ),
      ImageStatus.missing => (
        'Missing image',
        Icons.warning_rounded,
        KidsColors.coral,
      ),
      null => ('Checking…', Icons.hourglass_empty_rounded, KidsColors.slot),
    };
    return ClayChip(
      label: label,
      color: color,
      fontSize: 13,
      leading: Icon(icon, size: 16, color: KidsColors.ink),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({required this.entry, required this.status});

  final WordEntry entry;
  final ImageStatus? status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key('word-row-${entry.word}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: ClayCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          radius: 20,
          depth: 0.6,
          child: Row(
            children: [
              WordPicture(entry: entry, size: 64, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.word,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '${entry.category} · ${entry.length} letters',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      entry.imagePath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KidsColors.inkSoft,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClayCard(
                padding: const EdgeInsets.all(10),
                child: WordPicture(entry: entry, size: 220),
              ),
              const SizedBox(height: 16),
              Text(
                entry.word,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '💡 ${entry.hintText}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ClayChip(
                    label: entry.category,
                    color: KidsColors.forCategory(entry.category),
                  ),
                  ClayChip(label: '${entry.length} letters'),
                  ClayChip(label: entry.difficulty.name),
                  _StatusChip(status),
                ],
              ),
              const SizedBox(height: 16),
              _DetailLine('Asset path', entry.imagePath),
              _DetailLine('Expected filename', entry.expectedFileName),
              _DetailLine('Word id', entry.id),
              if (!entry.imagePathMatchesWord)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠️ Path does not match the naming rule '
                    '<n>_letter/<word>.png',
                    style: TextStyle(color: KidsColors.wrong),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
