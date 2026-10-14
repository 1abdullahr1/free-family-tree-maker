import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/person_repository.dart';
import '../../models/person.dart';
import 'tree_workspace_screen.dart';

class PersonProfileScreen extends ConsumerWidget {
  const PersonProfileScreen({super.key, required this.treeId, required this.person});
  final String treeId;
  final Person person;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(personRepositoryProvider(treeId));
    return Scaffold(
      appBar: AppBar(title: Text(person.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(radius: 42, child: Text(person.initials, style: const TextStyle(fontSize: 24))),
          const SizedBox(height: 12),
          Center(child: Text(person.displayName, style: Theme.of(context).textTheme.headlineSmall)),
          if (person.nickname != null) Center(child: Text('“${person.nickname}”')),
          const SizedBox(height: 20),
          if (person.yearLabel.isNotEmpty) ListTile(leading: const Icon(Icons.event), title: Text(person.yearLabel)),
          if (person.birthPlace != null) ListTile(leading: const Icon(Icons.place), title: Text('Born in ${person.birthPlace}')),
          if (person.deathPlace != null) ListTile(leading: const Icon(Icons.place_outlined), title: Text('Died in ${person.deathPlace}')),
          if (person.biography != null) _Section(title: 'Biography', body: person.biography!),
          if (person.notes != null) _Section(title: 'Notes', body: person.notes!),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: () => _delete(context, repo), icon: const Icon(Icons.delete_outline), label: const Text('Delete person')),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, PersonRepository repo) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete person?'),
      content: Text('Delete ${person.displayName}? Their relationship links will also be removed.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (confirm == true) {
      await repo.delete(person.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body),
        ]),
      );
}
