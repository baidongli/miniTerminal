import '../models/snippet.dart';
import 'json_prefs.dart';

class SnippetStore {
  static const _key = 'miniterminal.snippets';

  Future<List<Snippet>> load() async {
    final list = await JsonPrefs.readList(_key);
    return list.map(Snippet.fromJson).toList();
  }

  Future<void> _persist(List<Snippet> items) =>
      JsonPrefs.writeList(_key, items.map((s) => s.toJson()).toList());

  Future<List<Snippet>> upsert(Snippet snippet) async {
    final items = await load();
    final i = items.indexWhere((s) => s.id == snippet.id);
    if (i >= 0) {
      items[i] = snippet;
    } else {
      items.add(snippet);
    }
    await _persist(items);
    return items;
  }

  Future<List<Snippet>> delete(String id) async {
    final items = await load();
    items.removeWhere((s) => s.id == id);
    await _persist(items);
    return items;
  }
}
