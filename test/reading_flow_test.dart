import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_learners/features/profile/domain/child_profile.dart';
import 'package:little_learners/features/profile/presentation/learning_dashboard.dart';
import 'package:little_learners/features/listening/data/prompt_speaker.dart';
import 'package:little_learners/features/listening/domain/vocabulary_round.dart';
import 'package:little_learners/features/reading/domain/reading_pathway.dart';
import 'package:little_learners/features/reading/presentation/reading_pathway_screen.dart';
import 'package:little_learners/features/reading/presentation/reading_explore_screen.dart';
import 'package:little_learners/features/reading/presentation/reading_lesson_screen.dart';
import 'package:little_learners/features/listening/presentation/vocabulary_game_screen.dart';

class MemorySpeaker implements PromptSpeaker {
  final spoken = <String>[];
  int stops = 0;
  bool fail = false;

  @override
  Future<void> speak(String text) async {
    if (fail) throw StateError('Voice unavailable');
    spoken.add(text);
  }

  @override
  Future<void> stop() async => stops++;
}

void main() {
  testWidgets(
      'Alphabet tiles show press feedback and cancel without navigating',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ReadingPathwayScreen(speaker: MemorySpeaker()),
    ));
    await tester.pumpAndSettle();
    final tile = find.bySemanticsLabel('Open letter B');
    await tester.scrollUntilVisible(tile, 200);
    final material = find.descendant(
      of: tile,
      matching: find.byType(Material),
    );
    expect(tester.widget<Material>(material).color, Colors.white);
    final press = await tester.startGesture(tester.getCenter(tile));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<Material>(material).color, const Color(0xFFB6DFFF));
    expect(find.byType(ReadingLessonScreen), findsNothing);
    await press.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<Material>(material).color, Colors.white);
    expect(find.byType(ReadingLessonScreen), findsNothing);
    final tap = await tester.startGesture(tester.getCenter(tile));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<Material>(material).color, const Color(0xFFB6DFFF));
    await tap.up();
    await tester.pumpAndSettle();
    expect(find.byType(ReadingLessonScreen), findsOneWidget);
    expect(
      tester
          .widget<ReadingLessonScreen>(find.byType(ReadingLessonScreen))
          .lesson
          .letter,
      'b',
    );
    Navigator.of(tester.element(find.byType(ReadingLessonScreen))).pop();
    await tester.pumpAndSettle();
    expect(tester.widget<Material>(material).color, Colors.white);
    await tester.scrollUntilVisible(
        find.text('0 of 26 letters explored'), -200);
    expect(find.text('0 of 26 letters explored'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reading lesson picker supports large text on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: ReadingExploreScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Letters & Sounds'));
    await tester.tap(find.text('Letters & Sounds'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingPathwayScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ReadingExploreScreen), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Choose a lesson'), -200);
    expect(find.text('Choose a lesson'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Letters & Sounds opens the existing A-Z reading pathway',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LearningDashboard(
        profile: ChildProfile(nickname: 'Alex', ageBand: AgeBand.fourToFive),
        onSettings: () {},
        onRefresh: () {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Ready to Read'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    await tester.ensureVisible(find.text('Letters & Sounds'));
    final card = find.ancestor(
      of: find.text('Letters & Sounds'),
      matching: find.byType(Card),
    );
    expect(find.descendant(of: card, matching: find.text('Play now')),
        findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Coming soon')),
        findsNothing);
    await tester.tap(find.text('Letters & Sounds'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingPathwayScreen), findsOneWidget);
    expect(find.text('0 of 26 letters explored'), findsOneWidget);
    expect(find.text('Start with A'), findsNWidgets(2));
    await tester.scrollUntilVisible(
        find.bySemanticsLabel('Open letter Z'), 300);
    expect(find.bySemanticsLabel('Open letter Z'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard opens listening separately from Reading',
      (tester) async {
    const channel = MethodChannel('flutter_tts');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async => call.method == 'isLanguageAvailable' ? true : 1);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(MaterialApp(
      home: LearningDashboard(
        profile: ChildProfile(nickname: 'Alex', ageBand: AgeBand.fourToFive),
        onSettings: () {},
        onRefresh: () {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Listening & Vocabulary'));
    await tester.tap(find.text('Listening & Vocabulary'));
    await tester.pumpAndSettle();
    expect(find.byType(VocabularyGameScreen), findsOneWidget);
    expect(find.text('Tap the dog.'), findsOneWidget);
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.star_rounded));
    await tester.tap(find.byIcon(Icons.star_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingExploreScreen), findsOneWidget);
    expect(find.text('Choose a lesson'), findsOneWidget);
    expect(find.byType(ReadingPathwayScreen), findsNothing);
    await tester.tap(find.text('Letters & Sounds'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingPathwayScreen), findsOneWidget);
    expect(find.byType(VocabularyGameScreen), findsNothing);
    expect(find.text('Start with A'), findsNWidgets(2));
    expect(find.text('0 of 26 letters explored'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Reading has five stages separate from varied listening rounds', () {
    expect(readingStages.length, 5);
    expect(readingStages.first.title, 'Story Time');
    expect(vocabularyRounds.length, 5);
    final positions = <int>{};
    for (final round in vocabularyRounds) {
      expect(
          round.choices.where((picture) => picture.word == round.target).length,
          1);
      expect(round.choices.map((picture) => picture.word).toSet().length, 3);
      positions.add(round.choices.indexWhere((p) => p.word == round.target));
    }
    expect(positions, {0, 1, 2});
  });

  testWidgets('Pathway shows the current letter, progress, and every letter',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReadingPathwayScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Start with A'), findsNWidgets(2));
    expect(find.text('Name: ay  •  Sound: /æ/'), findsOneWidget);
    expect(find.text('Other early literacy ideas'), findsNothing);
    expect(find.text('For grown-ups: session notes'), findsNothing);
    await tester.scrollUntilVisible(
        find.bySemanticsLabel('Open letter Z'), 300);
    expect(find.byIcon(Icons.lock), findsNothing);
  });

  testWidgets('Spoken prompts, gentle modeled retry, completion and repeat',
      (tester) async {
    final speaker = MemorySpeaker();
    await tester
        .pumpWidget(MaterialApp(home: VocabularyGameScreen(speaker: speaker)));
    await tester.pumpAndSettle();
    expect(speaker.spoken.single, contains('Tap the dog.'));
    await tester.tap(find.text('Hear again'));
    await tester.pump();
    expect(speaker.spoken.last, 'Tap the dog.');
    await tester.tap(find.bySemanticsLabel('cat'));
    await tester.pumpAndSettle();
    expect(find.textContaining("That's a cat."), findsOneWidget);
    expect(find.text('Next picture'), findsNothing);
    expect(speaker.spoken.last, contains('highlighted dog'));
    final targetButton = tester.widget<OutlinedButton>(
      find.descendant(
          of: find.bySemanticsLabel('dog'),
          matching: find.byType(OutlinedButton)),
    );
    expect(targetButton.style!.backgroundColor!.resolve({}),
        const Color(0xFFDDF3C8));
    for (var index = 0; index < vocabularyRounds.length; index++) {
      final round = vocabularyRounds[index];
      await tester.tap(find.bySemanticsLabel(round.target));
      await tester.pumpAndSettle();
      expect(speaker.spoken.last, contains('Great exploring'));
      final next = find.text(
          index == vocabularyRounds.length - 1 ? 'Celebrate' : 'Next picture');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(find.text('Wonderful exploring!'), findsOneWidget);
    expect(find.textContaining('Comfortable'), findsNothing);
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(find.text('Picture 1 of 5'), findsOneWidget);
    expect(find.text('Tap the dog.'), findsOneWidget);
    expect(find.textContaining("That's a cat."), findsNothing);
    await tester.pumpWidget(const SizedBox());
    expect(speaker.stops, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Audio errors are explicit and Hear again retries',
      (tester) async {
    final speaker = MemorySpeaker()..fail = true;
    await tester
        .pumpWidget(MaterialApp(home: VocabularyGameScreen(speaker: speaker)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<StateError>());
    expect(find.textContaining('Audio is unavailable'), findsOneWidget);
    speaker.fail = false;
    await tester.tap(find.text('Hear again'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Audio is unavailable'), findsNothing);
    expect(speaker.spoken.last, 'Tap the dog.');
  });

  testWidgets('Game stops audio when backgrounded and permits an early finish',
      (tester) async {
    final speaker = MemorySpeaker();
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) =>
                            VocabularyGameScreen(speaker: speaker))),
                child: const Text('Start'),
              )),
    ));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(speaker.stops, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(speaker.stops, 2);
  });

  testWidgets('Game remains usable with large text on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: VocabularyGameScreen(speaker: MemorySpeaker()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.bySemanticsLabel('dog'));
    await tester.tap(find.bySemanticsLabel('dog'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next picture'));
    await tester.tap(find.text('Next picture'));
    await tester.pumpAndSettle();
    expect(find.text('Tap the apple.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
