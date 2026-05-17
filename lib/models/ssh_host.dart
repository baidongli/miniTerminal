import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A saved SSH host. The password is never stored in this object; it lives
/// in the platform secure storage keyed by [id].
class SshHost {
  SshHost({
    String? id,
    required this.label,
    required this.host,
    this.port = 22,
    required this.username,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String label;
  final String host;
  final int port;
  final String username;

  String get displayName => label.trim().isEmpty ? '$username@$host' : label;

  SshHost copyWith({
    String? label,
    String? host,
    int? port,
    String? username,
  }) {
    return SshHost(
      id: id,
      label: label ?? this.label,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'host': host,
        'port': port,
        'username': username,
      };

  factory SshHost.fromJson(Map<String, dynamic> json) => SshHost(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        host: json['host'] as String,
        port: (json['port'] as num?)?.toInt() ?? 22,
        username: json['username'] as String,
      );
}
