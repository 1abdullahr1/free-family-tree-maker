class Person {
  final int? id;
  final String name;
  final String? birthYear;
  final int? parentId; // simple parent link to build a tree

  Person({this.id, required this.name, this.birthYear, this.parentId});

  Person copyWith({int? id, String? name, String? birthYear, int? parentId}) =>
      Person(
        id: id ?? this.id,
        name: name ?? this.name,
        birthYear: birthYear ?? this.birthYear,
        parentId: parentId ?? this.parentId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'birthYear': birthYear,
        'parentId': parentId,
      };

  factory Person.fromMap(Map<String, dynamic> m) => Person(
        id: m['id'] as int?,
        name: m['name'] as String,
        birthYear: m['birthYear'] as String?,
        parentId: m['parentId'] as int?,
      );
}
