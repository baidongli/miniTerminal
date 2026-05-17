import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/host_group.dart';
import '../models/ssh_host.dart';
import '../ssh/session_manager.dart';
import '../state/app_repository.dart';
import 'host_edit_screen.dart';
import 'terminal_screen.dart';

class HostsScreen extends StatefulWidget {
  const HostsScreen({super.key});

  @override
  State<HostsScreen> createState() => _HostsScreenState();
}

class _HostsScreenState extends State<HostsScreen> {
  List<SshHost> _hosts = [];
  List<HostGroup> _groups = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final repo = context.read<AppRepository>();
    final hosts = await repo.hosts.loadHosts();
    final groups = await repo.groups.load();
    if (!mounted) return;
    setState(() {
      _hosts = hosts;
      _groups = groups;
      _loading = false;
    });
  }

  Future<void> _openEditor({SshHost? host}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => HostEditScreen(existing: host)),
    );
    if (changed == true) _reload();
  }

  Future<void> _connect(SshHost host) async {
    final repo = context.read<AppRepository>();
    final manager = context.read<SessionManager>();
    final allHosts = await repo.hosts.loadHosts();
    manager.open(host,
        allHosts: allHosts, scrollback: repo.settings.scrollback);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TerminalScreen(sessionId: host.id),
    ));
  }

  Future<void> _confirmDelete(SshHost host) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${host.displayName}"?'),
        content: const Text('This also removes the saved password.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await context.read<AppRepository>().hosts.delete(host.id);
      _reload();
    }
  }

  List<SshHost> get _filtered {
    if (_query.isEmpty) return _hosts;
    final q = _query.toLowerCase();
    return _hosts.where((h) {
      return h.displayName.toLowerCase().contains(q) ||
          h.host.toLowerCase().contains(q) ||
          h.username.toLowerCase().contains(q) ||
          h.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  String _groupName(String? id) {
    if (id == null) return 'Ungrouped';
    final g = _groups.where((g) => g.id == id);
    return g.isEmpty ? 'Ungrouped' : g.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final byGroup = <String, List<SshHost>>{};
    for (final h in filtered) {
      byGroup.putIfAbsent(_groupName(h.groupId), () => []).add(h);
    }
    final groupNames = byGroup.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hosts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search),
                hintText: 'Search hosts / tags',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? const Center(
                  child: Text('No hosts. Tap + to add your first SSH host.'))
              : ListView(
                  children: [
                    for (final g in groupNames) ...[
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(g,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary)),
                      ),
                      ...byGroup[g]!.map((host) => ListTile(
                            leading: Icon(host.jumpHostId != null
                                ? Icons.alt_route
                                : Icons.dns_outlined),
                            title: Text(host.displayName),
                            subtitle: Text(host.endpoint),
                            onTap: () => _connect(host),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _openEditor(host: host);
                                if (v == 'delete') _confirmDelete(host);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete')),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
    );
  }
}
