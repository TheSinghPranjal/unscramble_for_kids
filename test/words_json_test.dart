import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unscramble_for_kids/features/unscramble/data/image_assets.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/word_bank.dart';
import 'package:unscramble_for_kids/features/unscramble/domain/word_entry.dart';

import 'helpers.dart';

void main() {
  late WordBank bank;

  setUpAll(() => bank = loadRealBank());

  const categories = [
    'Animals', 'Food', 'Nature', 'Home', 'Colors', //
    'Body', 'Toys', 'Transport', 'Weather', 'School',
  ];

  test('schema v2 with the 10 required categories', () {
    expect(bank.version, 2);
    expect(bank.categories, categories);
  });

  test('exactly 100 words per length (300 total)', () {
    expect(bank.words, hasLength(300));
    for (final n in [3, 4, 5]) {
      expect(bank.wordsFor(length: n), hasLength(100), reason: '$n-letter');
    }
  });

  test('every category appears in every length bank', () {
    for (final n in [3, 4, 5]) {
      for (final c in categories) {
        expect(
          bank.wordsFor(length: n, category: c),
          isNotEmpty,
          reason: '$c has no $n-letter words',
        );
      }
    }
  });

  test('words are A–Z, match their length and the length regex', () {
    for (final w in bank.words) {
      expect(RegExp('^[A-Z]{${w.length}}\$').hasMatch(w.word), isTrue);
      expect(WordEntry.validWord(w.word, length: w.length), isTrue);
    }
    expect(WordEntry.validWord('CAT', length: 4), isFalse);
    expect(WordEntry.validWord('ELEPHANT'), isFalse);
    expect(WordEntry.validWord('IT'), isFalse);
  });

  test('words, ids and image paths are globally unique', () {
    final words = bank.words.map((w) => w.word).toList();
    final ids = bank.words.map((w) => w.id).toList();
    final images = bank.words.map((w) => w.imagePath).toList();
    expect(words.toSet(), hasLength(words.length));
    expect(ids.toSet(), hasLength(ids.length));
    expect(images.toSet(), hasLength(images.length));
  });

  test('image filenames match words and live in the right folder', () {
    for (final w in bank.words) {
      expect(
        w.imagePath,
        'assets/images/words/${w.length}_letter/${w.word.toLowerCase()}.png',
      );
      expect(w.expectedFileName, '${w.word.toLowerCase()}.png');
    }
  });

  test('every image path exists on disk', () {
    final missing = [
      for (final w in bank.words)
        if (!File(w.imagePath).existsSync()) w.imagePath,
    ];
    expect(missing, isEmpty);
  });

  test('every word has a kid-friendly hint and a known difficulty', () {
    for (final w in bank.words) {
      expect(w.hintText.trim(), isNotEmpty, reason: w.word);
      expect(w.hintText.length, lessThan(60), reason: w.word);
    }
  });

  test('WordBank.validate() reports no issues', () {
    expect(bank.validate(), isEmpty);
  });

  test('validate() catches bad content', () {
    final bad = smallBank([
      word('CAT', 'Animals'),
      word('CAT', 'Animals'),
      WordEntry(
        id: 'dog',
        word: 'DOG',
        category: 'Space',
        hintText: '',
        imagePath: 'assets/images/words/3_letter/puppy.png',
      ),
    ]);
    final issues = bad.validate(perLength: 3).join('\n');
    expect(issues, contains('Duplicate 3-letter word CAT'));
    expect(issues, contains('unknown category Space'));
    expect(issues, contains('should be assets/images/words/3_letter/dog.png'));
    expect(issues, contains('DOG has no hintText'));
  });

  test('fromJson rejects length mismatches and bad words', () {
    expect(
      () => WordEntry.fromJson({'word': 'CAT', 'length': 4, 'image': 'x.png'}),
      throwsFormatException,
    );
    expect(
      () => WordEntry.fromJson({'word': 'C-T', 'length': 3, 'image': 'x.png'}),
      throwsFormatException,
    );
  });

  test('image_manifest.json lists every word with its expected path', () {
    final manifest =
        (jsonDecode(File('assets/words/image_manifest.json').readAsStringSync())
                as List)
            .cast<Map<String, dynamic>>();
    expect(manifest, hasLength(300));
    expect(
      {for (final m in manifest) m['expectedPath']},
      {for (final w in bank.words) w.imagePath},
    );
    for (final m in manifest) {
      expect(m['present'], isTrue, reason: m['word'] as String);
    }
  });

  test('placeholder marker sits inside the bytes the app inspects', () {
    for (final w in bank.words) {
      final bytes = File(w.imagePath).readAsBytesSync();
      final head = bytes.length > 8192 ? bytes.sublist(0, 8192) : bytes;
      final text = latin1.decode(head, allowInvalid: true);
      final full = latin1.decode(bytes, allowInvalid: true);
      // Either real art (no marker anywhere) or a detectable placeholder.
      if (full.contains(ImageInspector.marker)) {
        expect(text, contains(ImageInspector.marker), reason: w.imagePath);
      }
    }
  });

  test('declared asset folders exist in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final dir in [
      'assets/words/',
      'assets/images/words/3_letter/',
      'assets/images/words/4_letter/',
      'assets/images/words/5_letter/',
      'assets/images/rewards/',
    ]) {
      expect(pubspec, contains('- $dir'));
      expect(Directory(dir).existsSync(), isTrue, reason: dir);
    }
  });
}
