import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/ssh_host.dart';
import '../ssh/ssh_connection.dart';
import '../state/app_repository.dart';

class SftpScreen extends StatefulWidget {
  const SftpScreen({super.key, required this.host});

  final SshHost host;

  @override
  State<SftpScreen> createState() => _SftpScreenState();
}

class _SftpScreenState extends State<SftpScreen> {
  Dialed? _dialed;
  SftpClient? _sftp;
  String _cwd = '.';
  List<SftpName> _entries = [];
  bool _busy = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _dialed?.closeAll();
    super.dispose();
  }

  Future<void> _connect() async {
    final repo = context.read<AppRepository>();
    try {
      final conn = SshConnection(
        hostStore: repo.hosts,
        keyStore: repo.keys,
        knownHosts: repo.knownHosts,
      );
      final hosts = await repo.hosts.loadHosts();
      final dialed = await conn.connect(widget.host, allHosts: hosts);
      _dialed = dialed;
      _sftp = await dialed.client.sftp();
      final home = await _sftp!.absolute('.');
      _cwd = home;
      await _list();
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _list() async {
    setState(() => _busy = true);
    try {
      final items = await _sftp!.listdir(_cwd);
      items.sort((a, b) {
        final ad = a.attr.isDirectory ? 0 : 1;
        final bd = b.attr.isDirectory ? 0 : 1;
        if (ad != bd) return ad - bd;
        return a.filename.toLowerCase().compareTo(b.filename.toLowerCase());
      });
      setState(() {
        _entries = items.where((e) => e.filename != '.').toList();
        _busy = false;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  String _join(String base, String name) {
    if (name == '..') {
      final i = base.lastIndexOf('/');
      if (i <= 0) return '/';
      return base.substring(0, i);
    }
    return base.endsWith('/') ? '$base$name' : '$base/$name';
  }

  Future<void> _download(SftpName entry) async {
    setState(() => _busy = true);
    try {
      final remote = _join(_cwd, entry.filename);
      final file = await _sftp!.open(remote);
      final bytes = await file.readBytes();
      await file.close();
      final dir = await getApplicationDocumentsDirectory();
      final out = File('${dir.path}/${entry.filename}');
      await out.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${out.path}')),
        );
      }
    } catch (e) {
      _snack('Download failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final picked = await openFile();
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final data = await picked.readAsBytes();
      final name = picked.name;
      final remote = _join(_cwd, name);
      final file = await _sftp!.open(
        remote,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );
      await file.writeBytes(data);
      await file.close();
      await _list();
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(SftpName entry) async {
    final remote = _join(_cwd, entry.filename);
    try {
      if (entry.attr.isDirectory) {
        await _sftp!.rmdir(remote);
      } else {
        await _sftp!.remove(remote);
      }
      await _list();
    } catch (e) {
      _snack('Delete failed: $e');
    }
  }

  Future<void> _mkdir() async {
    final name = await _prompt('New folder name');
    if (name == null || name.isEmpty) return;
    try {
      await _sftp!.mkdir(_join(_cwd, name));
      await _list();
    } catch (e) {
      _snack('mkdir failed: $e');
    }
  }

  Future<String?> _prompt(String title) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('OK')),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SFTP'),
        actions: [
          IconButton(
              onPressed: _busy ? null : _mkdir,
              icon: const Icon(Icons.create_new_folder)),
          IconButton(
              onPressed: _busy ? null : _upload,
              icon: const Icon(Icons.upload_file)),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(_cwd, style: const TextStyle(fontFamily: 'monospace')),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error,
                  style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.arrow_upward),
                        title: const Text('..'),
                        onTap: () {
                          _cwd = _join(_cwd, '..');
                          _list();
                        },
                      ),
                      ..._entries.map((e) {
                        final isDir = e.attr.isDirectory;
                        return ListTile(
                          leading: Icon(
                              isDir ? Icons.folder : Icons.insert_drive_file),
                          title: Text(e.filename),
                          subtitle: isDir
                              ? null
                              : Text('${e.attr.size ?? 0} bytes'),
                          onTap: () {
                            if (isDir) {
                              _cwd = _join(_cwd, e.filename);
                              _list();
                            } else {
                              _download(e);
                            }
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'download') _download(e);
                              if (v == 'delete') _delete(e);
                            },
                            itemBuilder: (_) => [
                              if (!isDir)
                                const PopupMenuItem(
                                    value: 'download',
                                    child: Text('Download')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
