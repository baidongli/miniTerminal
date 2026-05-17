import 'package:shared_preferences/shared_preferences.dart';

import 'json_prefs.dart';

/// Trust-on-first-use store of host-key fingerprints, keyed by "host:port".
class KnownHostsStore {
  static const _key = 'miniterminal.knownhosts';

  Future<Map<String, String>> _all() async {
    final obj = await JsonPrefs.readObject(_key);
    if (obj == null) return {};
    return obj.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<String?> fingerprintFor(String host, int port) async {
    final all = await _all();
    return all['$host:$port'];
  }

  Future<void> trust(String host, int port, String fingerprint) async {
    final all = await _all();
    all['$host:$port'] = fingerprint;
    await JsonPrefs.writeObject(_key, all);
  }

  Future<void> forget(String host, int port) async {
    final all = await _all();
    all.remove('$host:$port');
    await JsonPrefs.writeObject(_key, all);
  }

  Future<Map<String, String>> all() => _all();

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
