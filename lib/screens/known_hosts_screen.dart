import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_repository.dart';

class KnownHostsScreen extends StatefulWidget {
  const KnownHostsScreen({super.key});

  @override
  State<KnownHostsScreen> createState() => _KnownHostsScreenState();
}

class _KnownHostsScreenState extends State<KnownHostsScreen> {
  Map<String, String> _entries = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final all = await context.read<AppRepository>().knownHosts.all();
    if (!mounted) return;
    setState(() {
      _entries = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Known hosts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              await context.read<AppRepository>().knownHosts.clear();
              _reload();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('No trusted host keys yet.'))
              : ListView(
                  children: _entries.entries
                      .map((e) => ListTile(
                            leading: const Icon(Icons.verified_user),
                            title: Text(e.key),
                            subtitle: Text(e.value,
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 11)),
                          ))
                      .toList(),
                ),
    );
  }
}
