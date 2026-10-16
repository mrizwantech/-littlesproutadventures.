import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_learners/app/little_learners_app.dart';
import 'package:little_learners/core/widgets/app_title.dart';
import 'package:little_learners/features/splash/presentation/splash_screen.dart';
import 'package:little_learners/features/welcome/presentation/welcome_screen.dart';

void main() {
  testWidgets('Splash title fits tall phones independently of background crop',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: SplashScreen(),
      ),
    ));
    await tester.pump();
    final title = tester.getRect(find.byType(AppTitle));
    expect(title.left, greaterThanOrEqualTo(24));
    expect(title.right, lessThanOrEqualTo(393 - 24));
    expect(find.bySemanticsLabel('Little Sprout Adventures'), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).image,
        const AssetImage('assets/images/little_learners_meadow.png'));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Future<void> cacheSplash(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.runAsync(() => precacheImage(
          const AssetImage(SplashScreen.assetPath),
          tester.element(find.byType(SizedBox).first),
        ));
  }

  testWidgets('Splash fills edge to edge and stays for at least two seconds',
      (tester) async {
    await cacheSplash(tester);
    await tester.pumpWidget(const LittleLearnersApp());
    await tester.pump();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
    expect(image.alignment, Alignment.center);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Waits for preparation before showing welcome', (tester) async {
    await cacheSplash(tester);
    final preparation = Completer<void>();
    await tester
        .pumpWidget(LittleLearnersApp(prepare: () => preparation.future));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        isNull);
    expect(find.byType(WelcomeScreen), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(SplashScreen), findsOneWidget);

    preparation.complete();
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
    expect(find.text('Already have an account?'), findsNothing);
  });

  testWidgets('Preparation failure is reported and can be retried',
      (tester) async {
    await cacheSplash(tester);
    var attempts = 0;
    await tester.pumpWidget(LittleLearnersApp(prepare: () async {
      attempts++;
      if (attempts == 1) throw StateError('Preparation failed');
    }));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isA<StateError>());
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(
        find.text('Unable to prepare the app. Please retry.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('Welcome screen can render without app composition',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Meadow welcome overlays a title and reachable phone controls',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: WelcomeScreen(onGetStarted: () {}),
    ));
    await tester.pumpAndSettle();

    final background = tester.widget<Image>(find.byType(Image));
    expect(background.image, const AssetImage(WelcomeScreen.assetPath));
    expect(background.fit, BoxFit.cover);
    expect(find.bySemanticsLabel('Little Sprout Adventures'), findsOneWidget);
    expect(find.text('Play  •  Learn  •  Grow'), findsOneWidget);
    expect(find.text('Get Started').hitTestable(), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Welcome controls remain usable on small screens with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var starts = 0;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: WelcomeScreen(
          onGetStarted: () => starts++,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    expect(starts, 1);
    expect(tester.takeException(), isNull);
  });
}
