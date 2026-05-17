import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A reusable command snippet that can be sent into a live session.
class Snippet {
  Snippet({
    String? id,
    required this.name,
    required this.command,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String name;
  final String command;

  Snippet copyWith({String? name, String? command}) => Snippet(
        id: id,
        name: name ?? this.name,
        command: command ?? this.command,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'command': command};

  factory Snippet.fromJson(Map<String, dynamic> json) => Snippet(
        id: json['id'] as String,
        name: json['name'] as String,
        command: json['command'] as String? ?? '',
      );
}
