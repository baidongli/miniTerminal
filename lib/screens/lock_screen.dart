import 'package:flutter/material.dart';

import '../services/app_lock.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _trying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_trying) return;
    setState(() => _trying = true);
    final ok = await AppLock().authenticate();
    setState(() => _trying = false);
    if (ok) widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 64),
            const SizedBox(height: 16),
            const Text('MiniTerminal is locked'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _trying ? null : _unlock,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
