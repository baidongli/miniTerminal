import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../ssh/session_manager.dart';
import 'desktop/desktop_shell.dart';
import 'hosts_screen.dart';
import 'keys_screen.dart';
import 'sessions_screen.dart';
import 'settings_screen.dart';
import 'snippets_screen.dart';

/// Picks a layout based on width: master-detail desktop shell on wide
/// windows, bottom-navigation mobile shell on phones.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) return const DesktopShell();
        return const MobileShell();
      },
    );
  }
}

class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _index = 0;

  static const _pages = [
    HostsScreen(),
    SessionsScreen(),
    KeysScreen(),
    SnippetsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final sessionCount = context.watch<SessionManager>().sessions.length;
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.dns), label: l.t('hosts')),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: sessionCount > 0,
              label: Text('$sessionCount'),
              child: const Icon(Icons.terminal),
            ),
            label: l.t('sessions'),
          ),
          NavigationDestination(
              icon: const Icon(Icons.vpn_key), label: l.t('keys')),
          NavigationDestination(
              icon: const Icon(Icons.bolt), label: l.t('snippets')),
          NavigationDestination(
              icon: const Icon(Icons.settings), label: l.t('settings')),
        ],
      ),
    );
  }
}
