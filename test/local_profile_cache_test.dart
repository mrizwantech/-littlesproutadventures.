import 'package:flutter_test/flutter_test.dart';
import 'package:little_learners/features/profile/data/local_profile_cache.dart';
import 'package:little_learners/features/profile/domain/child_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
  });

  test(
      'Saved nickname and age survive cache recreation and stay account scoped',
      () async {
    final cache = LocalProfileCache();
    await cache.save('parent-a',
        ChildProfile(nickname: 'Alex', ageBand: AgeBand.fourToFive));
    await cache.save(
        'parent-b', ChildProfile(nickname: 'Sam', ageBand: AgeBand.twoToThree));
    final recreated = LocalProfileCache();
    final a = (await recreated.load('parent-a'))!;
    expect(a.nickname, 'Alex');
    expect(a.ageBand, AgeBand.fourToFive);
    expect((await recreated.load('parent-b'))!.nickname, 'Sam');
    expect(await recreated.load('unknown-parent'), isNull);
    await recreated.clear('parent-a');
    expect(await recreated.load('parent-a'), isNull);
    expect((await recreated.load('parent-b'))!.nickname, 'Sam');
    final fields = await SharedPreferencesAsync().getAll();
    expect(fields.keys, ['child_profile_v1_parent-b']);
    expect(fields.values.single, '{"nickname":"Sam","ageBand":"2-3"}');
  });

  test('Malformed cached values fail explicitly rather than resetting profile',
      () async {
    final preferences = SharedPreferencesAsync();
    final cache = LocalProfileCache(preferences: preferences);
    for (final data in [
      'invalid-json',
      '[]',
      '{"nickname":"Alex","ageBand":"8-9"}',
      '{"nickname":3,"ageBand":"2-3"}',
      '{"nickname":"Alex","ageBand":"2-3","avatar":"invalid"}',
      '{"nickname":"Alex","ageBand":"2-3","avatar":null}',
    ]) {
      await preferences.setString('child_profile_v1_parent-a', data);
      await expectLater(cache.load('parent-a'), throwsFormatException);
    }
  });

  test('Avatar survives cache recreation and legacy profiles remain readable',
      () async {
    final cache = LocalProfileCache();
    for (final avatar in ChildAvatar.values) {
      await cache.save(
          'parent-a',
          ChildProfile(
              nickname: 'Alex', ageBand: AgeBand.fourToFive, avatar: avatar));
      expect((await LocalProfileCache().load('parent-a'))!.avatar, avatar);
    }
    expect(
        LocalProfileCache.decode({'nickname': 'Alex', 'ageBand': '2-3'}).avatar,
        isNull);
  });
}
