import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:free_family_tree_maker/data/backup/family_tree_backup.dart';
import 'package:free_family_tree_maker/data/database/app_database.dart';
import 'package:free_family_tree_maker/data/repositories/family_tree_repository.dart';
import 'package:free_family_tree_maker/data/repositories/person_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('exports and restores a tree with relationships', () async {
    final tempDir = await Directory.systemTemp.createTemp('family_tree_backup_test');
    final database = AppDatabase(databaseFactory: databaseFactoryFfi, databasePathProvider: () async => tempDir.path);
    final trees = FamilyTreeRepository(database: database);
    final people = PersonRepository(database: database);
    final backup = FamilyTreeBackup(database: database);
    final tree = await trees.createTree('Original');
    final parent = await people.create(treeId: tree.id, givenName: 'Parent');
    final child = await people.create(treeId: tree.id, givenName: 'Child');
    await people.addParentChild(treeId: tree.id, parentId: parent.id, childId: child.id);

    final restoredId = await backup.restoreTree(await backup.exportTree(tree.id));
    final restoredTrees = await trees.listTrees();
    final restored = restoredTrees.singleWhere((item) => item.id == restoredId);
    expect(restored.name, 'Original (Imported)');
    final restoredPeople = await people.listPeople(restoredId);
    expect(restoredPeople, hasLength(2));
    final restoredChild = restoredPeople.singleWhere((item) => item.displayName == 'Child');
    expect((await people.parentsOfPeople(restoredChild.id)).single.displayName, 'Parent');

    await people.dispose();
    await trees.dispose();
    await tempDir.delete(recursive: true);
  });

  test('rejects malformed backup without writing data', () async {
    final tempDir = await Directory.systemTemp.createTemp('family_tree_backup_test');
    final database = AppDatabase(databaseFactory: databaseFactoryFfi, databasePathProvider: () async => tempDir.path);
    final trees = FamilyTreeRepository(database: database);
    final backup = FamilyTreeBackup(database: database);

    await expectLater(backup.restoreTree('not json'), throwsA(isA<FamilyTreeBackupException>()));
    await expectLater(
      backup.restoreTree(jsonEncode({'format': 'wrong', 'version': 1})),
      throwsA(isA<FamilyTreeBackupException>()),
    );
    expect(await trees.listTrees(), isEmpty);

    await trees.dispose();
    await tempDir.delete(recursive: true);
  });
}
