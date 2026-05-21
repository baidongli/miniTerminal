import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/ssh_key.dart';
import '../ssh/key_gen.dart';
import '../state/app_repository.dart';

class KeysScreen extends StatefulWidget {
  const KeysScreen({super.key});

  @override
  State<KeysScreen> createState() => _KeysScreenState();
}

class _KeysScreenState extends State<KeysScreen> {
  List<SshKey> _keys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final keys = await context.read<AppRepository>().keys.loadKeys();
    if (!mounted) return;
    setState(() {
      _keys = keys;
      _loading = false;
    });
  }

  Future<void> _generate() async {
    final name = await _prompt('Key name', 'My ed25519 key');
    if (name == null || name.isEmpty) return;
    final gen = await KeyGen.ed25519(comment: name);
    await context.read<AppRepository>().keys.upsert(
          SshKey(name: name, type: 'ed25519', publicKey: gen.publicKeyLine),
          privateKeyPem: gen.privateKeyOpenSsh,
        );
    await _reload();
    if (mounted) _showPublicKey(gen.publicKeyLine);
  }

  Future<void> _import() async {
    final picked = await openFile();
    if (picked == null) return;
    final pem = await picked.readAsString();
    final name = await _prompt('Key name', picked.name);
    if (name == null || name.isEmpty) return;
    final pass = await _prompt('Passphrase (blank if none)', '');
    await context.read<AppRepository>().keys.upsert(
          SshKey(
            name: name,
            type: 'imported',
            publicKey: '',
            hasPassphrase: pass != null && pass.isNotEmpty,
          ),
          privateKeyPem: pem,
          passphrase: pass ?? '',
        );
    await _reload();
  }

  Future<void> _pasteImport() async {
    final pem = await _multilinePrompt('Paste private key (PEM)');
    if (pem == null || pem.trim().isEmpty) return;
    final name = await _prompt('Key name', 'Pasted key');
    if (name == null || name.isEmpty) return;
    final pass = await _prompt('Passphrase (blank if none)', '');
    await context.read<AppRepository>().keys.upsert(
          SshKey(
            name: name,
            type: 'imported',
            publicKey: '',
            hasPassphrase: pass != null && pass.isNotEmpty,
          ),
          privateKeyPem: pem,
          passphrase: pass ?? '',
        );
    await _reload();
  }

  void _showPublicKey(String pub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Public key'),
        content: SelectableText(
          pub.isEmpty ? '(no public key stored for imported key)' : pub,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        actions: [
          if (pub.isNotEmpty)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pub));
                Navigator.pop(ctx);
              },
              child: const Text('Copy'),
            ),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<String?> _prompt(String title, String initial) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<String?> _multilinePrompt(String title) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 8,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Import')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH Keys'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (v) {
              if (v == 'gen') _generate();
              if (v == 'file') _import();
              if (v == 'paste') _pasteImport();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'gen', child: Text('Generate ed25519')),
              PopupMenuItem(value: 'file', child: Text('Import from file')),
              PopupMenuItem(value: 'paste', child: Text('Paste private key')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _keys.isEmpty
              ? const Center(
                  child: Text('No keys. Use + to generate or import.'))
              : ListView(
                  children: _keys.map((k) {
                    return ListTile(
                      leading: const Icon(Icons.vpn_key),
                      title: Text(k.name),
                      subtitle: Text(
                          '${k.type}${k.hasPassphrase ? " · passphrase" : ""}'),
                      onTap: () => _showPublicKey(k.publicKey),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await context
                              .read<AppRepository>()
                              .keys
                              .delete(k.id);
                          _reload();
                        },
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
