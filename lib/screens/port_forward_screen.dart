import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ssh_host.dart';
import '../ssh/port_forwarding.dart';
import '../ssh/ssh_connection.dart';
import '../state/app_repository.dart';

class PortForwardScreen extends StatefulWidget {
  const PortForwardScreen({super.key, required this.host});

  final SshHost host;

  @override
  State<PortForwardScreen> createState() => _PortForwardScreenState();
}

class _PortForwardScreenState extends State<PortForwardScreen> {
  Dialed? _dialed;
  PortForwardingService? _svc;
  bool _busy = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _svc?.dispose();
    _dialed?.closeAll();
    super.dispose();
  }

  Future<void> _connect() async {
    final repo = context.read<AppRepository>();
    try {
      final conn =
          SshConnection(hostStore: repo.hosts, keyStore: repo.keys);
      final hosts = await repo.hosts.loadHosts();
      final dialed = await conn.connect(widget.host, allHosts: hosts);
      _dialed = dialed;
      _svc = PortForwardingService(dialed.client);
      setState(() => _busy = false);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _addForward() async {
    final spec = await showModalBottomSheet<PortForward>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ForwardForm(),
    );
    if (spec != null && _svc != null) {
      await _svc!.start(spec);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Port forwarding')),
      floatingActionButton: _svc == null
          ? null
          : FloatingActionButton(
              onPressed: _addForward, child: const Icon(Icons.add)),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error,
                      style: const TextStyle(color: Colors.red)))
              : AnimatedBuilder(
                  animation: _svc!,
                  builder: (_, __) {
                    final active = _svc!.active;
                    if (active.isEmpty) {
                      return const Center(
                          child: Text('No forwards. Tap + to add.'));
                    }
                    return ListView(
                      children: active.map((a) {
                        return ListTile(
                          leading: Icon(a.error
                              ? Icons.error
                              : Icons.swap_horiz),
                          title: Text(a.spec.summary),
                          subtitle: a.error ? Text(a.message) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.stop_circle),
                            onPressed: () => _svc!.stop(a.spec.id),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
    );
  }
}

class _ForwardForm extends StatefulWidget {
  const _ForwardForm();

  @override
  State<_ForwardForm> createState() => _ForwardFormState();
}

class _ForwardFormState extends State<_ForwardForm> {
  ForwardKind _kind = ForwardKind.local;
  final _bind = TextEditingController(text: '8080');
  final _destHost = TextEditingController(text: '127.0.0.1');
  final _destPort = TextEditingController(text: '80');

  @override
  void dispose() {
    _bind.dispose();
    _destHost.dispose();
    _destPort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<ForwardKind>(
            segments: const [
              ButtonSegment(value: ForwardKind.local, label: Text('Local')),
              ButtonSegment(value: ForwardKind.remote, label: Text('Remote')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          TextField(
            controller: _bind,
            decoration: InputDecoration(
                labelText: _kind == ForwardKind.local
                    ? 'Local listen port'
                    : 'Remote listen port'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _destHost,
            decoration: const InputDecoration(labelText: 'Destination host'),
          ),
          TextField(
            controller: _destPort,
            decoration: const InputDecoration(labelText: 'Destination port'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final bind = int.tryParse(_bind.text.trim());
              final dport = int.tryParse(_destPort.text.trim());
              if (bind == null || dport == null) return;
              Navigator.pop(
                context,
                PortForward(
                  kind: _kind,
                  bindPort: bind,
                  destHost: _destHost.text.trim(),
                  destPort: dport,
                ),
              );
            },
            child: const Text('Start forward'),
          ),
        ],
      ),
    );
  }
}
