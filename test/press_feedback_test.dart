import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_learners/core/theme/app_theme.dart';
import 'package:little_learners/core/widgets/press_feedback.dart';

void main() {
  for (final reducedMotion in [false, true]) {
    testWidgets(
        'Buttons and cards react immediately and reset (reduced motion: $reducedMotion)',
        (tester) async {
      var taps = 0;
      void tap() => taps++;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: Scaffold(
            body: Column(
              children: [
                FilledButton(onPressed: tap, child: const Text('Filled')),
                OutlinedButton(onPressed: tap, child: const Text('Outlined')),
                TextButton(onPressed: tap, child: const Text('Text')),
                ElevatedButton(onPressed: tap, child: const Text('Elevated')),
                IconButton(onPressed: tap, icon: const Icon(Icons.play_arrow)),
                Material(
                  child: PressableInkWell(
                    onTap: tap,
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Lesson card'),
                    ),
                  ),
                ),
                const FilledButton(onPressed: null, child: Text('Disabled')),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final controls = [
        find.widgetWithText(FilledButton, 'Filled'),
        find.byType(OutlinedButton),
        find.byType(TextButton),
        find.byType(ElevatedButton),
        find.byType(IconButton),
        find.byType(PressableInkWell),
      ];
      for (final control in controls) {
        final scale =
            find.descendant(of: control, matching: find.byType(AnimatedScale));
        expect(tester.widget<AnimatedScale>(scale).scale, 1);
        final press = await tester.startGesture(tester.getCenter(control));
        await tester.pump();
        expect(tester.widget<AnimatedScale>(scale).scale, 0.94);
        if (reducedMotion) {
          expect(tester.widget<AnimatedScale>(scale).duration, Duration.zero);
        }
        await tester.pump(const Duration(milliseconds: 80));
        final transform =
            find.descendant(of: scale, matching: find.byType(Transform));
        expect(tester.widget<Transform>(transform.first).transform.entry(0, 0),
            closeTo(0.94, 0.001));
        await press.cancel();
        await tester.pumpAndSettle();
        expect(tester.widget<AnimatedScale>(scale).scale, 1);
      }
      expect(taps, 0);
      for (final control in controls) {
        await tester.tap(control);
        await tester.pumpAndSettle();
      }
      expect(taps, controls.length);
      final disabled = find.widgetWithText(FilledButton, 'Disabled');
      final disabledPress =
          await tester.startGesture(tester.getCenter(disabled));
      await tester.pump();
      final scale =
          find.descendant(of: disabled, matching: find.byType(AnimatedScale));
      expect(tester.widget<AnimatedScale>(scale).scale, 1);
      await disabledPress.up();
      await tester.pumpAndSettle();
      expect(taps, controls.length);
      expect(tester.takeException(), isNull);
    });
  }
}
