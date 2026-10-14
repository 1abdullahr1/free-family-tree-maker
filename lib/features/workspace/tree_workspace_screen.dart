import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/person_repository.dart';
import '../../models/person.dart';
import '../trees/tree_list_screen.dart';
import 'person_form_screen.dart';
import 'person_profile_screen.dart';

final personRepositoryProvider = Provider.family<PersonRepository, String>((ref, treeId) {
  final repository = PersonRepository(database: ref.watch(familyTreeRepositoryProvider).database);
  ref.onDispose(repository.dispose);
  return repository;
});

final peopleProvider = StreamProvider.family<List<Person>, String>((ref, treeId) {
  return ref.watch(personRepositoryProvider(treeId)).watchPeople(treeId);
});

class TreeWorkspaceScreen extends ConsumerStatefulWidget {
  const TreeWorkspaceScreen({super.key, required this.treeId});
  final String treeId;

  @override
  ConsumerState<TreeWorkspaceScreen> createState() => _TreeWorkspaceScreenState();
}

class _TreeWorkspaceScreenState extends ConsumerState<TreeWorkspaceScreen> {
  int _tab = 0;
  String _search = '';
  String? _focusId;

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(familyTreesProvider).maybeWhen(
          data: (trees) => trees.where((item) => item.id == widget.treeId).firstOrNull,
          orElse: () => null,
        );
    final people = ref.watch(peopleProvider(widget.treeId));
    return Scaffold(
      appBar: AppBar(
        title: Text(tree?.name ?? 'Family tree'),
        actions: [
          if (_tab == 1)
            IconButton(
              tooltip: 'Search people',
              onPressed: () => _showSearch(context),
              icon: const Icon(Icons.search),
            ),
        ],
      ),
      body: people.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load people.\n$error')),
        data: (items) {
          if (_tab == 0) return _TreeCanvas(items: items, focusId: _focusId, onSelect: _selectPerson);
          if (_tab == 1) return _PeopleTab(items: _filtered(items), onAdd: _addPerson, onSelect: _selectPerson);
          return _MoreTab(treeName: tree?.name ?? 'Family tree');
        },
      ),
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(onPressed: _addPerson, icon: const Icon(Icons.person_add), label: const Text('Add person'))
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_tree_outlined), selectedIcon: Icon(Icons.account_tree), label: 'Tree'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'People'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  List<Person> _filtered(List<Person> items) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((person) => '${person.displayName} ${person.nickname ?? ''}'.toLowerCase().contains(query)).toList();
  }

  void _selectPerson(Person person) {
    setState(() => _focusId = person.id);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: CircleAvatar(child: Text(person.initials)), title: Text(person.displayName), subtitle: Text(person.yearLabel)),
            ListTile(leading: const Icon(Icons.person), title: const Text('View profile'), onTap: () {
              Navigator.pop(context);
              Navigator.of(this.context).push(MaterialPageRoute(builder: (_) => PersonProfileScreen(treeId: widget.treeId, person: person)));
            }),
            ListTile(leading: const Icon(Icons.edit), title: const Text('Edit details'), onTap: () {
              Navigator.pop(context);
              _editPerson(person);
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _addPerson() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PersonFormScreen(treeId: widget.treeId)));
  }

  Future<void> _editPerson(Person person) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PersonFormScreen(treeId: widget.treeId, person: person)));
  }

  Future<void> _showSearch(BuildContext context) async {
    final controller = TextEditingController(text: _search);
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search people'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Name or nickname')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Search')),
        ],
      ),
    );
    if (query != null) setState(() => _search = query);
  }
}

class _PeopleTab extends StatelessWidget {
  const _PeopleTab({required this.items, required this.onAdd, required this.onSelect});
  final List<Person> items;
  final VoidCallback onAdd;
  final ValueChanged<Person> onSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.person_add), label: const Text('Add first person')));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final person = items[index];
        return ListTile(
          key: ValueKey(person.id),
          onTap: () => onSelect(person),
          leading: CircleAvatar(child: Text(person.initials)),
          title: Text(person.displayName),
          subtitle: Text([person.yearLabel, if (person.nickname != null) '“${person.nickname}”'].where((v) => v.isNotEmpty).join(' · ')),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({required this.treeName});
  final String treeName;
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(treeName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          const ListTile(leading: Icon(Icons.backup), title: Text('Backup & export'), subtitle: Text('Coming next: local backup and GEDCOM/PDF export')),
          const ListTile(leading: Icon(Icons.lock_outline), title: Text('Privacy'), subtitle: Text('Your family data stays on this device.')),
          const ListTile(leading: Icon(Icons.palette_outlined), title: Text('Theme'), subtitle: Text('System theme is active')),
        ],
      );
}

class _TreeCanvas extends StatelessWidget {
  const _TreeCanvas({required this.items, required this.focusId, required this.onSelect});
  final List<Person> items;
  final String? focusId;
  final ValueChanged<Person> onSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text('Add people to begin your family tree.', style: Theme.of(context).textTheme.titleMedium));
    }
    final columns = <List<Person>>[items];
    return InteractiveViewer(
      constrained: false,
      minScale: .35,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(240),
      child: SizedBox(
        width: (columns.first.length * 190).clamp(360, 2400).toDouble(),
        height: 360,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _ConnectorPainter())),
            for (var index = 0; index < items.length; index++)
              Positioned(
                left: 20 + (index * 180),
                top: 120,
                child: _NodeCard(person: items[index], selected: items[index].id == focusId, onTap: () => onSelect(items[index])),
              ),
            Positioned(
              right: 18,
              top: 18,
              child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Text('${items.length} people'))),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({required this.person, required this.selected, required this.onTap});
  final Person person;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${person.displayName}, ${person.yearLabel}',
        child: SizedBox(
          width: 168,
          child: Card(
            color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  CircleAvatar(child: Text(person.initials)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(person.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (person.yearLabel.isNotEmpty) Text(person.yearLabel),
                  ])),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _ConnectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blueGrey.withOpacity(.35)..strokeWidth = 2;
    final y = 164.0;
    for (var x = 104.0; x < size.width - 86; x += 180) {
      canvas.drawLine(Offset(x, y), Offset(x + 180, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
