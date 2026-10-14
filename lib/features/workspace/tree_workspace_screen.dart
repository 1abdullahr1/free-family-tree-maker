import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../trees/tree_list_screen.dart';

class TreeWorkspaceScreen extends ConsumerWidget {
  const TreeWorkspaceScreen({super.key, required this.treeId});

  final String treeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(familyTreesProvider);
    final tree = treeAsync.maybeWhen(
      data: (trees) => trees.where((item) => item.id == treeId).firstOrNull,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tree?.name ?? 'Family tree'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                tree?.name ?? 'Loading tree...',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Milestone 1 foundation is ready. People, relationships, and the interactive canvas come next.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (tree != null) Text('${tree.personCount} people'),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
