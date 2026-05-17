import 'package:flutter/material.dart';

import 'screens/hosts_screen.dart';

void main() {
  runApp(const MiniTerminalApp());
}

class MiniTerminalApp extends StatelessWidget {
  const MiniTerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiniTerminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HostsScreen(),
    );
  }
}
