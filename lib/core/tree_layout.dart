import '../models/person.dart';

class PersonRelation {
  const PersonRelation({required this.firstId, required this.secondId});
  final String firstId;
  final String secondId;
}

class TreeLayoutNode {
  const TreeLayoutNode({required this.person, required this.position});
  final Person person;
  final TreeLayoutPoint position;
}

class TreeLayoutPoint {
  const TreeLayoutPoint(this.x, this.y);
  final double x;
  final double y;
}

enum TreeEdgeType { parentChild, partner }

class TreeLayoutEdge {
  const TreeLayoutEdge({
    required this.firstId,
    required this.secondId,
    required this.type,
  });
  final String firstId;
  final String secondId;
  final TreeEdgeType type;
}

class TreeLayout {
  const TreeLayout({
    required this.nodes,
    required this.edges,
    required this.width,
    required this.height,
  });
  final List<TreeLayoutNode> nodes;
  final List<TreeLayoutEdge> edges;
  final double width;
  final double height;
}

class TreeLayoutService {
  const TreeLayoutService();

  TreeLayout layout({
    required List<Person> people,
    required List<PersonRelation> parentChildRelations,
    required List<PersonRelation> partnerRelations,
  }) {
    if (people.isEmpty) {
      return const TreeLayout(nodes: [], edges: [], width: 360, height: 240);
    }

    final byId = {for (final person in people) person.id: person};
    final parentsByChild = <String, List<String>>{};
    final childrenByParent = <String, List<String>>{};
    for (final relation in parentChildRelations) {
      if (!byId.containsKey(relation.firstId) || !byId.containsKey(relation.secondId)) continue;
      parentsByChild.putIfAbsent(relation.secondId, () => []).add(relation.firstId);
      childrenByParent.putIfAbsent(relation.firstId, () => []).add(relation.secondId);
    }

    final generation = <String, int>{};
    final roots = people.where((person) => !parentsByChild.containsKey(person.id)).toList()
      ..sort(_comparePeople);
    final queue = <String>[...roots.map((person) => person.id)];
    for (final root in roots) {
      generation[root.id] = 0;
    }
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentGeneration = generation[current] ?? 0;
      final children = childrenByParent[current] ?? const <String>[];
      for (final childId in children) {
        final nextGeneration = currentGeneration + 1;
        final existing = generation[childId];
        if (existing == null || nextGeneration > existing) {
          generation[childId] = nextGeneration;
          queue.add(childId);
        }
      }
    }
    for (final person in people) {
      generation.putIfAbsent(person.id, () => 0);
    }
    var partnerLevelsChanged = true;
    while (partnerLevelsChanged) {
      partnerLevelsChanged = false;
      for (final relation in partnerRelations) {
        final firstLevel = generation[relation.firstId];
        final secondLevel = generation[relation.secondId];
        if (firstLevel == null || secondLevel == null || firstLevel == secondLevel) continue;
        final sharedLevel = firstLevel > secondLevel ? firstLevel : secondLevel;
        if (firstLevel != sharedLevel || secondLevel != sharedLevel) {
          generation[relation.firstId] = sharedLevel;
          generation[relation.secondId] = sharedLevel;
          partnerLevelsChanged = true;
        }
      }
    }

    final levels = <int, List<Person>>{};
    for (final person in people) {
      levels.putIfAbsent(generation[person.id]!, () => []).add(person);
    }
    final orderedLevels = levels.keys.toList()..sort();
    final positions = <String, TreeLayoutPoint>{};
    var maxWidth = 360.0;
    for (var levelIndex = 0; levelIndex < orderedLevels.length; levelIndex++) {
      final level = levels[orderedLevels[levelIndex]]!..sort(_comparePeople);
      final levelWidth = level.length * 190.0 + 40.0;
      maxWidth = levelWidth > maxWidth ? levelWidth : maxWidth;
      final offset = (maxWidth - levelWidth) / 2;
      for (var index = 0; index < level.length; index++) {
        positions[level[index].id] = TreeLayoutPoint(offset + 20 + index * 190, 30 + levelIndex * 190);
      }
    }

    final edges = <TreeLayoutEdge>[
      for (final relation in parentChildRelations)
        if (positions.containsKey(relation.firstId) && positions.containsKey(relation.secondId))
          TreeLayoutEdge(firstId: relation.firstId, secondId: relation.secondId, type: TreeEdgeType.parentChild),
      for (final relation in partnerRelations)
        if (positions.containsKey(relation.firstId) && positions.containsKey(relation.secondId))
          TreeLayoutEdge(firstId: relation.firstId, secondId: relation.secondId, type: TreeEdgeType.partner),
    ];
    return TreeLayout(
      nodes: [for (final person in people) TreeLayoutNode(person: person, position: positions[person.id]!)],
      edges: edges,
      width: maxWidth,
      height: orderedLevels.length * 190.0 + 80,
    );
  }

  int _comparePeople(Person first, Person second) {
    return first.displayName.toLowerCase().compareTo(second.displayName.toLowerCase());
  }
}
