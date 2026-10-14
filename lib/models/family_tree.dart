class FamilyTree {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int personCount;

  const FamilyTree({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.personCount,
  });

  FamilyTree copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? personCount,
  }) {
    return FamilyTree(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      personCount: personCount ?? this.personCount,
    );
  }

  factory FamilyTree.fromMap(Map<String, Object?> map) {
    return FamilyTree(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      personCount: (map['person_count'] as int?) ?? 0,
    );
  }
}
