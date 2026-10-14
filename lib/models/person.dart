class Person {
  const Person({
    required this.id,
    required this.treeId,
    this.givenName,
    this.middleName,
    this.surname,
    this.nickname,
    this.gender,
    this.lifeStatus = 'unknown',
    this.birthYear,
    this.birthMonth,
    this.birthDay,
    this.birthPlace,
    this.deathYear,
    this.deathMonth,
    this.deathDay,
    this.deathPlace,
    this.biography,
    this.notes,
  });

  final String id;
  final String treeId;
  final String? givenName;
  final String? middleName;
  final String? surname;
  final String? nickname;
  final String? gender;
  final String lifeStatus;
  final int? birthYear;
  final int? birthMonth;
  final int? birthDay;
  final String? birthPlace;
  final int? deathYear;
  final int? deathMonth;
  final int? deathDay;
  final String? deathPlace;
  final String? biography;
  final String? notes;

  String get displayName {
    final parts = [givenName, middleName, surname]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Unknown person' : parts.join(' ');
  }

  String get initials => displayName
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  String get yearLabel {
    final birth = birthYear?.toString() ?? '?';
    final death = deathYear?.toString();
    if (death == null && birth == '?') return '';
    return death == null ? 'b. $birth' : '$birth – $death';
  }

  factory Person.fromMap(Map<String, Object?> map) {
    return Person(
      id: map['id'] as String,
      treeId: map['tree_id'] as String,
      givenName: map['given_name'] as String?,
      middleName: map['middle_name'] as String?,
      surname: map['surname'] as String?,
      nickname: map['nickname'] as String?,
      gender: map['gender'] as String?,
      lifeStatus: (map['life_status'] as String?) ?? 'unknown',
      birthYear: map['birth_year'] as int?,
      birthMonth: map['birth_month'] as int?,
      birthDay: map['birth_day'] as int?,
      birthPlace: map['birth_place'] as String?,
      deathYear: map['death_year'] as int?,
      deathMonth: map['death_month'] as int?,
      deathDay: map['death_day'] as int?,
      deathPlace: map['death_place'] as String?,
      biography: map['biography'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
