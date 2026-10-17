import 'dart:convert';

import 'word_entry.dart';

/// Parsed `assets/words/words.json` (schema version 2).
class WordBank {
  WordBank({
    required this.version,
    required this.categories,
    required List<WordEntry> words,
  }) : words = List.unmodifiable(words);

  factory WordBank.parse(String source) =>
      WordBank.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory WordBank.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'];
    if (rawWords is! List) {
      throw const FormatException('words.json has no "words" list');
    }
    return WordBank(
      version: json['version'] as int? ?? 1,
      categories: [
        for (final c in json['categories'] as List? ?? const []) c as String,
      ],
      words: [
        for (final w in rawWords) WordEntry.fromJson(w as Map<String, dynamic>),
      ],
    );
  }

  static const lengths = [3, 4, 5];
  static const wordsPerLength = 100;

  final int version;
  final List<String> categories;
  final List<WordEntry> words;

  /// Filter API used by the game, home screen and library.
  List<WordEntry> wordsFor({required int length, String? category}) => [
    for (final w in words)
      if (w.length == length && (category == null || w.category == category)) w,
  ];

  /// Categories that have at least one word of [length].
  List<String> categoriesFor(int length) => [
    for (final c in categories)
      if (words.any((w) => w.length == length && w.category == c)) c,
  ];

  /// Content-integrity problems. Empty list == healthy deck.
  List<String> validate({int perLength = wordsPerLength}) {
    final issues = <String>[];
    final ids = <String>{};
    final images = <String>{};
    final seen = <int, Set<String>>{};

    for (final w in words) {
      if (!ids.add(w.id)) issues.add('Duplicate id ${w.id}');
      if (!images.add(w.imagePath)) {
        issues.add('Image ${w.imagePath} used by more than one word');
      }
      if (!(seen.putIfAbsent(w.length, () => {})).add(w.word)) {
        issues.add('Duplicate ${w.length}-letter word ${w.word}');
      }
      if (!categories.contains(w.category)) {
        issues.add('${w.word} has unknown category ${w.category}');
      }
      if (!w.imagePathMatchesWord) {
        issues.add(
          '${w.word} image ${w.imagePath} should be '
          '${WordEntry.expectedImagePath(w.word)}',
        );
      }
      if (w.hintText.trim().isEmpty) issues.add('${w.word} has no hintText');
    }

    for (final n in lengths) {
      final count = wordsFor(length: n).length;
      if (count != perLength) {
        issues.add('$count $n-letter words (expected $perLength)');
      }
      for (final c in categories) {
        if (wordsFor(length: n, category: c).isEmpty) {
          issues.add('Category $c has no $n-letter words');
        }
      }
    }
    return issues;
  }
}
