import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ssh/session_manager.dart';
import 'hosts_screen.dart';
import 'keys_screen.dart';
import 'sessions_screen.dart';
import 'settings_screen.dart';
import 'snippets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.dns), label: 'Hosts'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: sessionCount > 0,
              label: Text('$sessionCount'),
              child: const Icon(Icons.terminal),
            ),
            label: 'Sessions',
          ),
          const NavigationDestination(
              icon: Icon(Icons.vpn_key), label: 'Keys'),
          const NavigationDestination(
              icon: Icon(Icons.bolt), label: 'Snippets'),
          const NavigationDestination(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
