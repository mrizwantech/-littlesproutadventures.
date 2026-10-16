import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_learners/features/auth/domain/auth_repository.dart';
import 'package:little_learners/features/auth/presentation/auth_gate.dart';
import 'package:little_learners/features/auth/presentation/sign_in_screen.dart';
import 'package:little_learners/features/profile/domain/child_profile.dart';
import 'package:little_learners/features/profile/domain/profile_repository.dart';
import 'package:little_learners/features/profile/presentation/profile_screen.dart';

class MemoryAuth implements AuthRepository {
  MemoryAuth(this.currentParentId);
  final changes = StreamController<String?>.broadcast();
  @override
  String? currentParentId;
  @override
  Stream<String?> get parentChanges => changes.stream;
  void change(String? id) {
    currentParentId = id;
    changes.add(id);
  }

  @override
  Future<void> initialize() async {}
  @override
  Future<void> signInWithGoogle() async => change('parent-a');
  @override
  Future<void> signInWithApple() async => change('parent-b');
  @override
  Future<void> signOut() async => change(null);
}

class MemoryProfiles implements ProfileRepository {
  final values = <String, ChildProfile>{};
  final cleared = <String>[];
  bool offline = false;
  bool failLoad = false;
  bool failSave = false;
  bool accessDenied = false;
  @override
  Future<LoadedProfile> load(String parentId) async {
    if (accessDenied) throw const ProfileAccessDenied();
    if (failLoad) throw StateError('Load denied');
    return LoadedProfile(values[parentId], isOffline: offline);
  }

  @override
  Future<void> save(String parentId, ChildProfile profile) async {
    if (accessDenied) throw const ProfileAccessDenied();
    if (failSave) throw StateError('Save denied');
    values[parentId] = profile;
  }

  @override
  Future<void> clearLocal(String parentId) async => cleared.add(parentId);
}

void main() {
  testWidgets('Dashboard supports large text, coming soon, and avatar settings',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final profiles = MemoryProfiles()
      ..values['parent-a'] = ChildProfile(
          nickname: 'Alex',
          ageBand: AgeBand.fourToFive,
          avatar: ChildAvatar.girl);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: ProfileScreen(
            parentId: 'parent-a', repository: profiles, signOut: () async {}),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Alex!'), findsOneWidget);
    expect(find.text('👧'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.star_rounded));
    await tester.tap(find.byIcon(Icons.star_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Little steps toward reading'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.numbers_rounded));
    await tester.tap(find.byIcon(Icons.numbers_rounded));
    await tester.pump();
    expect(find.text('Math is coming soon.'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Edit child profile'));
    await tester.tap(find.byTooltip('Edit child profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Boy'));
    await tester.tap(find.text('Boy'));
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('👧'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit child profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Boy'));
    await tester.tap(find.text('Boy'));
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('👦'), findsOneWidget);
    expect(profiles.values['parent-a']!.avatar, ChildAvatar.boy);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Nickname tap opens text input and accepts typing after reopening',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final profiles = MemoryProfiles();
    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(
        parentId: 'parent-a',
        repository: profiles,
        signOut: () async {},
      ),
    ));
    await tester.pumpAndSettle();

    final background = tester.widget<Image>(find.byType(Image));
    expect(background.image,
        const AssetImage('assets/images/little_learners_meadow.png'));
    expect(background.fit, BoxFit.cover);
    expect(background.excludeFromSemantics, isTrue);
    final nickname = find.byType(TextFormField);
    await tester.tap(nickname);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    tester.testTextInput.enterText('Alex');
    await tester.pump();
    expect(find.text('Alex'), findsOneWidget);
    await tester.ensureVisible(find.text('Boy'));
    await tester.tap(find.text('Boy'));

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.ensureVisible(nickname);
    await tester.tap(nickname);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(nickname).dy, lessThan(844 - 336));
    await tester.ensureVisible(find.text('4-5 years'));
    await tester.tap(find.text('4-5 years'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(profiles.values['parent-a']!.nickname, 'Alex');
    expect(profiles.values['parent-a']!.ageBand, AgeBand.fourToFive);
    expect(profiles.values['parent-a']!.avatar, ChildAvatar.boy);
    expect(find.text('Hello, Alex!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Animal cards restore selection and save a changed age with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final profiles = MemoryProfiles()
      ..values['parent-a'] = ChildProfile(
          nickname: 'Alex',
          ageBand: AgeBand.twoToThree,
          avatar: ChildAvatar.girl);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: ProfileScreen(
          parentId: 'parent-a',
          repository: profiles,
          signOut: () async {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit child profile'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(TextFormField)).dy,
      lessThan(tester.getTopLeft(find.text('2-3 years')).dy),
    );
    await tester.ensureVisible(find.text('6-7 years'));
    await tester.tap(find.text('6-7 years'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(profiles.values['parent-a']!.ageBand, AgeBand.sixToSeven);
    expect(find.text('Hello, Alex!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sign-in shows meadow and provider icons with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = MemoryAuth(null);
    addTearDown(auth.changes.close);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: SignInScreen(auth: auth),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.apple), findsOneWidget);
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(
        images.map((image) => image.image),
        containsAll([
          const AssetImage('assets/images/little_learners_meadow.png'),
          const AssetImage('assets/images/google_logo.png'),
        ]));
    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(auth.currentParentId, 'parent-a');
    await tester.ensureVisible(find.text('Sign in with Apple'));
    await tester.tap(find.text('Sign in with Apple'));
    await tester.pumpAndSettle();
    expect(auth.currentParentId, 'parent-b');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Get Started opens parent sign-in and supports going back',
      (tester) async {
    final auth = MemoryAuth(null);
    addTearDown(auth.changes.close);
    await tester.pumpWidget(
      MaterialApp(home: AuthGate(auth: auth, profiles: MemoryProfiles())),
    );
    await tester.pumpAndSettle();
    for (final label in ['Get Started']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('Parent sign-in'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Get Started'), findsOneWidget);
    }
  });

  test('Child profiles trim nicknames and reject invalid lengths', () {
    final profile = ChildProfile(
      nickname: '  Alex  ',
      ageBand: AgeBand.fourToFive,
    );
    expect(profile.nickname, 'Alex');
    expect(AgeBand.values.map((band) => band.id), ['2-3', '4-5', '6-7']);
    expect(() => ChildProfile(nickname: ' ', ageBand: AgeBand.twoToThree),
        throwsArgumentError);
    expect(() => ChildProfile(nickname: 'a' * 41, ageBand: AgeBand.twoToThree),
        throwsArgumentError);
  });

  testWidgets('Parent signs in, creates, edits, and reloads a child profile',
      (tester) async {
    final auth = MemoryAuth(null);
    final profiles = MemoryProfiles();
    addTearDown(auth.changes.close);
    Widget app() => MaterialApp(home: AuthGate(auth: auth, profiles: profiles));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Parent sign-in'), findsOneWidget);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Select an age band.'), findsOneWidget);
    expect(
        find.text('Choose Girl or Boy for the profile icon.'), findsOneWidget);
    expect(
        find.text('Enter a nickname with 1 to 40 characters.'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), '  Alex  ');
    await tester.ensureVisible(find.text('Girl'));
    await tester.tap(find.text('Girl'));
    await tester.ensureVisible(find.text('4-5 years'));
    await tester.tap(find.text('4-5 years'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(profiles.values['parent-a']!.nickname, 'Alex');
    expect(profiles.values['parent-a']!.ageBand, AgeBand.fourToFive);
    expect(find.text('Hello, Alex!'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit child profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Sam');
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Sam!'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Sam!'), findsOneWidget);
    expect(find.text('Parent sign-in'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('Sign-out clears local profile and account switches isolate data',
      (tester) async {
    final auth = MemoryAuth('parent-a');
    final profiles = MemoryProfiles()
      ..values['parent-a'] =
          ChildProfile(nickname: 'Alex', ageBand: AgeBand.twoToThree);
    addTearDown(auth.changes.close);
    await tester.pumpWidget(
      MaterialApp(home: AuthGate(auth: auth, profiles: profiles)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsNothing);
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Alex!'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit child profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(profiles.cleared, ['parent-a']);
    expect(find.text('Hello, Alex!'), findsNothing);
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Parent sign-in'), findsOneWidget);
    await tester.tap(find.text('Sign in with Apple'));
    await tester.pumpAndSettle();
    expect(find.text('Your child\'s profile'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        isEmpty);
  });

  testWidgets('Offline profile is labeled; failed save retains form for retry',
      (tester) async {
    final profiles = MemoryProfiles()
      ..offline = true
      ..failSave = true
      ..values['parent-a'] = ChildProfile(
          nickname: 'Alex',
          ageBand: AgeBand.sixToSeven,
          avatar: ChildAvatar.boy);
    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(
        parentId: 'parent-a',
        repository: profiles,
        signOut: () async {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline:'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit child profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Sam');
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<StateError>());
    expect(find.textContaining('Save could not be confirmed'), findsOneWidget);
    expect(profiles.values['parent-a']!.nickname, 'Alex');
    profiles.failSave = false;
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Sam!'), findsOneWidget);
    expect(find.textContaining('Offline:'), findsNothing);
  });

  testWidgets('Load errors do not masquerade as a missing profile',
      (tester) async {
    final profiles = MemoryProfiles()..failLoad = true;
    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(
        parentId: 'parent-a',
        repository: profiles,
        signOut: () async {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<StateError>());
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    profiles.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('Denied reads explain Firestore rules and recover after Retry',
      (tester) async {
    final profiles = MemoryProfiles()..accessDenied = true;
    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(
        parentId: 'parent-a',
        repository: profiles,
        signOut: () async {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<ProfileAccessDenied>());
    expect(find.text(ProfileAccessDenied.message), findsOneWidget);
    expect(find.textContaining('Connect to the internet'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    profiles.accessDenied = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('Denied saves identify rules rather than a network failure',
      (tester) async {
    final profiles = MemoryProfiles()
      ..values['parent-a'] = ChildProfile(
          nickname: 'Alex',
          ageBand: AgeBand.twoToThree,
          avatar: ChildAvatar.girl);
    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(
        parentId: 'parent-a',
        repository: profiles,
        signOut: () async {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit child profile'));
    await tester.pumpAndSettle();
    profiles.accessDenied = true;
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<ProfileAccessDenied>());
    expect(find.text(ProfileAccessDenied.message), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
