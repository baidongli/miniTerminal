import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

import '../models/ssh_host.dart';
import 'ssh_connection.dart';

enum SessionStatus { connecting, connected, error, closed }

class TerminalSession {
  TerminalSession({required this.host, required int scrollback})
      : terminal = Terminal(maxLines: scrollback);

  final SshHost host;
  final Terminal terminal;

  SessionStatus status = SessionStatus.connecting;
  String errorMessage = '';

  Dialed? _dialed;
  SSHSession? _shell;

  String get id => host.id;

  bool get isLive => status == SessionStatus.connected;

  void writeUser(String data) {
    _shell?.write(utf8.encode(data));
  }

  void resize(int w, int h, int pw, int ph) {
    _shell?.resizeTerminal(w, h, pw, ph);
  }

  void runCommand(String command) {
    if (command.trim().isEmpty) return;
    _shell?.write(utf8.encode('$command\n'));
  }

  void dispose() {
    _shell?.close();
    _dialed?.closeAll();
    _shell = null;
    _dialed = null;
  }
}

/// Holds all open terminal sessions. Notifies on any session list/state
/// change so the UI can rebuild tabs/status.
class SessionManager extends ChangeNotifier {
  SessionManager({required this.connection});

  final SshConnection connection;
  final List<TerminalSession> sessions = [];

  TerminalSession open(
    SshHost host, {
    required List<SshHost> allHosts,
    required int scrollback,
  }) {
    final existing = sessions.where((s) => s.id == host.id).toList();
    if (existing.isNotEmpty && existing.first.isLive) {
      return existing.first;
    }
    sessions.removeWhere((s) => s.id == host.id);

    final session =
        TerminalSession(host: host, scrollback: scrollback);
    sessions.add(session);
    notifyListeners();
    _start(session, allHosts);
    return session;
  }

  Future<void> _start(
    TerminalSession session,
    List<SshHost> allHosts,
  ) async {
    final t = session.terminal;
    session.status = SessionStatus.connecting;
    session.errorMessage = '';
    notifyListeners();
    t.write('Connecting to ${session.host.endpoint} ...\r\n');

    try {
      final dialed =
          await connection.connect(session.host, allHosts: allHosts);
      session._dialed = dialed;

      final shell = await dialed.client.shell(
        pty: SSHPtyConfig(
          width: t.viewWidth > 0 ? t.viewWidth : 80,
          height: t.viewHeight > 0 ? t.viewHeight : 25,
        ),
      );
      session._shell = shell;

      t.onOutput = (data) => shell.write(utf8.encode(data));
      t.onResize = (w, h, pw, ph) => shell.resizeTerminal(w, h, pw, ph);

      shell.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(t.write);
      shell.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(t.write);

      unawaited(shell.done.then((_) {
        session.status = SessionStatus.closed;
        t.write('\r\n*** Session closed ***\r\n');
        notifyListeners();
      }));

      final startup = session.host.startupCommand.trim();
      if (startup.isNotEmpty) {
        shell.write(utf8.encode('$startup\n'));
      }

      session.status = SessionStatus.connected;
      notifyListeners();
    } catch (e) {
      session.status = SessionStatus.error;
      session.errorMessage = e.toString();
      t.write('\r\nConnection failed: $e\r\n');
      notifyListeners();
    }
  }

  void reconnect(TerminalSession session, List<SshHost> allHosts) {
    session.dispose();
    _start(session, allHosts);
  }

  void close(String id) {
    final idx = sessions.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    sessions[idx].dispose();
    sessions.removeAt(idx);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in sessions) {
      s.dispose();
    }
    sessions.clear();
    super.dispose();
  }
}
