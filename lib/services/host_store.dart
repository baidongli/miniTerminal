import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ssh_host.dart';

/// Persists host metadata in [SharedPreferences] and the per-host password in
/// the platform secure storage (iOS Keychain / Android Keystore).
class HostStore {
  HostStore({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  static const _hostsKey = 'miniterminal.hosts';
  static String _passwordKey(String id) => 'miniterminal.password.$id';

  final FlutterSecureStorage _secure;

  Future<List<SshHost>> loadHosts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hostsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => SshHost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist(List<SshHost> hosts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(hosts.map((h) => h.toJson()).toList());
    await prefs.setString(_hostsKey, raw);
  }

  Future<List<SshHost>> upsert(SshHost host, {String? password}) async {
    final hosts = await loadHosts();
    final index = hosts.indexWhere((h) => h.id == host.id);
    if (index >= 0) {
      hosts[index] = host;
    } else {
      hosts.add(host);
    }
    await _persist(hosts);
    if (password != null && password.isNotEmpty) {
      await _secure.write(key: _passwordKey(host.id), value: password);
    }
    return hosts;
  }

  Future<List<SshHost>> delete(String id) async {
    final hosts = await loadHosts();
    hosts.removeWhere((h) => h.id == id);
    await _persist(hosts);
    await _secure.delete(key: _passwordKey(id));
    return hosts;
  }

  Future<String?> readPassword(String id) =>
      _secure.read(key: _passwordKey(id));
}
