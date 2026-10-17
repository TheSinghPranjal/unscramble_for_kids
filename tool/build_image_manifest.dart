// Regenerates assets/words/image_manifest.json from assets/words/words.json.
//
//   dart run tool/build_image_manifest.dart
//
// For every word it records the expected asset path, whether the file is
// present on disk, and whether it is still a generated placeholder.
import 'dart:convert';
import 'dart:io';

const placeholderMarker = 'unscramble-placeholder';

bool isPlaceholder(File file) {
  final bytes = file.readAsBytesSync();
  final head = bytes.length > 4096 ? bytes.sublist(0, 4096) : bytes;
  return latin1.decode(head, allowInvalid: true).contains(placeholderMarker);
}

void main() {
  final words =
      (jsonDecode(File('assets/words/words.json').readAsStringSync())
              as Map<String, dynamic>)['words']
          as List<dynamic>;

  var present = 0, placeholders = 0;
  final manifest = <Map<String, Object>>[];
  for (final raw in words.cast<Map<String, dynamic>>()) {
    final path = raw['image'] as String;
    final file = File(path);
    final exists = file.existsSync();
    final placeholder = exists && isPlaceholder(file);
    if (exists) present++;
    if (placeholder) placeholders++;
    manifest.add({
      'word': raw['word'] as String,
      'length': raw['length'] as int,
      'category': raw['category'] as String,
      'expectedPath': path,
      'present': exists,
      'placeholder': placeholder,
    });
  }

  File('assets/words/image_manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln(
    'image_manifest.json: ${manifest.length} words, $present present, '
    '$placeholders placeholders, ${manifest.length - present} missing',
  );
}
