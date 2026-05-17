import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../models/ssh_host.dart';
import '../services/host_store.dart';

enum _ConnState { connecting, connected, error }

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key, required this.host, required this.store});

  final SshHost host;
  final HostStore store;

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final Terminal _terminal = Terminal(maxLines: 10000);
  final TerminalController _terminalController = TerminalController();

  SSHClient? _client;
  SSHSession? _session;

  _ConnState _state = _ConnState.connecting;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    setState(() {
      _state = _ConnState.connecting;
      _errorMessage = '';
    });
    _terminal.write('Connecting to ${widget.host.host}:${widget.host.port}...\r\n');

    try {
      final password = await widget.store.readPassword(widget.host.id);
      if (password == null || password.isEmpty) {
        throw SSHAuthAbortError('No saved password for this host.');
      }

      final socket = await SSHSocket.connect(
        widget.host.host,
        widget.host.port,
        timeout: const Duration(seconds: 15),
      );

      final client = SSHClient(
        socket,
        username: widget.host.username,
        onPasswordRequest: () => password,
      );
      _client = client;

      final session = await client.shell(
        pty: SSHPtyConfig(
          width: _terminal.viewWidth > 0 ? _terminal.viewWidth : 80,
          height: _terminal.viewHeight > 0 ? _terminal.viewHeight : 25,
        ),
      );
      _session = session;

      _terminal.onOutput = (data) {
        session.write(utf8.encode(data));
      };
      _terminal.onResize = (w, h, pw, ph) {
        session.resizeTerminal(w, h, pw, ph);
      };

      session.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(_terminal.write);
      session.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(_terminal.write);

      unawaited(session.done.then((_) {
        if (!mounted) return;
        _terminal.write('\r\n*** Session closed ***\r\n');
      }));

      if (!mounted) return;
      setState(() => _state = _ConnState.connected);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ConnState.error;
        _errorMessage = e.toString();
      });
      _terminal.write('\r\nConnection failed: $e\r\n');
    }
  }

  void _disconnect() {
    _session?.close();
    _client?.close();
    _session = null;
    _client = null;
  }

  @override
  void dispose() {
    _disconnect();
    _terminalController.dispose();
    super.dispose();
  }

  void _sendKey(String data) {
    _session?.write(utf8.encode(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(widget.host.displayName),
        actions: [
          if (_state == _ConnState.error)
            IconButton(
              tooltip: 'Reconnect',
              icon: const Icon(Icons.refresh),
              onPressed: _connect,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TerminalView(
              _terminal,
              controller: _terminalController,
              autofocus: true,
              backgroundOpacity: 1.0,
            ),
          ),
          if (_state == _ConnState.connected) _KeyToolbar(onKey: _sendKey),
          if (_state == _ConnState.error)
            Container(
              width: double.infinity,
              color: Colors.red.shade900,
              padding: const EdgeInsets.all(12),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// A compact row of keys that a soft keyboard typically lacks.
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
            _key('ESC', '\x1b'),
            _key('TAB', '\t'),
            _key('CTRL+C', '\x03'),
            _key('CTRL+D', '\x04'),
            _key('CTRL+L', '\x0c'),
            _key('CTRL+Z', '\x1a'),
            _key('↑', '\x1b[A'),
            _key('↓', '\x1b[B'),
            _key('←', '\x1b[D'),
            _key('→', '\x1b[C'),
            _key('HOME', '\x1b[H'),
            _key('END', '\x1b[F'),
          ],
        ),
      ),
    );
  }

  Widget _key(String label, String data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFF3A3A3A),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        onPressed: () => onKey(data),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
