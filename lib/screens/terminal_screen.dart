import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/snippet.dart';
import '../ssh/session_manager.dart';
import '../ssh/terminal_themes.dart';
import '../state/app_repository.dart';
import '../widgets/terminal_pane.dart';
import 'port_forward_screen.dart';
import 'sftp_screen.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  TerminalSession? _session(SessionManager m) {
    final list = m.sessions.where((s) => s.id == widget.sessionId);
    return list.isEmpty ? null : list.first;
  }

  Future<void> _pickSnippet(TerminalSession session) async {
    final chosen = await pickSnippet(context);
    if (chosen != null) session.runCommand(chosen.command);
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SessionManager>();
    final repo = context.watch<AppRepository>();
    final session = _session(manager);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Session closed.')),
      );
    }

    return Scaffold(
      backgroundColor:
          AppTerminalThemes.background(repo.settings.terminalTheme),
      appBar: AppBar(
        title: Text(session.host.displayName),
        actions: [
          IconButton(
            tooltip: 'Snippets',
            icon: const Icon(Icons.bolt),
            onPressed: session.isLive ? () => _pickSnippet(session) : null,
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'reconnect') {
                final hosts = await repo.hosts.loadHosts();
                manager.reconnect(session, hosts);
              } else if (v == 'sftp') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SftpScreen(host: session.host),
                ));
              } else if (v == 'forward') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PortForwardScreen(host: session.host),
                ));
              } else if (v == 'close') {
                manager.close(session.id);
                if (mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reconnect', child: Text('Reconnect')),
              PopupMenuItem(value: 'sftp', child: Text('SFTP files')),
              PopupMenuItem(value: 'forward', child: Text('Port forwarding')),
              PopupMenuItem(value: 'close', child: Text('Close session')),
            ],
          ),
        ],
      ),
      body: TerminalPane(session: session),
    );
  }
}

/// Shared snippet picker used by mobile and desktop terminal UIs.
Future<Snippet?> pickSnippet(BuildContext context) async {
  final repo = context.read<AppRepository>();
  final snippets = await repo.snippets.load();
  if (!context.mounted) return null;
  if (snippets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No snippets yet. Add some first.')),
    );
    return null;
  }
  return showModalBottomSheet<Snippet>(
    context: context,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: snippets
            .map((s) => ListTile(
                  title: Text(s.name),
                  subtitle: Text(s.command,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.pop(context, s),
                ))
            .toList(),
      ),
    ),
  );
}
