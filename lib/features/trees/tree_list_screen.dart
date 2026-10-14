import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/family_tree_repository.dart';
import '../../models/family_tree.dart';

final familyTreeRepositoryProvider = Provider<FamilyTreeRepository>((ref) {
  final repository = FamilyTreeRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final familyTreesProvider = StreamProvider<List<FamilyTree>>((ref) {
  return ref.watch(familyTreeRepositoryProvider).watchTrees();
});

class TreeListScreen extends ConsumerWidget {
  const TreeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treesAsync = ref.watch(familyTreesProvider);
    final repo = ref.watch(familyTreeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your family trees'),
      ),
      body: treesAsync.when(
        data: (trees) {
          if (trees.isEmpty) {
            return _EmptyState(onCreate: () => context.push('/new'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: trees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tree = trees[index];
              return _TreeCard(
                tree: tree,
                onTap: () => context.push('/tree/${tree.id}'),
                onRename: () => _showRenameDialog(context, repo, tree),
                onDelete: () => _showDeleteDialog(context, repo, tree),
              );
            },
          );
        },
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load trees.\n$error'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/new'),
        icon: const Icon(Icons.add),
        label: const Text('Create family tree'),
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    FamilyTreeRepository repo,
    FamilyTree tree,
  ) async {
    final controller = TextEditingController(text: tree.name);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename family tree'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Tree name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    await repo.renameTree(tree.id, result);
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    FamilyTreeRepository repo,
    FamilyTree tree,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete family tree?'),
          content: Text('Delete "${tree.name}" and all of its people and relationships?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await repo.deleteTree(tree.id);
    }
  }
}

class _TreeCard extends StatelessWidget {
  const _TreeCard({
    required this.tree,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final FamilyTree tree;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final updatedLabel = MaterialLocalizations.of(context).formatShortDate(tree.updatedAt);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                child: const Icon(Icons.forest),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tree.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('${tree.personCount} people'),
                    const SizedBox(height: 2),
                    Text('Updated $updatedLabel'),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.family_restroom, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              'Your family trees',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first tree to begin organizing relatives on this device.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create family tree'),
            ),
          ],
        ),
      ),
    );
  }
}
