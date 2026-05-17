import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/host_group.dart';
import '../models/ssh_host.dart';
import '../models/ssh_key.dart';
import '../state/app_repository.dart';

class HostEditScreen extends StatefulWidget {
  const HostEditScreen({super.key, this.existing});

  final SshHost? existing;

  @override
  State<HostEditScreen> createState() => _HostEditScreenState();
}

class _HostEditScreenState extends State<HostEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _label;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _username;
  late final TextEditingController _startup;
  late final TextEditingController _tags;
  final _password = TextEditingController();

  SshAuthType _authType = SshAuthType.password;
  String? _keyId;
  String? _groupId;
  String? _jumpHostId;

  List<SshKey> _keys = [];
  List<HostGroup> _groups = [];
  List<SshHost> _hosts = [];

  bool _saving = false;
  bool _obscure = true;
  bool _loading = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _label = TextEditingController(text: h?.label ?? '');
    _host = TextEditingController(text: h?.host ?? '');
    _port = TextEditingController(text: (h?.port ?? 22).toString());
    _username = TextEditingController(text: h?.username ?? '');
    _startup = TextEditingController(text: h?.startupCommand ?? '');
    _tags = TextEditingController(text: (h?.tags ?? const []).join(', '));
    _authType = h?.authType ?? SshAuthType.password;
    _keyId = h?.keyId;
    _groupId = h?.groupId;
    _jumpHostId = h?.jumpHostId;
    _loadRefs();
  }

  Future<void> _loadRefs() async {
    final repo = context.read<AppRepository>();
    final keys = await repo.keys.loadKeys();
    final groups = await repo.groups.load();
    final hosts = await repo.hosts.loadHosts();
    if (!mounted) return;
    setState(() {
      _keys = keys;
      _groups = groups;
      _hosts = hosts.where((h) => h.id != widget.existing?.id).toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _label.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _startup.dispose();
    _tags.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final base = widget.existing ??
        SshHost(label: '', host: '', username: '');
    final host = base.copyWith(
      label: _label.text.trim(),
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _username.text.trim(),
      authType: _authType,
      keyId: _authType == SshAuthType.key ? _keyId : null,
      clearKeyId: _authType != SshAuthType.key,
      groupId: _groupId,
      clearGroupId: _groupId == null,
      jumpHostId: _jumpHostId,
      clearJumpHostId: _jumpHostId == null,
      startupCommand: _startup.text.trim(),
      tags: _tags.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    );

    await context.read<AppRepository>().hosts.upsert(
          host,
          password: _password.text.isEmpty ? null : _password.text,
        );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Host' : 'New Host')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _label,
              decoration: const InputDecoration(
                  labelText: 'Label (optional)', hintText: 'My server'),
            ),
            TextFormField(
              controller: _host,
              decoration: const InputDecoration(
                  labelText: 'Host', hintText: 'example.com or 192.168.1.10'),
              autocorrect: false,
              validator: _required,
            ),
            TextFormField(
              controller: _port,
              decoration: const InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1 || n > 65535) return '1-65535';
                return null;
              },
            ),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username'),
              autocorrect: false,
              validator: _required,
            ),
            const SizedBox(height: 16),
            SegmentedButton<SshAuthType>(
              segments: const [
                ButtonSegment(
                    value: SshAuthType.password, label: Text('Password')),
                ButtonSegment(value: SshAuthType.key, label: Text('Key')),
              ],
              selected: {_authType},
              onSelectionChanged: (s) =>
                  setState(() => _authType = s.first),
            ),
            if (_authType == SshAuthType.password)
              TextFormField(
                controller: _password,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'Password (leave blank to keep)'
                      : 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                validator: (v) {
                  if (_isEditing) return null;
                  return (v == null || v.isEmpty) ? 'Required' : null;
                },
              ),
            if (_authType == SshAuthType.key)
              DropdownButtonFormField<String>(
                initialValue: _keyId,
                decoration: const InputDecoration(labelText: 'SSH key'),
                items: _keys
                    .map((k) => DropdownMenuItem(
                        value: k.id, child: Text(k.name)))
                    .toList(),
                onChanged: (v) => setState(() => _keyId = v),
                validator: (v) =>
                    v == null ? 'Pick a key (add one in Keys tab)' : null,
              ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _groupId,
              decoration: const InputDecoration(labelText: 'Group'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— None —')),
                ..._groups.map((g) =>
                    DropdownMenuItem(value: g.id, child: Text(g.name))),
              ],
              onChanged: (v) => setState(() => _groupId = v),
            ),
            DropdownButtonFormField<String?>(
              initialValue: _jumpHostId,
              decoration:
                  const InputDecoration(labelText: 'Jump host (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— None —')),
                ..._hosts.map((h) => DropdownMenuItem(
                    value: h.id, child: Text(h.displayName))),
              ],
              onChanged: (v) => setState(() => _jumpHostId = v),
            ),
            TextFormField(
              controller: _startup,
              decoration: const InputDecoration(
                  labelText: 'Startup command (optional)'),
              autocorrect: false,
            ),
            TextFormField(
              controller: _tags,
              decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
