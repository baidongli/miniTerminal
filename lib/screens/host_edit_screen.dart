import 'package:flutter/material.dart';

import '../models/ssh_host.dart';
import '../services/host_store.dart';

class HostEditScreen extends StatefulWidget {
  const HostEditScreen({super.key, required this.store, this.existing});

  final HostStore store;
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
  final _password = TextEditingController();

  bool _saving = false;
  bool _obscurePassword = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _label = TextEditingController(text: h?.label ?? '');
    _host = TextEditingController(text: h?.host ?? '');
    _port = TextEditingController(text: (h?.port ?? 22).toString());
    _username = TextEditingController(text: h?.username ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final host = (widget.existing ??
            SshHost(
              label: '',
              host: '',
              username: '',
            ))
        .copyWith(
      label: _label.text.trim(),
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _username.text.trim(),
    );

    await widget.store.upsert(
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Host' : 'New Host'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: 'Label (optional)',
                hintText: 'My server',
              ),
            ),
            TextFormField(
              controller: _host,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: 'example.com or 192.168.1.10',
              ),
              autocorrect: false,
              keyboardType: TextInputType.url,
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
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText:
                    _isEditing ? 'Password (leave blank to keep)' : 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              autocorrect: false,
              enableSuggestions: false,
              validator: (v) {
                if (_isEditing) return null;
                return (v == null || v.isEmpty) ? 'Required' : null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
