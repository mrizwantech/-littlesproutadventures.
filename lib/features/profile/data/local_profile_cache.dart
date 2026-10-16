import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/child_profile.dart';

class LocalProfileCache {
  LocalProfileCache({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  String _key(String parentId) => 'child_profile_v1_$parentId';

  static Map<String, dynamic> encode(ChildProfile profile) => {
        'nickname': profile.nickname,
        'ageBand': profile.ageBand.id,
        if (profile.avatar != null) 'avatar': profile.avatar!.id,
      };

  static ChildProfile decode(Map<String, dynamic> data) {
    final nickname = data['nickname'];
    final age = data['ageBand'];
    if (nickname is! String || age is! String) {
      throw const FormatException('Invalid child profile.');
    }
    final bands = AgeBand.values.where((value) => value.id == age);
    if (bands.length != 1) {
      throw const FormatException('Invalid child age band.');
    }
    final avatarId = data['avatar'];
    ChildAvatar? avatar;
    if (data.containsKey('avatar')) {
      final matches = ChildAvatar.values.where((value) => value.id == avatarId);
      if (matches.length != 1) {
        throw const FormatException('Invalid child avatar.');
      }
      avatar = matches.single;
    }
    return ChildProfile(
        nickname: nickname, ageBand: bands.single, avatar: avatar);
  }

  Future<ChildProfile?> load(String parentId) async {
    final cached = await _preferences.getString(_key(parentId));
    if (cached == null) return null;
    final decoded = jsonDecode(cached);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid cached child profile.');
    }
    return decode(decoded);
  }

  Future<void> save(String parentId, ChildProfile profile) =>
      _preferences.setString(_key(parentId), jsonEncode(encode(profile)));

  Future<void> clear(String parentId) => _preferences.remove(_key(parentId));
}
