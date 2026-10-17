import 'package:flutter/foundation.dart';

enum LengthMode {
  three(3, 'Easy Kids'),
  four(4, 'Growing'),
  five(5, 'Challenge');

  const LengthMode(this.length, this.label);

  final int length;
  final String label;

  String get shortLabel => '$length Letters';

  static LengthMode fromLength(int length) => values.firstWhere(
    (m) => m.length == length,
    orElse: () => LengthMode.three,
  );
}

enum Difficulty {
  easy,
  medium,
  hard;

  static Difficulty parse(Object? raw) =>
      values.firstWhere((d) => d.name == raw, orElse: () => Difficulty.easy);
}

@immutable
class WordEntry {
  const WordEntry({
    required this.id,
    required this.word,
    required this.category,
    required this.hintText,
    required this.imagePath,
    this.difficulty = Difficulty.easy,
    this.emoji,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    final word = (json['word'] as String? ?? '').trim().toUpperCase();
    final length = json['length'];
    if (!validWord(word)) {
      throw FormatException('Invalid word "$word" (must be 3–5 letters A–Z)');
    }
    if (length is! int || length != word.length) {
      throw FormatException('Word "$word" has length field $length');
    }
    final image = json['image'] as String?;
    if (image == null || image.isEmpty) {
      throw FormatException('Word "$word" has no image path');
    }
    return WordEntry(
      id: json['id'] as String? ?? '${word.toLowerCase()}_${word.length}',
      word: word,
      category: json['category'] as String? ?? 'Other',
      hintText: json['hintText'] as String? ?? '',
      difficulty: Difficulty.parse(json['difficulty']),
      emoji: json['emoji'] as String?,
      imagePath: image,
    );
  }

  final String id;
  final String word;
  final String category;
  final String hintText;
  final Difficulty difficulty;

  /// Fallback glyph drawn on placeholder / missing pictures.
  final String? emoji;
  final String imagePath;

  int get length => word.length;

  static final _pattern = RegExp(r'^[A-Z]{3,5}$');

  /// Kids deck accepts 3–5 letter words. Pass [length] to also enforce the
  /// selected length mode (`^[A-Z]{3}$`, `^[A-Z]{4}$`, `^[A-Z]{5}$`).
  static bool validWord(String word, {int? length}) =>
      _pattern.hasMatch(word) && (length == null || word.length == length);

  /// `assets/images/words/<n>_letter/<word>.png`
  static String expectedImagePath(String word) =>
      'assets/images/words/${word.length}_letter/${word.toLowerCase()}.png';

  String get expectedFileName => '${word.toLowerCase()}.png';

  bool get imagePathMatchesWord => imagePath == expectedImagePath(word);

  /// Screen-reader label for the picture clue, e.g. "Picture of a cat".
  String get pictureLabel {
    final w = word.toLowerCase();
    if (category == 'Colors') return 'Picture of the color $w';
    if (category == 'Weather' && !_nouns.contains(word)) {
      return 'Picture of $w weather';
    }
    final article = 'aeiou'.contains(w[0]) ? 'an' : 'a';
    return 'Picture of $article $w';
  }

  static const _nouns = {
    'SUN',
    'SKY',
    'FOG',
    'ICE',
    'DEW',
    'RAY',
    'RAIN',
    'SNOW',
    'WIND',
    'HAIL',
    'MIST',
    'GUST',
    'CLOUD',
    'STORM',
    'FROST',
    'SLEET',
  };

  @override
  bool operator ==(Object other) => other is WordEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'WordEntry($word)';
}
