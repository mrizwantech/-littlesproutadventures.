// Exports reading and counting narration for tool/reading_audio/generate.py.
//
// Usage: dart run tool/reading_audio/export_script.dart > script.json
import 'dart:convert';
import 'dart:io';

import 'package:little_learners/features/reading/domain/phonics_curriculum.dart';
import 'package:little_learners/features/reading/domain/reading_narration.dart';
import 'package:little_learners/features/counting/domain/counting_narration.dart';

/// Marks letter names as `{x}` and short-vowel sounds as `[x]` so the
/// generator can force exact pronunciations. Throws if the markup no longer
/// matches the app text.
String _speech(String key, String text) {
  final parts = key.split('_');
  final letter = parts.length == 2 && parts.last.length == 1
      ? phonicsLetters[parts.last]
      : null;
  if (letter == null) return text;
  final l = letter.lowercase;
  final vowel = ReadingNarration.isShortVowel(letter);
  if (parts.first == 'sound') {
    // Consonant sounds are cut from a phrase using the SOUND table.
    return vowel
        ? ReadingNarration.vowelSoundSpeech(letter)
            .replaceFirst('$l, $l, ', '[$l], [$l], ')
        : text;
  }
  var marked = switch (parts.first) {
    'name' => '{$l}',
    _ => text
        .replaceFirst('uppercase ${letter.uppercase} ', 'uppercase {$l} ')
        .replaceFirst('lowercase $l.', 'lowercase {$l}.')
        .replaceFirst('name is ${letter.name}.', 'name is {$l}.')
        .replaceFirst('the short $l sound', 'the short {$l} sound')
        .replaceFirst('the hard $l sound', 'the hard {$l} sound')
        .replaceFirst('like $l, $l, ', 'like [$l], [$l], '),
  };
  final restored = parts.first == 'name'
      ? letter.name
      : marked
          .replaceFirst('uppercase {$l}', 'uppercase ${letter.uppercase}')
          .replaceFirst('name is {$l}', 'name is ${letter.name}')
          .replaceAll('{$l}', l)
          .replaceAll('[$l]', l);
  if (restored != text ||
      !marked.contains('{$l}') ||
      vowel && parts.first == 'intro' && !marked.contains('[$l]')) {
    throw StateError('Pronunciation markup failed for "$text": "$marked".');
  }
  return marked;
}

void main() {
  final entries = [
    for (final MapEntry(:key, :value) in ReadingNarration.all.entries)
      {
        'key': key,
        'text': value,
        'speech': _speech(key, value),
        if (key.startsWith('celebration_')) 'speed': 1.08,
        if (key.startsWith('celebration_')) 'voice': 'af_bella',
      },
    for (final MapEntry(:key, :value) in CountingNarration.all.entries)
      {'key': key, 'text': value, 'speech': value},
  ];
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(entries));
}
