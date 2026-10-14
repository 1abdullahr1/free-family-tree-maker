import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/name_utils.dart';
import '../../models/family_tree.dart';
import '../database/app_database.dart';

class FamilyTreeRepository {
  FamilyTreeRepository({AppDatabase? database}) : _database = database ?? AppDatabase();

  final AppDatabase _database;
  final _changes = StreamController<void>.broadcast();
  final _uuid = const Uuid();

  AppDatabase get database => _database;

  Stream<List<FamilyTree>> watchTrees() async* {
    yield await listTrees();
    yield* _changes.stream.asyncMap((_) => listTrees());
  }

  Future<List<FamilyTree>> listTrees() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT
        t.id,
        t.name,
        t.created_at,
        t.updated_at,
        COUNT(p.id) AS person_count
      FROM family_trees t
      LEFT JOIN persons p ON p.tree_id = t.id
      GROUP BY t.id, t.name, t.created_at, t.updated_at
      ORDER BY datetime(t.updated_at) DESC, t.name COLLATE NOCASE ASC
    ''');
    return rows.map(FamilyTree.fromMap).toList();
  }

  Future<FamilyTree?> getTree(String id) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT
        t.id,
        t.name,
        t.created_at,
        t.updated_at,
        COUNT(p.id) AS person_count
      FROM family_trees t
      LEFT JOIN persons p ON p.tree_id = t.id
      WHERE t.id = ?
      GROUP BY t.id, t.name, t.created_at, t.updated_at
    ''', [id]);
    if (rows.isEmpty) return null;
    return FamilyTree.fromMap(rows.first);
  }

  Future<FamilyTree> createTree(String name) async {
    final normalized = normalizeTreeName(name);
    if (normalized.isEmpty) {
      throw ArgumentError('Tree name cannot be empty.');
    }

    final now = DateTime.now().toUtc();
    final tree = FamilyTree(
      id: _uuid.v4(),
      name: normalized,
      createdAt: now,
      updatedAt: now,
      personCount: 0,
    );

    final db = await _database.database;
    await db.insert(
      'family_trees',
      {
        'id': tree.id,
        'name': tree.name,
        'created_at': tree.createdAt.toIso8601String(),
        'updated_at': tree.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    _notifyChange();
    return tree;
  }

  Future<void> renameTree(String id, String name) async {
    final normalized = normalizeTreeName(name);
    if (normalized.isEmpty) {
      throw ArgumentError('Tree name cannot be empty.');
    }

    final db = await _database.database;
    await db.update(
      'family_trees',
      {
        'name': normalized,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyChange();
  }

  Future<void> deleteTree(String id) async {
    final db = await _database.database;
    await db.delete('family_trees', where: 'id = ?', whereArgs: [id]);
    _notifyChange();
  }

  void _notifyChange() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  Future<void> dispose() async {
    await _changes.close();
    await _database.close();
  }
}
