import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum SshAuthType { password, key }

/// A saved SSH host. Secrets (password / key passphrase) are never stored in
/// this object; they live in the platform secure storage keyed by [id].
class SshHost {
  SshHost({
    String? id,
    required this.label,
    required this.host,
    this.port = 22,
    required this.username,
    this.authType = SshAuthType.password,
    this.keyId,
    this.groupId,
    this.jumpHostId,
    this.startupCommand = '',
    this.keepAliveSeconds = 0,
    this.compactPrompt = false,
    List<String>? tags,
  })  : id = id ?? _uuid.v4(),
        tags = tags ?? const [];

  final String id;
  final String label;
  final String host;
  final int port;
  final String username;
  final SshAuthType authType;

  /// Id of the [SshKey] used when [authType] is [SshAuthType.key].
  final String? keyId;

  /// Optional group/folder id.
  final String? groupId;

  /// Optional id of another host to use as a jump/bastion host.
  final String? jumpHostId;

  /// Command run automatically right after the shell opens.
  final String startupCommand;

  /// Server keep-alive interval in seconds (0 = disabled).
  final int keepAliveSeconds;

  /// When true, inject a short PS1 on connect so a long server hostname
  /// doesn't eat the command line.
  final bool compactPrompt;

  final List<String> tags;

  String get displayName => label.trim().isEmpty ? '$username@$host' : label;
  String get endpoint => '$username@$host:$port';

  SshHost copyWith({
    String? label,
    String? host,
    int? port,
    String? username,
    SshAuthType? authType,
    String? keyId,
    bool clearKeyId = false,
    String? groupId,
    bool clearGroupId = false,
    String? jumpHostId,
    bool clearJumpHostId = false,
    String? startupCommand,
    int? keepAliveSeconds,
    bool? compactPrompt,
    List<String>? tags,
  }) {
    return SshHost(
      id: id,
      label: label ?? this.label,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      keyId: clearKeyId ? null : (keyId ?? this.keyId),
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      jumpHostId: clearJumpHostId ? null : (jumpHostId ?? this.jumpHostId),
      startupCommand: startupCommand ?? this.startupCommand,
      keepAliveSeconds: keepAliveSeconds ?? this.keepAliveSeconds,
      compactPrompt: compactPrompt ?? this.compactPrompt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'host': host,
        'port': port,
        'username': username,
        'authType': authType.name,
        'keyId': keyId,
        'groupId': groupId,
        'jumpHostId': jumpHostId,
        'startupCommand': startupCommand,
        'keepAliveSeconds': keepAliveSeconds,
        'compactPrompt': compactPrompt,
        'tags': tags,
      };

  factory SshHost.fromJson(Map<String, dynamic> json) => SshHost(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        host: json['host'] as String,
        port: (json['port'] as num?)?.toInt() ?? 22,
        username: json['username'] as String,
        authType: SshAuthType.values.firstWhere(
          (e) => e.name == json['authType'],
          orElse: () => SshAuthType.password,
        ),
        keyId: json['keyId'] as String?,
        groupId: json['groupId'] as String?,
        jumpHostId: json['jumpHostId'] as String?,
        startupCommand: json['startupCommand'] as String? ?? '',
        keepAliveSeconds: (json['keepAliveSeconds'] as num?)?.toInt() ?? 0,
        compactPrompt: json['compactPrompt'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
