import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/snippet.dart';
import '../state/app_repository.dart';

class SnippetsScreen extends StatefulWidget {
  const SnippetsScreen({super.key});

  @override
  State<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends State<SnippetsScreen> {
  List<Snippet> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await context.read<AppRepository>().snippets.load();
    if (!mounted) return;
    setState(() {
      _items = s;
      _loading = false;
    });
  }

  Future<void> _edit({Snippet? snippet}) async {
    final name = TextEditingController(text: snippet?.name ?? '');
    final cmd = TextEditingController(text: snippet?.command ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(snippet == null ? 'New snippet' : 'Edit snippet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: cmd,
                decoration: const InputDecoration(labelText: 'Command'),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final repo = context.read<AppRepository>();
    await repo.snippets.upsert(snippet == null
        ? Snippet(name: name.text.trim(), command: cmd.text)
        : snippet.copyWith(name: name.text.trim(), command: cmd.text));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Snippets')),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _edit(), child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text('No snippets. Add reusable commands here.'))
              : ListView(
                  children: _items
                      .map((s) => ListTile(
                            leading: const Icon(Icons.bolt),
                            title: Text(s.name),
                            subtitle: Text(s.command,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            onTap: () => _edit(snippet: s),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await context
                                    .read<AppRepository>()
                                    .snippets
                                    .delete(s.id);
                                _reload();
                              },
                            ),
                          ))
                      .toList(),
                ),
    );
  }
}
