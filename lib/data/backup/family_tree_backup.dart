import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

class FamilyTreeBackupException implements Exception {
  const FamilyTreeBackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FamilyTreeBackup {
  FamilyTreeBackup({required this.database});
  final AppDatabase database;
  final _uuid = const Uuid();

  Future<String> exportTree(String treeId) async {
    final db = await database.database;
    final trees = await db.query('family_trees', where: 'id = ?', whereArgs: [treeId], limit: 1);
    if (trees.isEmpty) throw const FamilyTreeBackupException('Family tree not found.');
    final persons = await db.query('persons', where: 'tree_id = ?', whereArgs: [treeId]);
    final parentChild = await db.query('parent_child_relations', where: 'tree_id = ?', whereArgs: [treeId]);
    final partners = await db.query('partner_relations', where: 'tree_id = ?', whereArgs: [treeId]);
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'free-family-tree-maker',
      'version': 1,
      'tree': trees.single,
      'persons': persons,
      'parent_child_relations': parentChild,
      'partner_relations': partners,
    });
  }

  Future<String> restoreTree(String backupJson) async {
    final decoded = _decode(backupJson);
    final tree = _map(decoded['tree'], 'tree');
    _string(tree['id'], 'tree.id');
    final persons = _list(decoded['persons'], 'persons');
    final parentChild = _list(decoded['parent_child_relations'], 'parent_child_relations');
    final partners = _list(decoded['partner_relations'], 'partner_relations');
    final newTreeId = _uuid.v4();
    final personIds = <String, String>{};
    for (final person in persons) {
      final sourceId = _string(person['id'], 'persons.id');
      personIds[sourceId] = _uuid.v4();
    }
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.insert('family_trees', {
        ...tree,
        'id': newTreeId,
        'name': '${_string(tree['name'], 'tree.name')} (Imported)',
      });
      for (final person in persons) {
        final sourceId = _string(person['id'], 'persons.id');
        await txn.insert('persons', {
          ...person,
          'id': personIds[sourceId],
          'tree_id': newTreeId,
        });
      }
      for (final relation in parentChild) {
        final parentId = personIds[relation['parent_person_id']];
        final childId = personIds[relation['child_person_id']];
        if (parentId == null || childId == null) throw const FamilyTreeBackupException('Backup contains an unknown parent-child person.');
        await txn.insert('parent_child_relations', {
          ...relation,
          'id': _uuid.v4(),
          'tree_id': newTreeId,
          'parent_person_id': parentId,
          'child_person_id': childId,
        });
      }
      for (final relation in partners) {
        final firstId = personIds[relation['person_a_id']];
        final secondId = personIds[relation['person_b_id']];
        if (firstId == null || secondId == null) throw const FamilyTreeBackupException('Backup contains an unknown partner person.');
        await txn.insert('partner_relations', {
          ...relation,
          'id': _uuid.v4(),
          'tree_id': newTreeId,
          'person_a_id': firstId,
          'person_b_id': secondId,
        });
      }
    });
    return newTreeId;
  }

  Map<String, dynamic> _decode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic> ||
          decoded['format'] != 'free-family-tree-maker' ||
          decoded['version'] != 1) {
        throw const FamilyTreeBackupException('Unsupported backup format.');
      }
      return decoded;
    } on FormatException {
      throw const FamilyTreeBackupException('Backup is not valid JSON.');
    }
  }

  Map<String, dynamic> _map(Object? value, String field) {
    if (value is Map<String, dynamic>) return value;
    throw FamilyTreeBackupException('Backup field "$field" is invalid.');
  }

  List<Map<String, dynamic>> _list(Object? value, String field) {
    if (value is List) {
      return value.map((item) => _map(item, field)).toList();
    }
    throw FamilyTreeBackupException('Backup field "$field" is invalid.');
  }

  String _string(Object? value, String field) {
    if (value is String && value.trim().isNotEmpty) return value;
    throw FamilyTreeBackupException('Backup field "$field" is invalid.');
  }
}
