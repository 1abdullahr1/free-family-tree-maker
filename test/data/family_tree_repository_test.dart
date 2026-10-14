import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:free_family_tree_maker/data/database/app_database.dart';
import 'package:free_family_tree_maker/data/repositories/family_tree_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('create, rename, and delete tree persists data', () async {
    final tempDir = await Directory.systemTemp.createTemp('family_tree_test');
    final database = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePathProvider: () async => tempDir.path,
    );
    final repository = FamilyTreeRepository(database: database);

    final created = await repository.createTree('  My Family  ');
    expect(created.name, 'My Family');

    final treesAfterCreate = await repository.listTrees();
    expect(treesAfterCreate, hasLength(1));
    expect(treesAfterCreate.single.name, 'My Family');

    await repository.renameTree(created.id, 'The Renamed Tree');
    final treesAfterRename = await repository.listTrees();
    expect(treesAfterRename.single.name, 'The Renamed Tree');

    await repository.deleteTree(created.id);
    final treesAfterDelete = await repository.listTrees();
    expect(treesAfterDelete, isEmpty);

    await repository.dispose();
    await tempDir.delete(recursive: true);
  });

  test('rejects blank tree names', () async {
    final tempDir = await Directory.systemTemp.createTemp('family_tree_test');
    final database = AppDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePathProvider: () async => tempDir.path,
    );
    final repository = FamilyTreeRepository(database: database);

    expect(() => repository.createTree('   '), throwsArgumentError);

    await repository.dispose();
    await tempDir.delete(recursive: true);
  });
}
