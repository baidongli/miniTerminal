import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ssh/session_manager.dart';
import 'terminal_screen.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SessionManager>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: manager.sessions.isEmpty
          ? const Center(child: Text('No active sessions.'))
          : ListView(
              children: manager.sessions.map((s) {
                final color = switch (s.status) {
                  SessionStatus.connected => Colors.green,
                  SessionStatus.connecting => Colors.orange,
                  SessionStatus.error => Colors.red,
                  SessionStatus.closed => Colors.grey,
                };
                return ListTile(
                  leading: Icon(Icons.circle, color: color, size: 14),
                  title: Text(s.host.displayName),
                  subtitle: Text(s.status.name),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TerminalScreen(sessionId: s.id),
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => manager.close(s.id),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
