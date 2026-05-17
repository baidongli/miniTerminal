import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class GeneratedKey {
  GeneratedKey({required this.privateKeyOpenSsh, required this.publicKeyLine});

  /// Unencrypted OpenSSH-format private key (-----BEGIN OPENSSH PRIVATE KEY---).
  final String privateKeyOpenSsh;

  /// Single-line "ssh-ed25519 AAAA... comment" public key.
  final String publicKeyLine;
}

/// Generates an unencrypted ed25519 keypair encoded in the OpenSSH formats
/// understood by `dartssh2`'s `SSHKeyPair.fromPem` and `authorized_keys`.
class KeyGen {
  static Future<GeneratedKey> ed25519({String comment = 'miniterminal'}) async {
    final algorithm = Ed25519();
    final pair = await algorithm.newKeyPair();
    final priv = Uint8List.fromList(await pair.extractPrivateKeyBytes());
    final pub =
        Uint8List.fromList((await pair.extractPublicKey()).bytes);

    final pubBlob = _builder()
      ..addAll(_sshString(ascii.encode('ssh-ed25519')))
      ..addAll(_sshString(pub));
    final pubBlobBytes = pubBlob.toBytes();

    final publicLine =
        'ssh-ed25519 ${base64.encode(pubBlobBytes)} $comment';

    // 64-byte private = 32 seed + 32 public (OpenSSH convention).
    final priv64 = Uint8List(64)
      ..setRange(0, 32, priv)
      ..setRange(32, 64, pub);

    const checkint = 0x12345678;
    final unpadded = _builder()
      ..addAll(_uint32(checkint))
      ..addAll(_uint32(checkint))
      ..addAll(_sshString(ascii.encode('ssh-ed25519')))
      ..addAll(_sshString(pub))
      ..addAll(_sshString(priv64))
      ..addAll(_sshString(ascii.encode(comment)));
    final privSection = unpadded.toBytes();
    final padded = _padTo8(privSection);

    final body = _builder()
      ..addAll(ascii.encode('openssh-key-v1'))
      ..add(0)
      ..addAll(_sshString(ascii.encode('none'))) // ciphername
      ..addAll(_sshString(ascii.encode('none'))) // kdfname
      ..addAll(_sshString(Uint8List(0))) // kdfoptions
      ..addAll(_uint32(1)) // number of keys
      ..addAll(_sshString(pubBlobBytes)) // public key
      ..addAll(_sshString(padded)); // private section

    final b64 = base64.encode(body.toBytes());
    final wrapped = StringBuffer('-----BEGIN OPENSSH PRIVATE KEY-----\n');
    for (var i = 0; i < b64.length; i += 70) {
      wrapped.writeln(
          b64.substring(i, i + 70 > b64.length ? b64.length : i + 70));
    }
    wrapped.write('-----END OPENSSH PRIVATE KEY-----\n');

    return GeneratedKey(
      privateKeyOpenSsh: wrapped.toString(),
      publicKeyLine: publicLine,
    );
  }

  static BytesBuilder _builder() => BytesBuilder(copy: false);

  static Uint8List _uint32(int v) {
    final b = ByteData(4)..setUint32(0, v, Endian.big);
    return b.buffer.asUint8List();
  }

  static Uint8List _sshString(List<int> data) {
    final out = Uint8List(4 + data.length);
    out.setRange(0, 4, _uint32(data.length));
    out.setRange(4, out.length, data);
    return out;
  }

  static Uint8List _padTo8(Uint8List data) {
    final pad = (8 - (data.length % 8)) % 8;
    if (pad == 0) return data;
    final out = Uint8List(data.length + pad);
    out.setRange(0, data.length, data);
    for (var i = 0; i < pad; i++) {
      out[data.length + i] = i + 1;
    }
    return out;
  }
}
