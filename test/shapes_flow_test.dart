import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_learners/core/theme/app_theme.dart';
import 'package:little_learners/features/listening/data/prompt_speaker.dart';
import 'package:little_learners/features/profile/domain/child_profile.dart';
import 'package:little_learners/features/profile/presentation/learning_dashboard.dart';
import 'package:little_learners/features/reading/data/bundled_reading_prompt_speaker.dart';
import 'package:little_learners/features/reading/domain/reading_narration.dart';
import 'package:little_learners/features/shapes/domain/shapes_curriculum.dart';
import 'package:little_learners/features/shapes/presentation/shape_picture.dart';
import 'package:little_learners/features/shapes/presentation/shapes_lesson_screen.dart';
import 'package:little_learners/features/shapes/presentation/shapes_pathway_screen.dart';

class ShapeSpeaker implements PromptSpeaker {
  final spoken = <String>[];
  bool fail = false;
  int stops = 0;

  @override
  Future<void> speak(String text) async {
    expect({...ShapesNarration.all.values, ...ReadingNarration.all.values},
        contains(text));
    if (fail) throw StateError('Voice unavailable');
    spoken.add(text);
  }

  @override
  Future<void> stop() async => stops++;
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 150);
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder choice(ShapeKind shape, int index) =>
    find.bySemanticsLabel('${shape.label}, choice $index');
Finder get next => find.widgetWithText(FilledButton, 'Continue');

List<ShapeKind> choices(ShapeKind target, int variation, int step) {
  final other = ShapeKind.values[(target.index + 1 + variation % 2) % 3];
  final items = step == 1 ? [target, other] : [target, other, target];
  final shift = (variation + target.index) % items.length;
  return [...items.skip(shift), ...items.take(shift)];
}

Future<void> complete(WidgetTester tester, ShapeKind shape,
    {int variation = 0}) async {
  await tap(tester, next);
  final recognition = choices(shape, variation, 1);
  final targetIndex = recognition.indexOf(shape);
  await tap(tester, choice(shape, targetIndex + 1));
  await tap(tester, next);
  final matching = choices(shape, variation, 2);
  for (var i = 0; i < matching.length; i++) {
    if (matching[i] == shape) await tap(tester, choice(shape, i + 1));
  }
  await tap(tester, find.text('Check my matches'));
  await tap(tester, find.text('Finish shape'));
}

void main() {
  test('All shape prompts have nonempty offline recordings', () {
    final manifest = BundledReadingPromptSpeaker.parseManifest(
        File(BundledReadingPromptSpeaker.manifestPath).readAsStringSync());
    for (final text in ShapesNarration.all.values) {
      expect(manifest, contains(text));
      expect(
          File('${BundledReadingPromptSpeaker.audioDirectory}/${manifest[text]}')
              .lengthSync(),
          greaterThan(1000));
    }
  });

  for (final shape in ShapeKind.values) {
    testWidgets('${shape.label}: meet, recognize, match, celebrate and replay',
        (tester) async {
      final speaker = ShapeSpeaker();
      final evidence = <ShapeEvidence>[];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: ShapesLessonScreen(
          shape: shape,
          speaker: speaker,
          onCompleted: evidence.addAll,
        ),
      ));
      await tester.pumpAndSettle();
      expect(speaker.spoken, contains(ShapesNarration.meet(shape)));
      await tap(tester, find.text('Explore the outline'));
      expect(evidence, isEmpty);
      await complete(tester, shape);
      expect(find.byType(AlertDialog), findsOneWidget);
      final cheer = speaker.spoken.last;
      final count = speaker.spoken.length;
      await tap(
          tester,
          find.descendant(
              of: find.byType(AlertDialog), matching: find.text('Hear again')));
      expect(speaker.spoken.length, count + 1);
      expect(speaker.spoken.last, cheer);
      await tap(tester, find.text('Back to shapes'));
      expect(evidence.map((e) => e.skill),
          [ShapeSkill.recognizing, ShapeSkill.matching]);
      expect(evidence.every((e) => e.correct && !e.assisted), isTrue);
      expect(evidence.where((e) => e.skill == ShapeSkill.describing), isEmpty);
    });
  }

  testWidgets('Wrong answers and extra matches require a retry',
      (tester) async {
    final evidence = <ShapeEvidence>[];
    await tester.pumpWidget(MaterialApp(
      home: ShapesLessonScreen(
        shape: ShapeKind.circle,
        speaker: ShapeSpeaker(),
        onCompleted: evidence.addAll,
      ),
    ));
    await tester.pumpAndSettle();
    await tap(tester, next);
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tap(tester, choice(ShapeKind.square, 2));
    expect(find.text(ShapesNarration.retry), findsOneWidget);
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tap(tester, choice(ShapeKind.circle, 1));
    await tap(tester, next);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Check my matches'))
            .onPressed,
        isNull);
    await tap(tester, choice(ShapeKind.circle, 1));
    await tap(tester, find.text('Check my matches'));
    expect(find.text(ShapesNarration.retry), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tap(
          tester, choice(i == 1 ? ShapeKind.square : ShapeKind.circle, i + 1));
    }
    await tap(tester, find.text('Check my matches'));
    expect(find.text(ShapesNarration.retry), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Finish shape'))
            .onPressed,
        isNull);
    await tap(tester, choice(ShapeKind.circle, 1));
    await tap(tester, choice(ShapeKind.circle, 3));
    await tap(tester, find.text('Check my matches'));
    await tap(tester, find.text('Finish shape'));
    await tap(tester, find.text('Back to shapes'));
    expect(evidence.map((e) => e.correct), [false, true, false, false, true]);
    expect(evidence.where((e) => e.correct).every((e) => e.assisted), isTrue);
  });

  testWidgets('Revisits vary size, color and position, with rotated shapes',
      (tester) async {
    final firstColors = <Color>[];
    final firstPositions = <int>[];
    for (var variation = 0; variation < 3; variation++) {
      await tester.pumpWidget(MaterialApp(
        key: ValueKey(variation),
        home: ShapesLessonScreen(
          shape: ShapeKind.square,
          variation: variation,
          speaker: ShapeSpeaker(),
          onCompleted: (_) {},
        ),
      ));
      await tester.pumpAndSettle();
      await tap(tester, next);
      final rendered =
          tester.widgetList<ShapePicture>(find.byType(ShapePicture)).toList();
      firstColors.add(rendered.first.color);
      firstPositions
          .add(rendered.indexWhere((p) => p.shape == ShapeKind.square));
      await tap(tester, choice(ShapeKind.square, firstPositions.last + 1));
      await tap(tester, next);
      final matches = tester
          .widgetList<ShapePicture>(find.byType(ShapePicture))
          .where((p) => p.shape == ShapeKind.square);
      expect(matches.map((p) => p.size).toSet(), hasLength(2));
      expect(matches.map((p) => p.color).toSet(), hasLength(2));
      if (variation.isEven) expect(matches.any((p) => p.rotation != 0), isTrue);
    }
    expect(firstColors.toSet().length, greaterThan(1));
    expect(firstPositions.toSet().length, greaterThan(1));
  });

  testWidgets(
      'Early exit does not complete a lesson; completion updates garden',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ShapesPathwayScreen(speaker: ShapeSpeaker()),
    ));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Meet the circle'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('0 of 3 shapes explored'), findsOneWidget);
    await tap(tester, find.text('Meet the circle'));
    await complete(tester, ShapeKind.circle, variation: 1);
    await tap(tester, find.text('Back to shapes'));
    await tester.scrollUntilVisible(find.text('1 of 3 shapes explored'), -200);
    expect(find.text('1 of 3 shapes explored'), findsOneWidget);
    await tap(tester, find.text('For grown-ups: session practice'));
    await tester.scrollUntilVisible(find.text('Describing shapes'), 200);
    expect(find.text('Not assessed'), findsOneWidget);
  });

  testWidgets('Audio failure is visible and retry and background stop work',
      (tester) async {
    final speaker = ShapeSpeaker()..fail = true;
    await tester.pumpWidget(MaterialApp(
      home: ShapesLessonScreen(
          shape: ShapeKind.triangle, speaker: speaker, onCompleted: (_) {}),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isStateError);
    expect(find.text('The shape voice could not play. Tap Retry voice.'),
        findsOneWidget);
    speaker.fail = false;
    await tap(tester, find.text('Retry voice'));
    expect(speaker.spoken.last, ShapesNarration.meet(ShapeKind.triangle));
    final stops = speaker.stops;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(speaker.stops, greaterThan(stops));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Dashboard Shapes opens the shape garden', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LearningDashboard(
        profile: ChildProfile(nickname: 'Sam', ageBand: AgeBand.fourToFive),
        onSettings: () {},
        onRefresh: () {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Shapes'), 200);
    await tap(tester, find.text('Shapes'));
    expect(find.byType(ShapesPathwayScreen), findsOneWidget);
  });

  for (final shape in ShapeKind.values) {
    testWidgets('${shape.label} works on small screens with 2x text',
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
          child: ShapesLessonScreen(
              shape: shape, speaker: ShapeSpeaker(), onCompleted: (_) {}),
        ),
      ));
      await tester.pumpAndSettle();
      await complete(tester, shape);
      await tap(
          tester,
          find.descendant(
              of: find.byType(AlertDialog), matching: find.text('Hear again')));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
