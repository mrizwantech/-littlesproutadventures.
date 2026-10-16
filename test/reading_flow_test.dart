import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_learners/features/profile/domain/child_profile.dart';
import 'package:little_learners/features/profile/presentation/learning_dashboard.dart';
import 'package:little_learners/features/listening/data/prompt_speaker.dart';
import 'package:little_learners/features/listening/domain/vocabulary_round.dart';
import 'package:little_learners/features/reading/domain/reading_pathway.dart';
import 'package:little_learners/features/reading/presentation/reading_pathway_screen.dart';
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
    await tester.ensureVisible(find.text('Ready to Read'));
    await tester.tap(find.text('Ready to Read'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadingPathwayScreen), findsOneWidget);
    expect(find.byType(VocabularyGameScreen), findsNothing);
    expect(find.text('1. Story Time'), findsOneWidget);
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

  testWidgets('Pathway exposes every stage and labels unfinished activities',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReadingPathwayScreen()));
    await tester.pumpAndSettle();
    expect(find.text('1. Story Time'), findsOneWidget);
    expect(find.text('Play Picture Words'), findsNothing);
    expect(find.textContaining('Listen & Discover'), findsNothing);
    await tester.scrollUntilVisible(
        find.text('5. Ready for Kindergarten'), 300);
    expect(find.text('5. Ready for Kindergarten'), findsOneWidget);
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
