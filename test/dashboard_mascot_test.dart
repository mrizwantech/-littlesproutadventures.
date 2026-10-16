import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_learners/features/profile/presentation/dashboard_mascot.dart';

void main() {
  Widget app({bool reduceMotion = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const Scaffold(body: DashboardMascot()),
        ),
      );

  testWidgets('Mascot moves briefly and returns to rest', (tester) async {
    await tester.pumpWidget(app());
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, const AssetImage('assets/characters/wave.png'));
    expect(image.semanticLabel, contains('waving hello'));
    await tester.pump(const Duration(milliseconds: 300));
    final moving =
        tester.widget<Transform>(find.byKey(const ValueKey('mascot-tilt')));
    expect(moving.transform.entry(0, 1), isNot(0));
    await tester.pumpAndSettle();
    final resting =
        tester.widget<Transform>(find.byKey(const ValueKey('mascot-tilt')));
    expect(resting.transform.entry(0, 1), closeTo(0, 0.000001));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Reduce Motion keeps the mascot still', (tester) async {
    await tester.pumpWidget(app(reduceMotion: true));
    await tester.pump();
    final resting =
        tester.widget<Transform>(find.byKey(const ValueKey('mascot-tilt')));
    expect(resting.transform.entry(0, 1), closeTo(0, 0.000001));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
