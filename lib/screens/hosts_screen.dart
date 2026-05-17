import 'package:flutter/material.dart';

import '../models/ssh_host.dart';
import '../services/host_store.dart';
import 'host_edit_screen.dart';
import 'terminal_screen.dart';

class HostsScreen extends StatefulWidget {
  const HostsScreen({super.key});

  @override
  State<HostsScreen> createState() => _HostsScreenState();
}

class _HostsScreenState extends State<HostsScreen> {
  final HostStore _store = HostStore();
  List<SshHost> _hosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final hosts = await _store.loadHosts();
    if (!mounted) return;
    setState(() {
      _hosts = hosts;
      _loading = false;
    });
  }

  Future<void> _openEditor({SshHost? host}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HostEditScreen(store: _store, existing: host),
      ),
    );
    if (changed == true) _reload();
  }

  void _connect(SshHost host) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TerminalScreen(host: host, store: _store),
      ),
    );
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _store.delete(host.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MiniTerminal')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hosts.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  itemCount: _hosts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final host = _hosts[i];
                    return ListTile(
                      leading: const Icon(Icons.dns_outlined),
                      title: Text(host.displayName),
                      subtitle: Text(
                        '${host.username}@${host.host}:${host.port}',
                      ),
                      onTap: () => _connect(host),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _openEditor(host: host);
                          if (v == 'delete') _confirmDelete(host);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.terminal, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No hosts yet.\nTap + to add your first SSH host.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
