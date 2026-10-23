import '../domain/child_profile.dart';
import '../domain/profile_repository.dart';

class GuestProfileRepository implements ProfileRepository {
  final _profiles = <String, ChildProfile>{};

  @override
  Future<LoadedProfile> load(String parentId) async =>
      LoadedProfile(_profiles[parentId]);

  @override
  Future<void> save(String parentId, ChildProfile profile) async {
    _profiles[parentId] = profile;
  }

  @override
  Future<void> clearLocal(String parentId) async {
    _profiles.remove(parentId);
  }
}
