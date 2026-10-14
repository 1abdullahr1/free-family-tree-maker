import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../models/person.dart';
import '../../core/tree_layout.dart';
import '../database/app_database.dart';

class RelationshipException implements Exception {
  const RelationshipException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PersonRepository {
  PersonRepository({required this.database});
  final AppDatabase database;
  final _uuid = const Uuid();
  final _changes = StreamController<void>.broadcast();

  Stream<List<Person>> watchPeople(String treeId) async* {
    yield await listPeople(treeId);
    yield* _changes.stream.asyncMap((_) => listPeople(treeId));
  }

  Future<List<Person>> listPeople(String treeId) async {
    final db = await database.database;
    final rows = await db.query('persons', where: 'tree_id = ?', whereArgs: [treeId], orderBy: 'surname COLLATE NOCASE, given_name COLLATE NOCASE');
    return rows.map(Person.fromMap).toList();
  }

  Future<Person?> getPerson(String id) async {
    final db = await database.database;
    final rows = await db.query('persons', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Person.fromMap(rows.first);
  }

  Future<Person> create({
    required String treeId,
    required String givenName,
    String? middleName,
    String? surname,
    String? nickname,
    String? gender,
    String lifeStatus = 'unknown',
    int? birthYear,
    int? birthMonth,
    int? birthDay,
    String? birthPlace,
    int? deathYear,
    int? deathMonth,
    int? deathDay,
    String? deathPlace,
    String? biography,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final values = <String, Object?>{
      'id': id,
      'tree_id': treeId,
      'given_name': givenName.trim().isEmpty ? null : givenName.trim(),
      'middle_name': _clean(middleName),
      'surname': _clean(surname),
      'nickname': _clean(nickname),
      'gender': gender,
      'life_status': lifeStatus,
      'birth_year': birthYear,
      'birth_month': birthMonth,
      'birth_day': birthDay,
      'birth_place': _clean(birthPlace),
      'death_year': deathYear,
      'death_month': deathMonth,
      'death_day': deathDay,
      'death_place': _clean(deathPlace),
      'biography': _clean(biography),
      'notes': _clean(notes),
      'created_at': now,
      'updated_at': now,
    };
    if ((values['given_name'] == null) && (values['surname'] == null)) {
      throw ArgumentError('Enter a given name or surname.');
    }
    if (birthYear != null && deathYear != null && deathYear < birthYear) {
      throw ArgumentError('Death year cannot be earlier than birth year.');
    }
    final db = await database.database;
    await db.insert('persons', values);
    _notify();
    return (await getPerson(id))!;
  }

  Future<Person> update({
    required String id,
    required String givenName,
    String? middleName,
    String? surname,
    String? nickname,
    String? gender,
    String lifeStatus = 'unknown',
    int? birthYear,
    int? birthMonth,
    int? birthDay,
    String? birthPlace,
    int? deathYear,
    int? deathMonth,
    int? deathDay,
    String? deathPlace,
    String? biography,
    String? notes,
  }) async {
    final cleanGiven = _clean(givenName);
    final cleanSurname = _clean(surname);
    if (cleanGiven == null && cleanSurname == null) throw ArgumentError('Enter a given name or surname.');
    if (birthYear != null && deathYear != null && deathYear < birthYear) throw ArgumentError('Death year cannot be earlier than birth year.');
    final db = await database.database;
    await db.update('persons', {
      'given_name': cleanGiven, 'middle_name': _clean(middleName), 'surname': cleanSurname,
      'nickname': _clean(nickname), 'gender': gender, 'life_status': lifeStatus,
      'birth_year': birthYear, 'birth_month': birthMonth, 'birth_day': birthDay,
      'birth_place': _clean(birthPlace), 'death_year': deathYear, 'death_month': deathMonth,
      'death_day': deathDay, 'death_place': _clean(deathPlace), 'biography': _clean(biography),
      'notes': _clean(notes), 'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
    _notify();
    return (await getPerson(id))!;
  }

  Future<void> addParentChild({
    required String treeId,
    required String parentId,
    required String childId,
    String parentageType = 'unknown',
  }) async {
    if (parentId == childId) throw const RelationshipException('A person cannot be their own parent.');
    final db = await database.database;
    final people = await db.query('persons', columns: ['id', 'tree_id'], where: 'id IN (?, ?)', whereArgs: [parentId, childId]);
    if (people.length != 2 || people.any((row) => row['tree_id'] != treeId)) {
      throw const RelationshipException('Both people must belong to this family tree.');
    }

    final duplicate = await db.query('parent_child_relations', where: 'tree_id = ? AND parent_person_id = ? AND child_person_id = ?', whereArgs: [treeId, parentId, childId], limit: 1);
    if (duplicate.isNotEmpty) throw const RelationshipException('That parent-child relationship already exists.');
    if (await _wouldCreateCycle(db, parentId, childId)) {
      throw const RelationshipException('That relationship would create an ancestor cycle.');
    }
    await db.insert('parent_child_relations', {
      'id': _uuid.v4(),
      'tree_id': treeId,
      'parent_person_id': parentId,
      'child_person_id': childId,
      'parentage_type': parentageType,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await db.update('family_trees', {'updated_at': DateTime.now().toUtc().toIso8601String()}, where: 'id = ?', whereArgs: [treeId]);
    _notify();
  }

  Future<List<String>> parentsOf(String personId) async {
    final db = await database.database;
    final rows = await db.query('parent_child_relations', columns: ['parent_person_id'], where: 'child_person_id = ?', whereArgs: [personId]);
    return rows.map((row) => row['parent_person_id'] as String).toList();
  }

  Future<List<String>> childrenOf(String personId) async {
    final db = await database.database;
    final rows = await db.query('parent_child_relations', columns: ['child_person_id'], where: 'parent_person_id = ?', whereArgs: [personId]);
    return rows.map((row) => row['child_person_id'] as String).toList();
  }

  Future<List<Person>> parentsOfPeople(String personId) async {
    return _peopleByIds(await parentsOf(personId));
  }

  Future<List<Person>> childrenOfPeople(String personId) async {
    return _peopleByIds(await childrenOf(personId));
  }

  Future<List<PersonRelation>> parentChildRelations(String treeId) async {
    final db = await database.database;
    final rows = await db.query(
      'parent_child_relations',
      columns: ['parent_person_id', 'child_person_id'],
      where: 'tree_id = ?',
      whereArgs: [treeId],
    );
    return rows
        .map((row) => PersonRelation(
              firstId: row['parent_person_id'] as String,
              secondId: row['child_person_id'] as String,
            ))
        .toList();
  }

  Future<List<PersonRelation>> partnerRelations(String treeId) async {
    final db = await database.database;
    final rows = await db.query(
      'partner_relations',
      columns: ['person_a_id', 'person_b_id'],
      where: 'tree_id = ?',
      whereArgs: [treeId],
    );
    return rows
        .map((row) => PersonRelation(
              firstId: row['person_a_id'] as String,
              secondId: row['person_b_id'] as String,
            ))
        .toList();
  }

  Future<List<Person>> partnersOf(String personId) async {
    final db = await database.database;
    final rows = await db.query(
      'partner_relations',
      where: 'person_a_id = ? OR person_b_id = ?',
      whereArgs: [personId, personId],
    );
    final ids = rows.map((row) {
      final first = row['person_a_id'] as String;
      final second = row['person_b_id'] as String;
      return first == personId ? second : first;
    }).toList();
    return _peopleByIds(ids);
  }

  Future<void> addPartner({
    required String treeId,
    required String personAId,
    required String personBId,
    String partnershipType = 'partner',
    String status = 'unknown',
  }) async {
    if (personAId == personBId) {
      throw const RelationshipException('A person cannot be their own partner.');
    }
    final db = await database.database;
    final people = await db.query(
      'persons',
      columns: ['id', 'tree_id'],
      where: 'id IN (?, ?)',
      whereArgs: [personAId, personBId],
    );
    if (people.length != 2 || people.any((row) => row['tree_id'] != treeId)) {
      throw const RelationshipException('Both people must belong to this family tree.');
    }
    final duplicate = await db.query(
      'partner_relations',
      where: '''tree_id = ? AND
          ((person_a_id = ? AND person_b_id = ?) OR
           (person_a_id = ? AND person_b_id = ?))''',
      whereArgs: [treeId, personAId, personBId, personBId, personAId],
      limit: 1,
    );
    if (duplicate.isNotEmpty) {
      throw const RelationshipException('That partner relationship already exists.');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert('partner_relations', {
      'id': _uuid.v4(),
      'tree_id': treeId,
      'person_a_id': personAId,
      'person_b_id': personBId,
      'partnership_type': partnershipType,
      'status': status,
      'created_at': now,
      'updated_at': now,
    });
    await db.update('family_trees', {'updated_at': now}, where: 'id = ?', whereArgs: [treeId]);
    _notify();
  }

  Future<List<Person>> search(String treeId, String query) async {
    final people = await listPeople(treeId);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return people;
    return people.where((person) => '${person.displayName} ${person.nickname ?? ''}'.toLowerCase().contains(q)).toList();
  }

  Future<void> delete(String id) async {
    final db = await database.database;
    await db.delete('persons', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  Future<bool> _wouldCreateCycle(Database db, String parentId, String childId) async {
    final pending = <String>[parentId];
    final visited = <String>{};
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!visited.add(current)) continue;
      if (current == childId) return true;
      final rows = await db.query('parent_child_relations', columns: ['parent_person_id'], where: 'child_person_id = ?', whereArgs: [current]);
      pending.addAll(rows.map((row) => row['parent_person_id'] as String));
    }
    return false;
  }

  String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> dispose() async {
    await _changes.close();
  }

  Future<List<Person>> _peopleByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final db = await database.database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.query(
      'persons',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    final people = rows.map(Person.fromMap).toList();
    final byId = {for (final person in people) person.id: person};
    return ids.map((id) => byId[id]).whereType<Person>().toList();
  }
}
