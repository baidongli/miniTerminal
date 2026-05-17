import '../models/host_group.dart';
import 'json_prefs.dart';

class GroupStore {
  static const _key = 'miniterminal.groups';

  Future<List<HostGroup>> load() async {
    final list = await JsonPrefs.readList(_key);
    return list.map(HostGroup.fromJson).toList();
  }

  Future<void> _persist(List<HostGroup> groups) =>
      JsonPrefs.writeList(_key, groups.map((g) => g.toJson()).toList());

  Future<List<HostGroup>> upsert(HostGroup group) async {
    final groups = await load();
    final i = groups.indexWhere((g) => g.id == group.id);
    if (i >= 0) {
      groups[i] = group;
    } else {
      groups.add(group);
    }
    await _persist(groups);
    return groups;
  }

  Future<List<HostGroup>> delete(String id) async {
    final groups = await load();
    groups.removeWhere((g) => g.id == id);
    await _persist(groups);
    return groups;
  }
}
