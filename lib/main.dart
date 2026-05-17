import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'ssh/session_manager.dart';
import 'ssh/ssh_connection.dart';
import 'state/app_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = AppRepository();
  await repo.init();
  final sessions = SessionManager(
    connection: SshConnection(hostStore: repo.hosts, keyStore: repo.keys),
  );
  runApp(MiniTerminalApp(repo: repo, sessions: sessions));
}

class MiniTerminalApp extends StatelessWidget {
  const MiniTerminalApp({
    super.key,
    required this.repo,
    required this.sessions,
  });

  final AppRepository repo;
  final SessionManager sessions;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repo),
        ChangeNotifierProvider.value(value: sessions),
      ],
      child: MaterialApp(
        title: 'MiniTerminal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.light),
        darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark),
        themeMode: ThemeMode.system,
        home: const _Gate(),
      ),
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final locked =
        context.watch<AppRepository>().settings.appLockEnabled && !_unlocked;
    if (locked) {
      return LockScreen(onUnlocked: () => setState(() => _unlocked = true));
    }
    return const HomeScreen();
  }
}
