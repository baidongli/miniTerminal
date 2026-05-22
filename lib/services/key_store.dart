import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/ssh_key.dart';
import 'json_prefs.dart';

/// Stores key metadata + public key in prefs; the private key PEM and its
/// optional passphrase live in secure storage.
class KeyStore {
  KeyStore({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage(
              mOptions:
                  MacOsOptions(usesDataProtectionKeychain: false),
            );

  static const _keysKey = 'miniterminal.keys';
  static String _pemKey(String id) => 'miniterminal.keypem.$id';
  static String _passKey(String id) => 'miniterminal.keypass.$id';

  final FlutterSecureStorage _secure;

  Future<List<SshKey>> loadKeys() async {
    final list = await JsonPrefs.readList(_keysKey);
    return list.map(SshKey.fromJson).toList();
  }

  Future<void> _persist(List<SshKey> keys) =>
      JsonPrefs.writeList(_keysKey, keys.map((k) => k.toJson()).toList());

  Future<List<SshKey>> upsert(
    SshKey key, {
    String? privateKeyPem,
    String? passphrase,
  }) async {
    final keys = await loadKeys();
    final index = keys.indexWhere((k) => k.id == key.id);
    if (index >= 0) {
      keys[index] = key;
    } else {
      keys.add(key);
    }
    await _persist(keys);
    if (privateKeyPem != null && privateKeyPem.isNotEmpty) {
      await _secure.write(key: _pemKey(key.id), value: privateKeyPem);
    }
    if (passphrase != null) {
      if (passphrase.isEmpty) {
        await _secure.delete(key: _passKey(key.id));
      } else {
        await _secure.write(key: _passKey(key.id), value: passphrase);
      }
    }
    return keys;
  }

  Future<List<SshKey>> delete(String id) async {
    final keys = await loadKeys();
    keys.removeWhere((k) => k.id == id);
    await _persist(keys);
    await _secure.delete(key: _pemKey(id));
    await _secure.delete(key: _passKey(id));
    return keys;
  }

  Future<String?> readPem(String id) => _secure.read(key: _pemKey(id));
  Future<String?> readPassphrase(String id) =>
      _secure.read(key: _passKey(id));
}
