import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Metadata for a stored SSH private key. The private key PEM and its
/// optional passphrase live in secure storage keyed by [id]; only the
/// public key and metadata are kept here.
class SshKey {
  SshKey({
    String? id,
    required this.name,
    required this.type,
    required this.publicKey,
    this.hasPassphrase = false,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String name;

  /// e.g. "ed25519", "rsa", "imported".
  final String type;

  /// OpenSSH-format public key line (may be empty for some imports).
  final String publicKey;

  final bool hasPassphrase;

  SshKey copyWith({
    String? name,
    String? type,
    String? publicKey,
    bool? hasPassphrase,
  }) =>
      SshKey(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        publicKey: publicKey ?? this.publicKey,
        hasPassphrase: hasPassphrase ?? this.hasPassphrase,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'publicKey': publicKey,
        'hasPassphrase': hasPassphrase,
      };

  factory SshKey.fromJson(Map<String, dynamic> json) => SshKey(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String? ?? 'imported',
        publicKey: json['publicKey'] as String? ?? '',
        hasPassphrase: json['hasPassphrase'] as bool? ?? false,
      );
}
