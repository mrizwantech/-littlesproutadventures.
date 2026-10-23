import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_learners/features/listening/data/prompt_speaker.dart';
import 'package:little_learners/features/counting/domain/counting_narration.dart';
import 'package:little_learners/features/shapes/domain/shapes_curriculum.dart';
import 'package:little_learners/features/reading/data/bundled_reading_prompt_speaker.dart';
import 'package:little_learners/features/reading/domain/phonics_curriculum.dart';
import 'package:little_learners/features/reading/domain/reading_narration.dart';
import 'package:little_learners/features/reading/presentation/reading_lesson_screen.dart';
import 'package:little_learners/features/reading/presentation/reading_pathway_screen.dart';

// Sentences spoken in tests that have no bundled recording.
final _unrecorded = <String>[];

class _MemorySpeaker implements PromptSpeaker {
  final spoken = <String>[];
  bool fail = false;
  int stops = 0;

  @override
  Future<void> speak(String text) async {
    if (!ReadingNarration.all.values.contains(text)) _unrecorded.add(text);
    if (fail) throw StateError('Audio playback failed');
    spoken.add(text);
  }

  @override
  Future<void> stop() async => stops++;
}

class _ControlledAudioOutput implements ReadingAudioOutput {
  Completer<void>? playback;
  final played = <String>[];

  @override
  Future<void> play(String assetPath) {
    played.add(assetPath);
    playback = Completer<void>();
    return playback!.future;
  }

  @override
  Future<void> stop() async {
    final current = playback;
    if (current != null && !current.isCompleted) current.complete();
  }
}

void main() {
  test('Short celebration cheers use Bella without changing lesson voices', () {
    final manifest = jsonDecode(
      File(BundledReadingPromptSpeaker.manifestPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(ReadingNarration.celebrations, hasLength(3));
    expect(ReadingNarration.celebrations.toSet(), hasLength(3));
    expect(manifest['voice'], 'kokoro-82m/af_heart');
    for (var index = 0; index < ReadingNarration.celebrations.length; index++) {
      final file = 'celebration_${index + 1}.m4a';
      expect(manifest['clips'][ReadingNarration.celebrations[index]], file);
      expect(manifest['clipVoices'][file], 'af_bella');
      expect(manifest['clipSpeeds'][file], 1.08);
    }
  });

  tearDown(() {
    expect(_unrecorded, isEmpty, reason: 'Add these to ReadingNarration');
    _unrecorded.clear();
  });

  for (final reducedMotion in [false, true]) {
    testWidgets(
        'Mascot follows actual playback (reduced motion: $reducedMotion)',
        (tester) async {
      final manifest = Completer<String>();
      final output = _ControlledAudioOutput();
      final speaker = BundledReadingPromptSpeaker.forTesting(
        output: output,
        loadManifest: (_) => manifest.future,
      );
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: ReadingLessonScreen(
            lesson: phonicsLessons[1],
            speaker: speaker,
          ),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('mascot-idle')), findsOneWidget);
      manifest.complete(jsonEncode({
        'clips': {
          ReadingNarration.introduction(phonicsLetters['b']!): 'intro_b.m4a',
          '/b/': 'sound_b.m4a',
        },
      }));
      await tester.pump();
      await tester.pump();
      final mascot = find.byKey(const ValueKey('mascot-speaking'));
      expect(mascot, findsOneWidget);
      expect(output.played, ['assets/audio/reading/intro_b.m4a']);
      await tester.pump(const Duration(milliseconds: 225));
      final transform = tester.widget<Transform>(mascot);
      expect(transform.transform.getTranslation().y,
          reducedMotion ? isZero : lessThan(0));
      output.playback!.complete();
      await tester.pump();
      await tester.pump();
      expect(output.played, [
        'assets/audio/reading/intro_b.m4a',
        'assets/audio/reading/sound_b.m4a',
      ]);
      output.playback!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mascot-idle')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('Generates letter lessons in alphabetical order starting with A', () {
    expect(alphabet, 'abcdefghijklmnopqrstuvwxyz');
    expect(phonicsLetters, hasLength(26));
    expect(phonicsLessons, hasLength(26));
    expect(
      phonicsLessons.map((lesson) => lesson.letter).join(),
      alphabet,
    );
    expect(phonicsLessons.first.title, 'Letter A');
    expect(phonicsLessons.first.number, 1);
    expect(phonicsLessons.last.title, 'Letter Z');
    expect(
      phonicsLessons.map((lesson) => lesson.reviewLetters.length),
      orderedEquals(List.generate(26, (index) => index)),
    );
    expect(phonicsLetters['a']!.targetSound, '/æ/');
    expect(phonicsLetters['a']!.soundDescription, 'short a');
    expect(phonicsLetters['a']!.name, 'ay');
    expect(phonicsLetters['i']!.targetSound, '/ɪ/');
  });

  test('Every letter has natural spoken sound narration', () {
    for (final letter in phonicsLetters.values) {
      final phrase = letter.spokenSoundPhrase;
      expect(phrase, startsWith('the '), reason: letter.lowercase);
      expect(phrase, isNot(contains('the the')), reason: letter.lowercase);
      expect(phrase, contains(letter.exampleWord), reason: letter.lowercase);
      expect(phrase, isNot(contains('/')), reason: letter.lowercase);
    }
    expect(phonicsLetters['a']!.spokenSoundPhrase,
        'the short a sound, as in apple');
    expect(phonicsLetters['b']!.spokenSoundPhrase,
        'the sound at the start of ball');
    expect(
        phonicsLetters['c']!.spokenSoundPhrase, 'the hard c sound, as in cat');
    expect(
        phonicsLetters['x']!.spokenSoundPhrase, 'the sound at the end of box');
  });

  test('Words appear only after their letter connections are introduced', () {
    for (final lesson in phonicsLessons) {
      for (final text in lesson.words) {
        final word = phonicsWords[text]!;
        expect(word.lesson, lesson.number);
        expect(isDecodableByLesson(word), isTrue, reason: text);
      }
    }
    expect(phonicsLessons[12].oralBlend, 'am');
    expect(phonicsLessons[12].words, contains('am'));
    expect(phonicsWords['am']!.lesson, 13);
    expect(
      phonicsLessons.expand((lesson) => lesson.words),
      isNot(contains('the')),
    );
    expect(
      phonicsLessons.expand((lesson) => lesson.words),
      isNot(contains('said')),
    );
  });

  testWidgets('The am lesson models, guides, and records caregiver evidence',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final speaker = _MemorySpeaker();
    await tester.pumpWidget(MaterialApp(
      home: ReadingLessonScreen(
        lesson: phonicsLessons[12],
        speaker: speaker,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('m'), findsOneWidget);
    expect(find.textContaining('sound in moon /m/'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('letter-audio-Sound')));
    await tester.pumpAndSettle();
    expect(speaker.spoken.last, '/m/');

    Future<void> nextActivity() async {
      final action = find.text('Continue');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
    }

    await nextActivity();
    expect(find.text('Find lowercase m'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.ancestor(
                of: find.text('Continue'), matching: find.byType(FilledButton)))
            .onPressed,
        isNull);
    await tester.tap(find.bySemanticsLabel('Letter m'));
    await tester.pumpAndSettle();

    await nextActivity();
    await tester.tap(find.bySemanticsLabel('Letter m'));
    await tester.pumpAndSettle();
    await nextActivity();
    expect(find.text('Listen as the sounds are joined. You can try too.'),
        findsOneWidget);
    expect(speaker.spoken.last,
        'Listen as the sounds are joined. You can try too.');
    await tester.tap(find.bySemanticsLabel('Hear sound /m/'));
    await tester.pumpAndSettle();
    expect(speaker.spoken.last, '/m/');
    await nextActivity();
    expect(find.text('Let’s slide the sounds together.'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);

    await nextActivity();
    expect(find.text('Your turn. Start here and slide.'), findsOneWidget);
    await nextActivity();

    expect(find.text('Try reading this word.'), findsOneWidget);
    await tester.tap(find.text('Read independently'));
    await tester.pumpAndSettle();
    await nextActivity();

    expect(find.textContaining('talk about what am means'), findsOneWidget);
    expect(
        speaker.spoken,
        contains(
            'Am is a word we use when we talk about ourselves. I am happy.'));
    expect(find.textContaining('not a reading test'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingLessonScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Letter introduction follows the Meet the letter design',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final speaker = _MemorySpeaker();
    await tester.pumpWidget(MaterialApp(
      home: ReadingLessonScreen(
        lesson: phonicsLessons.first,
        speaker: speaker,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Meet the letter'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Let’s learn B!'), findsOneWidget);
    expect(find.bySemanticsLabel('Friendly sprout cheering you on'),
        findsOneWidget);
    // Short vowels say their sound inside the introduction.
    expect(speaker.spoken, [
      'This is uppercase A and lowercase a. The letter name is ay. '
          'We are learning the short a sound. It sounds like a, a, apple.',
    ]);

    await tester.tap(find.byKey(const ValueKey('letter-audio-Name')));
    await tester.pumpAndSettle();
    expect(speaker.spoken.last, contains('ay'));
    await tester.tap(find.byKey(const ValueKey('letter-audio-Sound')));
    await tester.pumpAndSettle();
    expect(speaker.spoken.last, '/æ/');
  });

  testWidgets('Voice errors allow retry without using device TTS',
      (tester) async {
    const channel = MethodChannel('flutter_tts');
    final ttsCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        ttsCalls.add(call);
        return call.method == 'isLanguageAvailable' ? true : 1;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    final speaker = _MemorySpeaker()..fail = true;
    await tester.pumpWidget(MaterialApp(
      home: ReadingLessonScreen(
        lesson: phonicsLessons.first,
        speaker: speaker,
      ),
    ));
    await tester.pumpAndSettle();

    final voiceStatus = tester.widget<Text>(
      find.byKey(const ValueKey('reading-voice-status')),
    );
    expect(voiceStatus.data,
        'The reading voice could not play. Please try again or ask a grown-up for help.');
    expect(ttsCalls, isEmpty);
    speaker.fail = false;
    await tester.tap(find.text('Try voice again'));
    await tester.pumpAndSettle();
    expect(speaker.spoken, hasLength(1));
    expect(find.byKey(const ValueKey('reading-voice-status')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(ttsCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  test('Every Reading sentence has a bundled recording', () {
    final manifest = BundledReadingPromptSpeaker.parseManifest(
      File(BundledReadingPromptSpeaker.manifestPath).readAsStringSync(),
    );
    expect(manifest.keys.toSet(), {
      ...ReadingNarration.all.values,
      ...CountingNarration.all.values,
      ...ShapesNarration.all.values,
    });
    for (final file in manifest.values) {
      final clip = File('${BundledReadingPromptSpeaker.audioDirectory}/$file');
      expect(clip.existsSync(), isTrue, reason: file);
      expect(clip.lengthSync(), greaterThan(1000), reason: file);
    }
  });

  test('Missing bundled recordings fail loudly instead of staying silent',
      () async {
    final speaker = BundledReadingPromptSpeaker.forTesting(
      output: _ControlledAudioOutput(),
      loadManifest: (_) async => '{"clips": {}}',
    );
    await expectLater(speaker.speak('Unrecorded text'), throwsStateError);
    expect(speaker.isSpeaking.value, isFalse);
  });

  testWidgets('Sound-to-letter choice does not display its answer',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final speaker = _MemorySpeaker();
    await tester.pumpWidget(MaterialApp(
      home: ReadingLessonScreen(
        lesson: phonicsLessons[1],
        speaker: speaker,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Find lowercase b'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Text &&
          widget.data == 'a' &&
          widget.style?.fontSize == 112),
      findsNothing,
    );
    await tester.tap(find.bySemanticsLabel('Letter b'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Listen to the sound, then choose its letter.'),
        findsOneWidget);
    expect(find.textContaining('Model short a'), findsNothing);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Text &&
          widget.data == 'a' &&
          widget.style?.fontSize == 112),
      findsNothing,
    );
    expect(speaker.spoken.skip(speaker.spoken.length - 2),
        ['Listen to the sound, then choose its letter.', '/b/']);
    expect(find.textContaining('/b/'), findsNothing);
    await tester.tap(find.text('Hear again'));
    await tester.pumpAndSettle();
    expect(speaker.spoken.last, '/b/');
  });

  testWidgets(
      'Completing letters shows a celebration before opening the next letter',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final speaker = _MemorySpeaker();
    await tester.pumpWidget(MaterialApp(
      home: ReadingPathwayScreen(speaker: speaker),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start with A').last);
    await tester.tap(find.text('Start with A').last);
    await tester.pumpAndSettle();
    expect(find.text('Meet the letter'), findsOneWidget);
    await tester.tap(find.text('Let’s learn B!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('You practiced A!'), findsOneWidget);
    expect(find.byKey(const ValueKey('mascot-celebrating')), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    final celebration = speaker.spoken.last;
    expect(ReadingNarration.celebrations, contains(celebration));
    await tester.tap(find.text('Hear celebration again'));
    await tester.pump();
    expect(speaker.spoken.last, celebration);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('You practiced A!'), findsOneWidget);
    expect(find.text('Letter B'), findsNothing);
    final stopsBeforeNext = speaker.stops;
    await tester.tap(find.text('Next letter: B'));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(speaker.stops, greaterThan(stopsBeforeNext));
    expect(speaker.spoken.last, '/b/');
    for (var index = 0; index < 2; index++) {
      if (index > 0) {
        await tester.tap(find.bySemanticsLabel('Letter b'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.bySemanticsLabel('Letter b'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let’s learn C!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('You practiced B!'), findsOneWidget);
    await tester.tap(find.text('Next letter: C'));
    await tester.pumpAndSettle();
    expect(find.text('C'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
    expect(speaker.spoken.skip(speaker.spoken.length - 2), [
      ReadingNarration.introduction(phonicsLetters['c']!),
      '/k/',
    ]);
    await tester.tap(find.byTooltip('Finish for now'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with C'), findsOneWidget);
    expect(find.text('2 of 26 letters explored'), findsOneWidget);
  });

  testWidgets('Celebration fits large text and respects reduced motion',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final completed = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(2),
          disableAnimations: true,
        ),
        child: ReadingLessonScreen(
          lesson: phonicsLessons.first,
          speaker: _MemorySpeaker(),
          onLessonCompleted: (lesson, _) => completed.add(lesson.number),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Let’s learn B!'));
    await tester.tap(find.text('Let’s learn B!'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(completed, [1]);
    final mascot = find.byKey(const ValueKey('mascot-celebrating'));
    expect(tester.widget<Transform>(mascot).transform.getTranslation().y, 0);
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.ensureVisible(find.text('Next letter: B'));
    await tester.tap(find.text('Next letter: B'));
    await tester.pumpAndSettle();
    expect(find.text('Letter B'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(completed, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Celebration voice errors are visible and retry plays a variant',
      (tester) async {
    final speaker = _MemorySpeaker();
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: ReadingLessonScreen(
          lesson: phonicsLessons.first,
          speaker: speaker,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    speaker.fail = true;
    await tester.tap(find.text('Let’s learn B!'));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('The reading voice could not play'),
        ),
        findsOneWidget);
    expect(find.text('Retry celebration voice'), findsOneWidget);
    speaker.fail = false;
    await tester.tap(find.text('Retry celebration voice'));
    await tester.pumpAndSettle();
    expect(ReadingNarration.celebrations, contains(speaker.spoken.last));
    expect(
        find.textContaining('The reading voice could not play'), findsNothing);
    expect(find.text('Hear celebration again'), findsOneWidget);
    await tester.tap(find.text('Next letter: B'));
    await tester.pumpAndSettle();
    expect(find.text('Letter B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pathway letter grid opens any letter', (tester) async {
    final speaker = _MemorySpeaker();
    await tester.pumpWidget(MaterialApp(
      home: ReadingPathwayScreen(speaker: speaker),
    ));
    await tester.pumpAndSettle();
    final tile = find.bySemanticsLabel('Open letter F');
    await tester.scrollUntilVisible(tile, 300);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('Letter F'), findsOneWidget);
    expect(speaker.spoken.first,
        ReadingNarration.introduction(phonicsLetters['f']!));
  });

  testWidgets('Arrows move between letters on every lesson screen',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final speaker = _MemorySpeaker();
    final completed = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: ReadingLessonScreen(
        lesson: phonicsLessons.first,
        speaker: speaker,
        onLessonCompleted: (lesson, _) => completed.add(lesson.number),
      ),
    ));
    await tester.pumpAndSettle();
    final previous = find.byTooltip('Previous letter');
    final next = find.byTooltip('Next letter');
    expect(
        tester
            .widget<IconButton>(find
                .ancestor(of: previous, matching: find.byType(IconButton))
                .first)
            .onPressed,
        isNull);

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Letter B'), findsOneWidget);
    expect(find.text('Meet the letter'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Find lowercase b'), findsOneWidget);

    // Arrows also work from an activity screen and restart at the intro.
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Letter C'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(find.text('Letter B'), findsOneWidget);
    expect(speaker.spoken.skip(speaker.spoken.length - 2), [
      ReadingNarration.introduction(phonicsLetters['b']!),
      '/b/',
    ]);
    expect(completed, isEmpty);
  });

  testWidgets('Next-letter arrow is disabled on Z', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ReadingLessonScreen(
        lesson: phonicsLessons.last,
        speaker: _MemorySpeaker(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<IconButton>(find
                .ancestor(
                    of: find.byTooltip('Next letter'),
                    matching: find.byType(IconButton))
                .first)
            .onPressed,
        isNull);
  });

  test('Every short vowel introduction says its sound', () {
    for (final l in 'aeiou'.split('')) {
      final letter = phonicsLetters[l]!;
      expect(ReadingNarration.introductionIncludesSound(letter), isTrue);
      expect(ReadingNarration.introduction(letter),
          endsWith('It sounds like $l, $l, ${letter.exampleWord}.'));
    }
    expect(ReadingNarration.introductionIncludesSound(phonicsLetters['b']!),
        isFalse);
  });

  testWidgets('The final letter celebrates and finishes without a next letter',
      (tester) async {
    final completed = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ReadingLessonScreen(
              lesson: phonicsLessons.last,
              speaker: _MemorySpeaker(),
              onLessonCompleted: (lesson, _) => completed.add(lesson.number),
            ),
          )),
          child: const Text('Open Z'),
        ),
      ),
    ));
    await tester.tap(find.text('Open Z'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 2; index++) {
      if (index > 0) {
        await tester.ensureVisible(find.bySemanticsLabel('Letter z'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.bySemanticsLabel('Letter z'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Letter z'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.bySemanticsLabel('Letter z'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Letter z'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish alphabet'));
    await tester.pump();
    expect(find.text('You practiced Z!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Finish alphabet').last);
    await tester.pumpAndSettle();
    expect(completed, [26]);
    expect(find.byType(ReadingLessonScreen), findsNothing);
    expect(find.text('Open Z'), findsOneWidget);
  });
}
