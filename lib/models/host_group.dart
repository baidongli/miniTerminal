import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class HostGroup {
  HostGroup({String? id, required this.name}) : id = id ?? _uuid.v4();

  final String id;
  final String name;

  HostGroup copyWith({String? name}) =>
      HostGroup(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory HostGroup.fromJson(Map<String, dynamic> json) =>
      HostGroup(id: json['id'] as String, name: json['name'] as String);
}
