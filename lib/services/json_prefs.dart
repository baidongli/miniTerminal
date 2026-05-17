import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small helper for storing a JSON list under a key in [SharedPreferences].
class JsonPrefs {
  static Future<List<Map<String, dynamic>>> readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> writeList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  static Future<Map<String, dynamic>?> readObject(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> writeObject(
    String key,
    Map<String, dynamic> obj,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(obj));
  }
}
