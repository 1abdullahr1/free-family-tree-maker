import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:free_family_tree_maker/data/database/app_database.dart';
import 'package:free_family_tree_maker/data/repositories/family_tree_repository.dart';
import 'package:free_family_tree_maker/data/repositories/person_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('persists relationships and rejects invalid links', () async {
    final tempDir = await Directory.systemTemp.createTemp('person_repository_test');
    final database = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePathProvider: () async => tempDir.path,
    );
    final trees = FamilyTreeRepository(database: database);
    final people = PersonRepository(database: database);
    final tree = await trees.createTree('Family');
    final parent = await people.create(treeId: tree.id, givenName: 'Parent');
    final child = await people.create(treeId: tree.id, givenName: 'Child');
    final partner = await people.create(treeId: tree.id, givenName: 'Partner');

    await people.addParentChild(treeId: tree.id, parentId: parent.id, childId: child.id);
    expect((await people.parentsOfPeople(child.id)).single.displayName, 'Parent');
    expect((await people.childrenOfPeople(parent.id)).single.displayName, 'Child');
    await expectLater(
      people.addParentChild(treeId: tree.id, parentId: parent.id, childId: child.id),
      throwsA(isA<RelationshipException>()),
    );
    await expectLater(
      people.addParentChild(treeId: tree.id, parentId: child.id, childId: parent.id),
      throwsA(isA<RelationshipException>()),
    );
    await expectLater(
      people.addParentChild(treeId: tree.id, parentId: parent.id, childId: parent.id),
      throwsA(isA<RelationshipException>()),
    );

    await people.addPartner(treeId: tree.id, personAId: parent.id, personBId: partner.id);
    expect((await people.partnersOf(partner.id)).single.displayName, 'Parent');
    await expectLater(
      people.addPartner(treeId: tree.id, personAId: partner.id, personBId: parent.id),
      throwsA(isA<RelationshipException>()),
    );

    await people.dispose();
    await trees.dispose();
    await tempDir.delete(recursive: true);
  });
}
