class Town {
  final int id;
  final String name;

  Town({required this.id, required this.name});

  @override
  String toString() => 'Town{id: $id, name: $name}';

  factory Town.fromJson(Map json) => Town(id: json['id'], name: json['nam']);

  Map<String, dynamic> toJson() => {'id': id, 'nam': name};
}
