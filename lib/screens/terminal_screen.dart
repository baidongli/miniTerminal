import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../models/snippet.dart';
import '../ssh/session_manager.dart';
import '../ssh/terminal_themes.dart';
import '../state/app_repository.dart';
import 'port_forward_screen.dart';
import 'sftp_screen.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TerminalController _controller = TerminalController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TerminalSession? _session(SessionManager m) {
    final list = m.sessions.where((s) => s.id == widget.sessionId);
    return list.isEmpty ? null : list.first;
  }

  Future<void> _pickSnippet(TerminalSession session) async {
    final repo = context.read<AppRepository>();
    final snippets = await repo.snippets.load();
    if (!mounted) return;
    if (snippets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No snippets yet. Add some in the Snippets tab.')),
      );
      return;
    }
    final chosen = await showModalBottomSheet<Snippet>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: snippets
              .map((s) => ListTile(
                    title: Text(s.name),
                    subtitle: Text(
                      s.command,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(context, s),
                  ))
              .toList(),
        ),
      ),
    );
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

    final themeId = repo.settings.terminalTheme;

    return Scaffold(
      backgroundColor: AppTerminalThemes.background(themeId),
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
      body: Column(
        children: [
          Expanded(
            child: TerminalView(
              session.terminal,
              controller: _controller,
              autofocus: true,
              theme: AppTerminalThemes.of(themeId),
              textStyle: TerminalStyle(fontSize: repo.settings.fontSize),
              backgroundOpacity: 1.0,
            ),
          ),
          if (session.status == SessionStatus.connected)
            _KeyToolbar(onKey: session.writeUser),
          if (session.status == SessionStatus.error)
            Container(
              width: double.infinity,
              color: Colors.red.shade900,
              padding: const EdgeInsets.all(12),
              child: Text(session.errorMessage,
                  style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _KeyToolbar extends StatelessWidget {
  const _KeyToolbar({required this.onKey});

  final void Function(String data) onKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFF2A2A2A),
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            _k('ESC', '\x1b'),
            _k('TAB', '\t'),
            _k('CTRL+C', '\x03'),
            _k('CTRL+D', '\x04'),
            _k('CTRL+L', '\x0c'),
            _k('CTRL+Z', '\x1a'),
            _k('↑', '\x1b[A'),
            _k('↓', '\x1b[B'),
            _k('←', '\x1b[D'),
            _k('→', '\x1b[C'),
            _k('HOME', '\x1b[H'),
            _k('END', '\x1b[F'),
            _k('|', '|'),
            _k('~', '~'),
            _k('/', '/'),
          ],
        ),
      ),
    );
  }

  Widget _k(String label, String data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF3A3A3A),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {
          HapticFeedback.selectionClick();
          onKey(data);
        },
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
