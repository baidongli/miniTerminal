import 'package:flutter/material.dart';

/// Lightweight localization (English + 中文). Lookup falls back to the key
/// itself, then English, so partially-translated strings stay readable.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _Delegate();

  static const supportedLocales = [Locale('en'), Locale('zh')];

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'hosts': 'Hosts',
      'sessions': 'Sessions',
      'keys': 'Keys',
      'snippets': 'Snippets',
      'settings': 'Settings',
      'groups': 'Groups',
      'newHost': 'New Host',
      'editHost': 'Edit Host',
      'searchHosts': 'Search hosts / tags',
      'noHosts': 'No hosts. Tap + to add your first SSH host.',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'connect': 'Connect',
    },
    'zh': {
      'hosts': '主机',
      'sessions': '会话',
      'keys': '密钥',
      'snippets': '片段',
      'settings': '设置',
      'groups': '分组',
      'newHost': '新建主机',
      'editHost': '编辑主机',
      'searchHosts': '搜索主机 / 标签',
      'noHosts': '还没有主机，点 + 添加第一个 SSH 主机。',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'connect': '连接',
    },
  };

  String t(String key) {
    final lang = locale.languageCode;
    return _values[lang]?[key] ?? _values['en']?[key] ?? key;
  }
}

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_Delegate old) => false;
}
