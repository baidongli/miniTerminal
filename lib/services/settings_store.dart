import '../models/app_settings.dart';
import 'json_prefs.dart';

class SettingsStore {
  static const _key = 'miniterminal.settings';

  Future<AppSettings> load() async {
    final obj = await JsonPrefs.readObject(_key);
    if (obj == null) return const AppSettings();
    return AppSettings.fromJson(obj);
  }

  Future<void> save(AppSettings settings) =>
      JsonPrefs.writeObject(_key, settings.toJson());
}
