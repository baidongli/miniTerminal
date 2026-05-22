import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/ssh_host.dart';
import '../services/app_lock.dart';
import '../state/app_repository.dart';
import 'about_screen.dart';
import 'groups_screen.dart';
import 'known_hosts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    final s = repo.settings;

    Future<void> exportHosts() async {
      final hosts = await repo.hosts.loadHosts();
      final json = jsonEncode(hosts.map((h) => h.toJson()).toList());
      await Clipboard.setData(ClipboardData(text: json));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Hosts JSON copied (passwords NOT included)')));
      }
    }

    Future<void> importHosts() async {
      final c = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Paste hosts JSON'),
          content: TextField(controller: c, maxLines: 8),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Import')),
          ],
        ),
      );
      if (ok != true) return;
      try {
        final list = jsonDecode(c.text) as List<dynamic>;
        for (final e in list) {
          await repo.hosts
              .upsert(SshHost.fromJson(e as Map<String, dynamic>));
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Imported ${list.length} hosts')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Import failed: $e')));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Terminal'),
          ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<TerminalThemeId>(
              value: s.terminalTheme,
              onChanged: (v) => repo
                  .updateSettings(s.copyWith(terminalTheme: v)),
              items: TerminalThemeId.values
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(t.label)))
                  .toList(),
            ),
          ),
          ListTile(
            title: const Text('Font size'),
            subtitle: Slider(
              min: 9,
              max: 24,
              divisions: 15,
              value: s.fontSize,
              label: s.fontSize.toStringAsFixed(0),
              onChanged: (v) =>
                  repo.updateSettings(s.copyWith(fontSize: v)),
            ),
          ),
          ListTile(
            title: const Text('Scrollback lines'),
            trailing: DropdownButton<int>(
              value: s.scrollback,
              onChanged: (v) =>
                  repo.updateSettings(s.copyWith(scrollback: v)),
              items: const [1000, 5000, 10000, 50000]
                  .map((n) =>
                      DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
            ),
          ),
          const _SectionHeader('Organization'),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Groups'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const GroupsScreen())),
          ),
          const _SectionHeader('Security'),
          SwitchListTile(
            title: const Text('App lock (biometric / passcode)'),
            value: s.appLockEnabled,
            onChanged: (v) async {
              if (v) {
                final ok = await AppLock().authenticate();
                if (!ok) return;
              }
              await repo.updateSettings(s.copyWith(appLockEnabled: v));
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Known hosts'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const KnownHostsScreen())),
          ),
          const _SectionHeader('Backup'),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Export hosts to clipboard'),
            subtitle: const Text('JSON, without passwords/keys'),
            onTap: exportHosts,
          ),
          ListTile(
            leading: const Icon(Icons.paste),
            title: const Text('Import hosts from JSON'),
            onTap: importHosts,
          ),
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About MiniTerminal'),
            subtitle: const Text('A fast, secure SSH client'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AboutScreen())),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}
