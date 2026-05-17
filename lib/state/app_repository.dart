import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/group_store.dart';
import '../services/host_store.dart';
import '../services/key_store.dart';
import '../services/known_hosts_store.dart';
import '../services/settings_store.dart';
import '../services/snippet_store.dart';

/// Aggregates the stores and holds live [AppSettings].
class AppRepository extends ChangeNotifier {
  final hosts = HostStore();
  final keys = KeyStore();
  final groups = GroupStore();
  final snippets = SnippetStore();
  final knownHosts = KnownHostsStore();
  final _settingsStore = SettingsStore();

  AppSettings settings = const AppSettings();
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> init() async {
    settings = await _settingsStore.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings next) async {
    settings = next;
    await _settingsStore.save(next);
    notifyListeners();
  }
}
