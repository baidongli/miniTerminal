import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ssh_host.dart';
import '../../ssh/session_manager.dart';
import '../../state/app_repository.dart';
import '../../widgets/terminal_pane.dart';
import '../groups_screen.dart';
import '../host_edit_screen.dart';
import '../keys_screen.dart';
import '../port_forward_screen.dart';
import '../settings_screen.dart';
import '../sftp_screen.dart';
import '../snippets_screen.dart';
import '../terminal_screen.dart' show pickSnippet;

/// Desktop / wide-screen layout: a hosts + sessions sidebar on the left
/// and a tabbed terminal area on the right.
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  List<SshHost> _hosts = [];
  String _query = '';
  String? _selectedId;
  bool _loading = true;
  bool _sidebarVisible = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final hosts = await context.read<AppRepository>().hosts.loadHosts();
    if (!mounted) return;
    setState(() {
      _hosts = hosts;
      _loading = false;
    });
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

  Future<void> _connect(SshHost host) async {
    final repo = context.read<AppRepository>();
    final manager = context.read<SessionManager>();
    final allHosts = await repo.hosts.loadHosts();
    manager.open(host,
        allHosts: allHosts, scrollback: repo.settings.scrollback);
    setState(() => _selectedId = host.id);
  }

  Future<void> _addOrEdit({SshHost? host}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => HostEditScreen(existing: host)),
    );
    if (changed == true) _reload();
  }

  void _push(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SessionManager>();
    final sessions = manager.sessions;

    // Resolve the selected session, falling back to the first open one.
    TerminalSession? selected;
    for (final s in sessions) {
      if (s.id == _selectedId) selected = s;
    }
    selected ??= sessions.isNotEmpty ? sessions.first : null;

    return Scaffold(
      body: Row(
        children: [
          if (_sidebarVisible) ...[
            SizedBox(width: 280, child: _sidebar(manager)),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: _sessionArea(manager, selected)),
        ],
      ),
    );
  }

  Widget _sidebar(SessionManager manager) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Text('MiniTerminal',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                tooltip: 'New host',
                icon: const Icon(Icons.add),
                onPressed: () => _addOrEdit(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search),
              hintText: 'Search hosts',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    _label('HOSTS'),
                    ..._filtered.map((h) => ListTile(
                          dense: true,
                          leading: Icon(
                              h.jumpHostId != null
                                  ? Icons.alt_route
                                  : Icons.dns_outlined,
                              size: 20),
                          title: Text(h.displayName,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(h.endpoint,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _connect(h),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _addOrEdit(host: h);
                              if (v == 'delete') _deleteHost(h);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        )),
                    if (manager.sessions.isNotEmpty) _label('SESSIONS'),
                    ...manager.sessions.map((s) => ListTile(
                          dense: true,
                          leading: Icon(Icons.circle,
                              size: 12, color: _statusColor(s.status)),
                          title: Text(s.host.displayName,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          selected: s.id == _selectedId,
                          onTap: () => setState(() => _selectedId = s.id),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => manager.close(s.id),
                          ),
                        )),
                  ],
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                  tooltip: 'Keys',
                  icon: const Icon(Icons.vpn_key),
                  onPressed: () => _push(const KeysScreen())),
              IconButton(
                  tooltip: 'Snippets',
                  icon: const Icon(Icons.bolt),
                  onPressed: () => _push(const SnippetsScreen())),
              IconButton(
                  tooltip: 'Groups',
                  icon: const Icon(Icons.folder),
                  onPressed: () => _push(const GroupsScreen())),
              IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings),
                  onPressed: () => _push(const SettingsScreen())),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteHost(SshHost host) async {
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

  Widget _sessionArea(SessionManager manager, TerminalSession? selected) {
    return Column(
      children: [
        _topBar(manager, selected),
        const Divider(height: 1),
        if (selected == null)
          const Expanded(
            child: Center(
              child: Text('Select a host on the left to connect.'),
            ),
          )
        else ...[
          _actionBar(manager, selected),
          const Divider(height: 1),
          Expanded(
            child: TerminalPane(
              key: ValueKey(selected.id),
              session: selected,
            ),
          ),
        ],
      ],
    );
  }

  Widget _topBar(SessionManager manager, TerminalSession? selected) {
    return Container(
      height: 40,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          IconButton(
            tooltip: _sidebarVisible ? 'Hide sidebar' : 'Show sidebar',
            icon: Icon(_sidebarVisible ? Icons.menu_open : Icons.menu),
            onPressed: () =>
                setState(() => _sidebarVisible = !_sidebarVisible),
          ),
          Expanded(child: _tabs(manager, selected)),
        ],
      ),
    );
  }

  Widget _tabs(SessionManager manager, TerminalSession? selected) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: manager.sessions.map((s) {
        final active = selected != null && s.id == selected.id;
          return InkWell(
            onTap: () => setState(() => _selectedId = s.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.surface
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle,
                      size: 10, color: _statusColor(s.status)),
                  const SizedBox(width: 6),
                  Text(s.host.displayName),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => manager.close(s.id),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
    );
  }

  Widget _actionBar(SessionManager manager, TerminalSession session) {
    return Row(
      children: [
        TextButton.icon(
          icon: const Icon(Icons.bolt, size: 18),
          label: const Text('Snippets'),
          onPressed: session.isLive
              ? () async {
                  final s = await pickSnippet(context);
                  if (s != null) session.runCommand(s.command);
                }
              : null,
        ),
        TextButton.icon(
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reconnect'),
          onPressed: () async {
            final hosts =
                await context.read<AppRepository>().hosts.loadHosts();
            manager.reconnect(session, hosts);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.folder_open, size: 18),
          label: const Text('SFTP'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SftpScreen(host: session.host))),
        ),
        TextButton.icon(
          icon: const Icon(Icons.swap_horiz, size: 18),
          label: const Text('Forward'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PortForwardScreen(host: session.host))),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600)),
      );

  Color _statusColor(SessionStatus status) => switch (status) {
        SessionStatus.connected => Colors.green,
        SessionStatus.connecting => Colors.orange,
        SessionStatus.error => Colors.red,
        SessionStatus.closed => Colors.grey,
      };
}
