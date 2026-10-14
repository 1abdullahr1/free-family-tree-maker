import 'package:flutter_test/flutter_test.dart';

import 'package:free_family_tree_maker/core/tree_layout.dart';
import 'package:free_family_tree_maker/models/person.dart';

void main() {
  test('lays out generations deterministically and includes relationship edges', () {
    const parent = Person(id: 'parent', treeId: 'tree', givenName: 'Ada');
    const child = Person(id: 'child', treeId: 'tree', givenName: 'Bert');
    const partner = Person(id: 'partner', treeId: 'tree', givenName: 'Cara');
    const service = TreeLayoutService();

    final layout = service.layout(
      people: [child, partner, parent],
      parentChildRelations: const [PersonRelation(firstId: 'parent', secondId: 'child')],
      partnerRelations: const [PersonRelation(firstId: 'child', secondId: 'partner')],
    );

    final nodes = {for (final node in layout.nodes) node.person.id: node};
    expect(nodes['parent']!.position.y, lessThan(nodes['child']!.position.y));
    expect(nodes['child']!.position.y, equals(nodes['partner']!.position.y));
    expect(layout.edges, hasLength(2));
    expect(layout.width, greaterThanOrEqualTo(360));
  });
}
