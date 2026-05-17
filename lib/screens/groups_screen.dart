import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/host_group.dart';
import '../state/app_repository.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<HostGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final g = await context.read<AppRepository>().groups.load();
    if (!mounted) return;
    setState(() {
      _groups = g;
      _loading = false;
    });
  }

  Future<void> _edit({HostGroup? group}) async {
    final c = TextEditingController(text: group?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(group == null ? 'New group' : 'Rename group'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    final repo = context.read<AppRepository>();
    await repo.groups.upsert(
        group == null ? HostGroup(name: name.trim()) : group.copyWith(name: name.trim()));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _edit(), child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(child: Text('No groups yet.'))
              : ListView(
                  children: _groups
                      .map((g) => ListTile(
                            leading: const Icon(Icons.folder),
                            title: Text(g.name),
                            onTap: () => _edit(group: g),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await context
                                    .read<AppRepository>()
                                    .groups
                                    .delete(g.id);
                                _reload();
                              },
                            ),
                          ))
                      .toList(),
                ),
    );
  }
}
