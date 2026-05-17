import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../models/ssh_host.dart';
import '../services/host_store.dart';
import '../services/key_store.dart';
import '../services/known_hosts_store.dart';

/// Resolves a [SshHost] (with optional key auth and jump host) into a live
/// [SSHClient]. Throws on failure; callers handle the error.
class SshConnection {
  SshConnection({
    required this.hostStore,
    required this.keyStore,
    required this.knownHosts,
  });

  final HostStore hostStore;
  final KeyStore keyStore;
  final KnownHostsStore knownHosts;

  /// Builds an authenticated client for [host]. If [host.jumpHostId] is set,
  /// [allHosts] must contain the jump host so it can be dialed first.
  Future<_Dialed> connect(
    SshHost host, {
    required List<SshHost> allHosts,
  }) async {
    final clients = <SSHClient>[];
    try {
      SSHSocket socket;
      if (host.jumpHostId != null) {
        final jump = allHosts.firstWhere(
          (h) => h.id == host.jumpHostId,
          orElse: () => throw const _ConnError('Jump host not found.'),
        );
        final jumpClient = await _client(
          jump,
          await SSHSocket.connect(jump.host, jump.port,
              timeout: const Duration(seconds: 15)),
        );
        clients.add(jumpClient);
        socket = await jumpClient.forwardLocal(host.host, host.port);
      } else {
        socket = await SSHSocket.connect(host.host, host.port,
            timeout: const Duration(seconds: 15));
      }

      final client = await _client(host, socket);
      clients.add(client);
      return _Dialed(client, clients);
    } catch (_) {
      for (final c in clients.reversed) {
        c.close();
      }
      rethrow;
    }
  }

  /// Trust-on-first-use host key check. First sighting is trusted and
  /// stored; a later mismatch is rejected (possible MITM).
  Future<bool> _verifyHostKey(
    SshHost host,
    String type,
    List<int> fingerprint,
  ) async {
    final fp = fingerprint
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':');
    final current = '$type $fp';
    final known = await knownHosts.fingerprintFor(host.host, host.port);
    if (known == null) {
      await knownHosts.trust(host.host, host.port, current);
      return true;
    }
    return known == current;
  }

  Future<SSHClient> _client(SshHost host, SSHSocket socket) async {
    Future<bool> verify(String type, Uint8List fp) =>
        _verifyHostKey(host, type, fp);
    final keepAlive = host.keepAliveSeconds > 0
        ? Duration(seconds: host.keepAliveSeconds)
        : const Duration(seconds: 15);

    if (host.authType == SshAuthType.key) {
      final keyId = host.keyId;
      if (keyId == null) {
        throw const _ConnError('No key selected for this host.');
      }
      final pem = await keyStore.readPem(keyId);
      if (pem == null || pem.isEmpty) {
        throw const _ConnError('Stored private key is missing.');
      }
      final passphrase = await keyStore.readPassphrase(keyId);
      final identities = SSHKeyPair.fromPem(pem, passphrase);
      return SSHClient(
        socket,
        username: host.username,
        identities: identities,
        onVerifyHostKey: verify,
        keepAliveInterval: keepAlive,
      );
    }

    final password = await hostStore.readPassword(host.id);
    if (password == null || password.isEmpty) {
      throw const _ConnError('No saved password for this host.');
    }
    return SSHClient(
      socket,
      username: host.username,
      onPasswordRequest: () => password,
      onVerifyHostKey: verify,
      keepAliveInterval: keepAlive,
    );
  }
}

class _Dialed {
  _Dialed(this.client, this.chain);

  /// The final client to open a shell/SFTP on.
  final SSHClient client;

  /// All clients in dial order (jump first); close in reverse on teardown.
  final List<SSHClient> chain;

  void closeAll() {
    for (final c in chain.reversed) {
      c.close();
    }
  }
}

class _ConnError implements Exception {
  const _ConnError(this.message);
  final String message;
  @override
  String toString() => message;
}

typedef Dialed = _Dialed;
