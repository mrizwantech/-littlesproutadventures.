import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_learners/core/theme/app_theme.dart';
import 'package:little_learners/features/counting/domain/counting_curriculum.dart';
import 'package:little_learners/features/counting/domain/counting_narration.dart';
import 'package:little_learners/features/counting/presentation/counting_lesson_screen.dart';
import 'package:little_learners/features/counting/presentation/counting_pathway_screen.dart';
import 'package:little_learners/features/listening/data/prompt_speaker.dart';
import 'package:little_learners/features/profile/domain/child_profile.dart';
import 'package:little_learners/features/profile/presentation/learning_dashboard.dart';
import 'package:little_learners/features/reading/data/bundled_reading_prompt_speaker.dart';
import 'package:little_learners/features/reading/domain/reading_narration.dart';

class CountingSpeaker implements PromptSpeaker {
  final spoken = <String>[];
  bool fail = false;
  bool hold = false;
  Completer<void>? pending;
  int stops = 0;

  @override
  Future<void> speak(String text) async {
    expect({
      ...CountingNarration.all.values,
      ...ReadingNarration.all.values
    }, contains(text), reason: 'Missing bundled narration: $text');
    if (fail) throw StateError('Counting voice unavailable');
    spoken.add(text);
    if (hold) {
      pending = Completer<void>();
      await pending!.future;
    }
  }

  @override
  Future<void> stop() async {
    stops++;
    final current = pending;
    pending = null;
    if (current != null && !current.isCompleted) current.complete();
  }
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder get continueButton => find.widgetWithText(FilledButton, 'Continue');

Future<void> countAll(WidgetTester tester, int number) async {
  for (var id = 1; id <= number; id++) {
    await tap(tester, find.bySemanticsLabel('Count star $id'));
  }
}

Future<void> makeGroup(WidgetTester tester, int number) async {
  for (var id = 1; id <= number; id++) {
    await tap(tester, find.bySemanticsLabel('Add star $id to basket'));
  }
  await tap(tester, find.text('Check my group'));
}

Future<void> selectRange(WidgetTester tester, int start) async {
  await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<int>), -200);
  await tap(tester, find.byType(DropdownButtonFormField<int>));
  final option = find.text('$start-${start + 9}').last;
  if (option.evaluate().isEmpty) {
    await tester.scrollUntilVisible(option, 180,
        scrollable: find.byType(Scrollable).last);
  }
  await tap(tester, option);
}

Future<void> countGrouped(WidgetTester tester, CountingLesson lesson) async {
  for (var index = 1; index <= lesson.tens; index++) {
    await tap(tester, find.bySemanticsLabel('Count ten group $index'));
  }
  for (var index = 1; index <= lesson.ones; index++) {
    await tap(tester, find.bySemanticsLabel('Count star $index'));
  }
}

Future<void> buildNumber(WidgetTester tester, CountingLesson lesson) async {
  for (var index = 0; index < lesson.tens; index++) {
    await tap(tester, find.text('Add ten'));
  }
  for (var index = 0; index < lesson.ones; index++) {
    await tap(tester, find.text('Add one'));
  }
  await tap(tester, find.text('Check my number'));
}

void main() {
  test(
      'All 100 numbers have correct place value and complete offline narration',
      () async {
    expect(countingLessons.map((lesson) => lesson.number),
        List.generate(100, (index) => index + 1));
    expect(countingLessons.take(5).map((lesson) => lesson.name),
        ['one', 'two', 'three', 'four', 'five']);
    expect(CountingSkill.values, hasLength(6));
    for (final lesson in countingLessons) {
      expect(lesson.tens * 10 + lesson.ones, lesson.number);
      expect(lesson.totalChoices, contains(lesson.number));
      expect(lesson.totalChoices.toSet().length, lesson.totalChoices.length);
      expect(
          lesson.totalChoices.every((number) => number >= 1 && number <= 100),
          isTrue);
      expect(lesson.countingUnits, lessThanOrEqualTo(18));
      expect(lesson.usesTens, lesson.number > 10);
    }
    expect(countingNumberName(11), 'eleven');
    expect(countingNumberName(19), 'nineteen');
    expect(countingNumberName(20), 'twenty');
    expect(countingNumberName(32), 'thirty-two');
    expect(countingNumberName(40), 'forty');
    expect(countingNumberName(58), 'fifty-eight');
    expect(countingNumberName(99), 'ninety-nine');
    expect(countingNumberName(100), 'one hundred');
    expect(() => countingNumberName(0), throwsRangeError);
    expect(() => countingNumberName(101), throwsRangeError);
    final clips = BundledReadingPromptSpeaker.parseManifest(
        File(BundledReadingPromptSpeaker.manifestPath).readAsStringSync());
    for (final text in CountingNarration.all.values) {
      expect(clips, contains(text));
      final file =
          File('${BundledReadingPromptSpeaker.audioDirectory}/${clips[text]}');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(1000));
    }
  });

  for (final lesson in countingLessons.take(10)) {
    testWidgets('Number ${lesson.number} requires counting and an exact group',
        (tester) async {
      final speaker = CountingSpeaker();
      final completed = <int>[];
      final evidence = <CountingEvidence>[];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: CountingLessonScreen(
          lesson: lesson,
          speaker: speaker,
          onCompleted: (lesson, attempts) {
            completed.add(lesson.number);
            evidence.addAll(attempts);
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Meet number ${lesson.number}'), findsOneWidget);
      expect(speaker.spoken.last, CountingNarration.meet(lesson));
      await tap(tester, continueButton);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      await countAll(tester, lesson.number);
      expect(speaker.spoken, contains(CountingNarration.total(lesson)));
      expect(speaker.spoken, contains('${lesson.name}.'));
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      await tap(
          tester, find.widgetWithText(OutlinedButton, '${lesson.number}'));
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
      await tap(tester, continueButton);
      expect(speaker.spoken.last, CountingNarration.give(lesson));
      final finish = find.widgetWithText(
          FilledButton,
          lesson.number < 100
              ? 'Let\'s learn ${lesson.number + 1}!'
              : 'Finish counting');
      expect(tester.widget<FilledButton>(finish).onPressed, isNull);
      // No stars is not a valid group.
      await tap(tester, find.text('Check my group'));
      expect(find.text(CountingNarration.tryGroup), findsOneWidget);
      expect(tester.widget<FilledButton>(finish).onPressed, isNull);
      if (lesson.number > 1) {
        await tap(tester, find.bySemanticsLabel('Add star 1 to basket'));
        await tap(tester, find.text('Check my group'));
        expect(find.text(CountingNarration.tryGroup), findsOneWidget);
        expect(tester.widget<FilledButton>(finish).onPressed, isNull);
        await tap(tester, find.bySemanticsLabel('Remove star 1 from basket'));
      }
      // A larger source pool allows an oversized group; it is not silently capped.
      for (var id = 1; id <= lesson.number + 1; id++) {
        await tap(tester, find.bySemanticsLabel('Add star $id to basket'));
      }
      await tap(tester, find.text('Check my group'));
      expect(find.text(CountingNarration.tryGroup), findsOneWidget);
      expect(tester.widget<FilledButton>(finish).onPressed, isNull);
      await tap(
          tester,
          find.bySemanticsLabel(
              'Remove star ${lesson.number + 1} from basket'));
      await tap(tester, find.text('Check my group'));
      expect(find.text(CountingNarration.correctGroup), findsOneWidget);
      expect(tester.widget<FilledButton>(finish).onPressed, isNotNull);
      expect(completed, isEmpty);
      await tap(tester, finish);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(completed, [lesson.number]);
      expect(find.text('You practiced ${lesson.number}!'), findsOneWidget);
      expect(ReadingNarration.celebrations, contains(speaker.spoken.last));
      expect(
          evidence
              .where((item) => item.skill == CountingSkill.countingObjects)
              .single
              .correct,
          isTrue);
      expect(
          evidence
              .where((item) => item.skill == CountingSkill.understandingTotal)
              .single
              .correct,
          isTrue);
      final groups =
          evidence.where((item) => item.skill == CountingSkill.makingQuantity);
      expect(groups.map((item) => item.correct),
          [false, if (lesson.number > 1) false, false, true]);
      expect(groups.last.assisted, isTrue);
      expect(
          evidence.any((item) => item.skill == CountingSkill.countingSequence),
          isFalse);
      expect(evidence.any((item) => item.skill == CountingSkill.tensAndOnes),
          isFalse);
      expect(
          evidence
              .where((item) => item.skill == CountingSkill.numeralRecognition)
              .single
              .method,
          CountingEvidenceMethod.guidedIntroduction);
      if (lesson.number < 100) {
        await tap(tester, find.text('Next number: ${lesson.number + 1}'));
        expect(find.text('Meet number ${lesson.number + 1}'), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      } else {
        // Root-screen tests have no route to pop; validate the finish label.
        expect(find.widgetWithText(FilledButton, 'Finish counting').last,
            findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
      'Repeated stars do not count twice and wrong totals require recount',
      (tester) async {
    final speaker = CountingSpeaker();
    await tester.pumpWidget(MaterialApp(
      home: CountingLessonScreen(
        lesson: countingLessons[2],
        speaker: speaker,
        onCompleted: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();
    await tap(tester, continueButton);
    await tap(tester, find.bySemanticsLabel('Count star 2'));
    expect(speaker.spoken.last, 'one.');
    final before = speaker.spoken.length;
    await tap(tester, find.bySemanticsLabel('Count star 2'));
    expect(speaker.spoken.length, before);
    expect(find.text(CountingNarration.howMany), findsNothing);
    await tap(tester, find.bySemanticsLabel('Count star 1'));
    expect(speaker.spoken.last, 'two.');
    await tap(tester, find.bySemanticsLabel('Count star 3'));
    await tap(tester, find.widgetWithText(OutlinedButton, '2'));
    expect(find.text(CountingNarration.tryTotal), findsOneWidget);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    expect(find.widgetWithText(OutlinedButton, '3'), findsNothing);
    await countAll(tester, 3);
    await tap(tester, find.widgetWithText(OutlinedButton, '3'));
    await tap(tester, find.text('Move stars and count again'));
    expect(speaker.spoken.last, CountingNarration.rearrange);
    expect(find.text(CountingNarration.howMany), findsNothing);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    await countAll(tester, 3);
    await tap(tester, find.widgetWithText(OutlinedButton, '3'));
    expect(find.text('Three stars altogether.'), findsOneWidget);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final number in [11, 14, 19, 20, 21, 32, 50, 73, 90, 99, 100]) {
    testWidgets('$number counts grouped tens and builds exact place value',
        (tester) async {
      final speaker = CountingSpeaker();
      final lesson = countingLessons[number - 1];
      final evidence = <CountingEvidence>[];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: CountingLessonScreen(
          lesson: lesson,
          speaker: speaker,
          onCompleted: (_, attempts) => evidence.addAll(attempts),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('${lesson.tens} tens + ${lesson.ones} ones'),
          findsOneWidget);
      expect(speaker.spoken.last, CountingNarration.number(number));
      // A ten-frame is one unit, not ten separate tapping targets.
      expect(find.bySemanticsLabel(RegExp(r'^Ten-frame \d+: 10 stars$')),
          findsNWidgets(lesson.tens));
      await tap(tester, continueButton);
      expect(speaker.spoken.last, CountingNarration.countTens);
      expect(find.bySemanticsLabel(RegExp(r'^Count ten group \d+$')),
          findsNWidgets(lesson.tens));
      expect(find.bySemanticsLabel(RegExp(r'^Count star \d+$')),
          findsNWidgets(lesson.ones));
      if (lesson.ones > 0) {
        final before = speaker.spoken.length;
        await tap(tester, find.bySemanticsLabel('Count star 1'));
        expect(speaker.spoken.length, before);
        expect(find.text(CountingNarration.howMany), findsNothing);
      }
      await tap(tester, find.bySemanticsLabel('Count ten group 1'));
      final before = speaker.spoken.length;
      await tap(tester, find.bySemanticsLabel('Count ten group 1'));
      expect(speaker.spoken.length, before);
      for (var index = 2; index <= lesson.tens; index++) {
        await tap(tester, find.bySemanticsLabel('Count ten group $index'));
      }
      for (var index = 1; index <= lesson.ones; index++) {
        await tap(tester, find.bySemanticsLabel('Count star $index'));
      }
      final counts = [
        for (var ten = 1; ten <= lesson.tens; ten++)
          CountingNarration.number(ten * 10),
        for (var one = 1; one <= lesson.ones; one++)
          CountingNarration.number(lesson.tens * 10 + one),
      ];
      final countStart =
          speaker.spoken.indexOf(CountingNarration.countTens) + 1;
      expect(speaker.spoken.skip(countStart).take(counts.length), counts);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      final wrong = lesson.totalChoices.firstWhere((item) => item != number);
      await tap(tester, find.widgetWithText(OutlinedButton, '$wrong'));
      expect(find.text(CountingNarration.tryTotal), findsOneWidget);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      await countGrouped(tester, lesson);
      await tap(tester, find.widgetWithText(OutlinedButton, '$number'));
      await tap(tester, continueButton);
      expect(find.text('Build $number'), findsOneWidget);
      expect(speaker.spoken.last, CountingNarration.number(number));
      final finish = find.widgetWithText(FilledButton,
          number == 100 ? 'Finish counting' : 'Let\'s learn ${number + 1}!');
      expect(tester.widget<FilledButton>(finish).onPressed, isNull);
      await tap(tester, find.text('Check my number'));
      expect(find.text(CountingNarration.tryBuild), findsOneWidget);
      for (var index = 0; index < lesson.tens; index++) {
        await tap(tester, find.text('Add ten'));
      }
      for (var index = 0; index <= lesson.ones; index++) {
        await tap(tester, find.text('Add one'));
      }
      // One extra remains a wrong answer, even at the 100 boundary.
      await tap(tester, find.text('Check my number'));
      expect(find.text(CountingNarration.tryBuild), findsOneWidget);
      expect(tester.widget<FilledButton>(finish).onPressed, isNull);
      await tap(tester, find.text('Remove one'));
      await tap(tester, find.text('Check my number'));
      expect(find.text(CountingNarration.correctBuild), findsOneWidget);
      expect(tester.widget<FilledButton>(finish).onPressed, isNotNull);
      expect(evidence, isEmpty);
      await tap(tester, finish);
      expect(find.text('You practiced $number!'), findsOneWidget);
      expect(
          evidence.where((item) => item.skill == CountingSkill.countingObjects),
          isEmpty);
      expect(
          evidence.where((item) =>
              item.skill == CountingSkill.tensAndOnes && item.correct),
          isNotEmpty);
      expect(
          evidence
              .where((item) => item.skill == CountingSkill.makingQuantity)
              .map((item) => item.correct),
          [false, false, true]);
      if (number < 100) {
        await tap(tester, find.text('Next number: ${number + 1}'));
        expect(find.text('Meet number ${number + 1}'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
      'Ten ones can be traded, and wrong decompositions are not accepted',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CountingLessonScreen(
        lesson: countingLessons[19],
        speaker: CountingSpeaker(),
        onCompleted: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();
    await tap(tester, continueButton);
    await countGrouped(tester, countingLessons[19]);
    await tap(tester, find.widgetWithText(OutlinedButton, '20'));
    await tap(tester, continueButton);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Remove ten'))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Remove one'))
            .onPressed,
        isNull);
    await tap(tester, find.text('Add ten'));
    for (var index = 0; index < 10; index++) {
      await tap(tester, find.text('Add one'));
    }
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Add one'))
            .onPressed,
        isNull);
    expect(find.text('20 stars in your group'), findsOneWidget);
    await tap(tester, find.text('Check my number'));
    expect(find.text(CountingNarration.tryBuild), findsOneWidget);
    await tap(tester, find.text('Trade 10 ones for a ten'));
    expect(find.text('2 tens + 0 ones'), findsOneWidget);
    expect(find.text('20 stars in your group'), findsOneWidget);
    await tap(tester, find.text('Check my number'));
    expect(find.text(CountingNarration.correctBuild), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Let\'s learn 21!'))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Every range exposes exactly ten selectable numbers',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CountingPathwayScreen(speaker: CountingSpeaker()),
    ));
    await tester.pumpAndSettle();
    for (var start = 1; start <= 91; start += 10) {
      if (start > 1) await selectRange(tester, start);
      expect(find.bySemanticsLabel(RegExp(r'^Open number \d+$')),
          findsNWidgets(10));
      for (var number = start; number < start + 10; number++) {
        expect(find.bySemanticsLabel('Open number $number'), findsOneWidget);
      }
      await tap(tester, find.bySemanticsLabel('Open number ${start + 9}'));
      expect(find.text('Meet number ${start + 9}'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.text('0 of 100 numbers explored'), -200);
      expect(find.text('0 of 100 numbers explored'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Math and Counting open the same 1-100 journey', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LearningDashboard(
        profile: ChildProfile(nickname: 'Alex', ageBand: AgeBand.fourToFive),
        onSettings: () {},
        onRefresh: () {},
      ),
    ));
    await tester.pumpAndSettle();
    await tap(tester, find.byIcon(Icons.numbers_rounded));
    expect(find.byType(CountingPathwayScreen), findsOneWidget);
    expect(find.text('0 of 100 numbers explored'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('coming later.'), 200);
    expect(find.textContaining('coming later.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, find.text('Counting'));
    expect(find.byType(CountingPathwayScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Open number 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Open number 10'), findsOneWidget);
    expect(find.bySemanticsLabel('Open number 11'), findsNothing);
  });

  testWidgets('Completed numbers update journey; jumps and early exit do not',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CountingPathwayScreen(speaker: CountingSpeaker()),
    ));
    await tester.pumpAndSettle();
    await tap(tester, find.bySemanticsLabel('Open number 1'));
    await tap(tester, find.byTooltip('Next number'));
    expect(find.text('Meet number 2'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('0 of 100 numbers explored'), -200);
    expect(find.text('0 of 100 numbers explored'), findsOneWidget);
    await tap(tester, find.bySemanticsLabel('Open number 1'));
    await tap(tester, continueButton);
    await countAll(tester, 1);
    await tap(tester, find.widgetWithText(OutlinedButton, '1'));
    await tap(tester, continueButton);
    await makeGroup(tester, 1);
    await tap(tester, find.text('Let\'s learn 2!'));
    await tap(tester, find.text('Next number: 2'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('1 of 100 numbers explored'), -200);
    expect(find.text('1 of 100 numbers explored'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('For grown-ups: session practice'), 250);
    await tap(tester, find.text('For grown-ups: session practice'));
    await tester.scrollUntilVisible(
        find.text('Understanding tens and ones'), 300);
    expect(find.text('Understanding tens and ones'), findsOneWidget);
    expect(find.text('Not assessed'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Finishing 100 returns to the number journey', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CountingPathwayScreen(speaker: CountingSpeaker()),
    ));
    await tester.pumpAndSettle();
    await selectRange(tester, 91);
    await tap(tester, find.bySemanticsLabel('Open number 100'));
    expect(
        tester
            .widget<IconButton>(find.ancestor(
              of: find.byTooltip('Next number'),
              matching: find.byType(IconButton),
            ))
            .onPressed,
        isNull);
    await tap(tester, continueButton);
    await countGrouped(tester, countingLessons.last);
    await tap(tester, find.widgetWithText(OutlinedButton, '100'));
    await tap(tester, continueButton);
    await buildNumber(tester, countingLessons.last);
    await tap(tester, find.text('Finish counting'));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tap(
        tester, find.widgetWithText(FilledButton, 'Finish counting').last);
    expect(find.byType(CountingLessonScreen), findsNothing);
    await tester.scrollUntilVisible(
        find.text('1 of 100 numbers explored'), -200);
    expect(find.text('1 of 100 numbers explored'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Audio errors show retry and backgrounding stops counting speech',
      (tester) async {
    final speaker = CountingSpeaker()..fail = true;
    await tester.pumpWidget(MaterialApp(
      home: CountingLessonScreen(
        lesson: countingLessons.first,
        speaker: speaker,
        onCompleted: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<StateError>());
    expect(find.textContaining('The counting voice could not play'),
        findsOneWidget);
    speaker.fail = false;
    await tap(tester, find.text('Retry voice'));
    expect(speaker.spoken.last, CountingNarration.meet(countingLessons.first));
    expect(
        find.textContaining('The counting voice could not play'), findsNothing);
    final before = speaker.stops;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(speaker.stops, greaterThan(before));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(speaker.stops, greaterThan(before + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spoken counts finish before the next star can be counted',
      (tester) async {
    final speaker = CountingSpeaker();
    await tester.pumpWidget(MaterialApp(
      home: CountingLessonScreen(
        lesson: countingLessons[1],
        speaker: speaker,
        onCompleted: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();
    await tap(tester, continueButton);
    speaker.hold = true;
    await tester.ensureVisible(find.bySemanticsLabel('Count star 1'));
    await tester.tap(find.bySemanticsLabel('Count star 1'));
    await tester.pumpAndSettle();
    final before = speaker.spoken.length;
    await tester.tap(find.bySemanticsLabel('Count star 2'));
    await tester.pumpAndSettle();
    expect(speaker.spoken.length, before);
    expect(find.text(CountingNarration.howMany), findsNothing);
    speaker.hold = false;
    await speaker.stop();
    await tester.pumpAndSettle();
    await tap(tester, find.bySemanticsLabel('Count star 2'));
    expect(speaker.spoken.skip(before), [
      'two.',
      CountingNarration.total(countingLessons[1]),
      CountingNarration.howMany
    ]);
    expect(tester.takeException(), isNull);
  });

  for (final number in [5, 99, 100]) {
    testWidgets(
        'Number $number fits small screens with large text and reduced motion',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
              textScaler: TextScaler.linear(2), disableAnimations: true),
          child: CountingLessonScreen(
            lesson: countingLessons[number - 1],
            speaker: CountingSpeaker(),
            onCompleted: (_, __) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tap(tester, continueButton);
      if (number <= 10) {
        await countAll(tester, number);
      } else {
        await countGrouped(tester, countingLessons[number - 1]);
      }
      await tap(tester, find.widgetWithText(OutlinedButton, '$number'));
      await tap(tester, continueButton);
      if (number <= 10) {
        await makeGroup(tester, number);
      } else {
        await buildNumber(tester, countingLessons[number - 1]);
      }
      await tap(
          tester,
          find.text(number == 100
              ? 'Finish counting'
              : 'Let\'s learn ${number + 1}!'));
      expect(find.byType(AlertDialog), findsOneWidget);
      final replay = find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Hear again'));
      await Scrollable.ensureVisible(tester.element(replay), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(replay.hitTestable(), findsOneWidget);
      await tester.tap(replay);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
