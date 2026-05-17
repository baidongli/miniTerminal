import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum ForwardKind { local, remote }

class PortForward {
  PortForward({
    String? id,
    required this.kind,
    required this.bindPort,
    required this.destHost,
    required this.destPort,
  }) : id = id ?? _uuid.v4();

  final String id;
  final ForwardKind kind;

  /// For local: local port to listen on. For remote: remote port to open.
  final int bindPort;
  final String destHost;
  final int destPort;

  String get summary => kind == ForwardKind.local
      ? 'L 127.0.0.1:$bindPort → $destHost:$destPort'
      : 'R *:$bindPort → $destHost:$destPort';
}

class ActiveForward {
  ActiveForward(this.spec);
  final PortForward spec;
  ServerSocket? _server;
  StreamSubscription? _remoteSub;
  bool error = false;
  String message = '';

  Future<void> stop() async {
    await _server?.close();
    await _remoteSub?.cancel();
    _server = null;
    _remoteSub = null;
  }
}

/// Manages active port forwards bound to a single live [SSHClient].
class PortForwardingService extends ChangeNotifier {
  PortForwardingService(this._client);

  final SSHClient _client;
  final List<ActiveForward> active = [];

  Future<ActiveForward> start(PortForward spec) async {
    final af = ActiveForward(spec);
    active.add(af);
    notifyListeners();
    try {
      if (spec.kind == ForwardKind.local) {
        final server = await ServerSocket.bind(
            InternetAddress.loopbackIPv4, spec.bindPort);
        af._server = server;
        server.listen((socket) async {
          try {
            final ch =
                await _client.forwardLocal(spec.destHost, spec.destPort);
            _pipe(ch, socket);
          } catch (_) {
            socket.destroy();
          }
        });
      } else {
        final forward = await _client.forwardRemote(port: spec.bindPort);
        if (forward == null) {
          throw Exception('Server rejected remote forward request.');
        }
        af._remoteSub = forward.connections.listen((ch) async {
          try {
            final socket =
                await Socket.connect(spec.destHost, spec.destPort);
            _pipe(ch, socket);
          } catch (_) {
            ch.close();
          }
        });
      }
    } catch (e) {
      af.error = true;
      af.message = e.toString();
    }
    notifyListeners();
    return af;
  }

  void _pipe(SSHForwardChannel ch, Socket socket) {
    ch.stream.listen(
      socket.add,
      onDone: socket.destroy,
      onError: (_) => socket.destroy(),
    );
    socket.listen(
      ch.sink.add,
      onDone: ch.sink.close,
      onError: (_) => ch.sink.close(),
    );
  }

  Future<void> stop(String id) async {
    final i = active.indexWhere((a) => a.spec.id == id);
    if (i < 0) return;
    await active[i].stop();
    active.removeAt(i);
    notifyListeners();
  }

  Future<void> stopAll() async {
    for (final a in active) {
      await a.stop();
    }
    active.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopAll();
    super.dispose();
  }
}
