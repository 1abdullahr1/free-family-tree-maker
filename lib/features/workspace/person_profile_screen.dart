import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/person_repository.dart';
import '../../models/person.dart';
import 'tree_workspace_screen.dart';

class PersonProfileScreen extends ConsumerStatefulWidget {
  const PersonProfileScreen({super.key, required this.treeId, required this.person});
  final String treeId;
  final Person person;

  @override
  ConsumerState<PersonProfileScreen> createState() => _PersonProfileScreenState();
}

class _PersonProfileScreenState extends ConsumerState<PersonProfileScreen> {
  int _relationshipVersion = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(personRepositoryProvider(widget.treeId));
    return Scaffold(
      appBar: AppBar(title: Text(widget.person.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(radius: 42, child: Text(widget.person.initials, style: const TextStyle(fontSize: 24))),
          const SizedBox(height: 12),
          Center(child: Text(widget.person.displayName, style: Theme.of(context).textTheme.headlineSmall)),
          if (widget.person.nickname != null) Center(child: Text('“${widget.person.nickname}”')),
          const SizedBox(height: 20),
          if (widget.person.yearLabel.isNotEmpty) ListTile(leading: const Icon(Icons.event), title: Text(widget.person.yearLabel)),
          if (widget.person.birthPlace != null) ListTile(leading: const Icon(Icons.place), title: Text('Born in ${widget.person.birthPlace}')),
          if (widget.person.deathPlace != null) ListTile(leading: const Icon(Icons.place_outlined), title: Text('Died in ${widget.person.deathPlace}')),
          if (widget.person.biography != null) _Section(title: 'Biography', body: widget.person.biography!),
          if (widget.person.notes != null) _Section(title: 'Notes', body: widget.person.notes!),
          _Relationships(
            key: ValueKey(_relationshipVersion),
            person: widget.person,
            repo: repo,
            onAdd: _addRelationship,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: () => _delete(context, repo), icon: const Icon(Icons.delete_outline), label: const Text('Delete person')),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, PersonRepository repo) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete person?'),
      content: Text('Delete ${widget.person.displayName}? Their relationship links will also be removed.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (confirm == true) {
      await repo.delete(widget.person.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _addRelationship() async {
    final people = await repoForDialog.listPeople(widget.treeId);
    final otherPeople = people.where((item) => item.id != widget.person.id).toList();
    if (!mounted || otherPeople.isEmpty) return;
    final selection = await _chooseRelationship(otherPeople);
    if (selection == null) return;
    try {
      if (selection.kind == _RelationshipKind.parent) {
        await repoForDialog.addParentChild(treeId: widget.treeId, parentId: selection.person.id, childId: widget.person.id);
      } else if (selection.kind == _RelationshipKind.child) {
        await repoForDialog.addParentChild(treeId: widget.treeId, parentId: widget.person.id, childId: selection.person.id);
      } else {
        await repoForDialog.addPartner(treeId: widget.treeId, personAId: widget.person.id, personBId: selection.person.id);
      }
      if (mounted) setState(() => _relationshipVersion++);
    } on RelationshipException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  PersonRepository get repoForDialog => ref.read(personRepositoryProvider(widget.treeId));

  Future<_RelationshipSelection?> _chooseRelationship(List<Person> people) {
    return showDialog<_RelationshipSelection>(
      context: context,
      builder: (context) => _RelationshipDialog(people: people),
    );
  }
}

class _Relationships extends StatelessWidget {
  const _Relationships({super.key, required this.person, required this.repo, required this.onAdd});
  final Person person;
  final PersonRepository repo;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<List<Person>>>(
        future: Future.wait([repo.parentsOfPeople(person.id), repo.partnersOf(person.id), repo.childrenOfPeople(person.id)]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Padding(padding: EdgeInsets.only(top: 20), child: LinearProgressIndicator());
          final groups = <({String title, IconData icon, List<Person> people})>[
            (title: 'Parents', icon: Icons.arrow_upward, people: snapshot.data![0]),
            (title: 'Partners', icon: Icons.favorite_outline, people: snapshot.data![1]),
            (title: 'Children', icon: Icons.arrow_downward, people: snapshot.data![2]),
          ];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Family relationships', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(tooltip: 'Add relationship', onPressed: onAdd, icon: const Icon(Icons.add_link)),
            ]),
            for (final group in groups)
              if (group.people.isNotEmpty) ...[
                Text(group.title, style: Theme.of(context).textTheme.labelLarge),
                ...group.people.map((item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(group.icon),
                      title: Text(item.displayName),
                      subtitle: item.yearLabel.isEmpty ? null : Text(item.yearLabel),
                    )),
              ],
            if (groups.every((group) => group.people.isEmpty))
              const Text('No relationships added yet.'),
          ]);
        },
      );
}

enum _RelationshipKind { parent, child, partner }

class _RelationshipSelection {
  const _RelationshipSelection(this.kind, this.person);
  final _RelationshipKind kind;
  final Person person;
}

class _RelationshipDialog extends StatefulWidget {
  const _RelationshipDialog({required this.people});
  final List<Person> people;
  @override
  State<_RelationshipDialog> createState() => _RelationshipDialogState();
}

class _RelationshipDialogState extends State<_RelationshipDialog> {
  _RelationshipKind _kind = _RelationshipKind.parent;
  Person? _person;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add relationship'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<_RelationshipKind>(
            value: _kind,
            decoration: const InputDecoration(labelText: 'Relationship'),
            items: const [
              DropdownMenuItem(value: _RelationshipKind.parent, child: Text('Parent')),
              DropdownMenuItem(value: _RelationshipKind.child, child: Text('Child')),
              DropdownMenuItem(value: _RelationshipKind.partner, child: Text('Partner')),
            ],
            onChanged: (value) => setState(() => _kind = value!),
          ),
          DropdownButtonFormField<Person>(
            value: _person,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Person'),
            items: widget.people.map((person) => DropdownMenuItem(value: person, child: Text(person.displayName, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (value) => setState(() => _person = value),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _person == null ? null : () => Navigator.pop(context, _RelationshipSelection(_kind, _person!)), child: const Text('Add')),
        ],
      );
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
