import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../ssh/session_manager.dart';
import '../ssh/terminal_themes.dart';
import '../state/app_repository.dart';

/// Inline terminal view for one session: the xterm view + the extra-key
/// toolbar + an error banner. Reused by the mobile TerminalScreen and the
/// desktop master-detail shell.
class TerminalPane extends StatefulWidget {
  const TerminalPane({super.key, required this.session});

  final TerminalSession session;

  @override
  State<TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<TerminalPane> {
  final TerminalController _controller = TerminalController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppRepository>();
    context.watch<SessionManager>(); // rebuild when session status changes
    final session = widget.session;
    final themeId = repo.settings.terminalTheme;

    return Container(
      color: AppTerminalThemes.background(themeId),
      child: Column(
        children: [
          Expanded(
            child: TerminalView(
              session.terminal,
              controller: _controller,
              autofocus: true,
              theme: AppTerminalThemes.of(themeId),
              textStyle: TerminalStyle(fontSize: repo.settings.fontSize),
              padding: EdgeInsets.zero,
              backgroundOpacity: 1.0,
            ),
          ),
          if (session.status == SessionStatus.connected)
            KeyToolbar(onKey: session.writeUser),
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

class KeyToolbar extends StatelessWidget {
  const KeyToolbar({super.key, required this.onKey});

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
