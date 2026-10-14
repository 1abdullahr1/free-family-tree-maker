import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/tree_layout.dart';
import '../../data/backup/family_tree_backup.dart';
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
          if (_tab == 0) {
            return _TreeCanvas(
              treeId: widget.treeId,
              items: items,
              repository: ref.read(personRepositoryProvider(widget.treeId)),
              focusId: _focusId,
              onSelect: _selectPerson,
            );
          }
          if (_tab == 1) return _PeopleTab(items: _filtered(items), onAdd: _addPerson, onSelect: _selectPerson);
          return _MoreTab(
            treeId: widget.treeId,
            treeName: tree?.name ?? 'Family tree',
            repository: ref.read(personRepositoryProvider(widget.treeId)),
          );
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
  const _MoreTab({required this.treeId, required this.treeName, required this.repository});
  final String treeId;
  final String treeName;
  final PersonRepository repository;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(treeName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & restore'),
            subtitle: const Text('Copy a portable backup or restore one from the clipboard'),
            onTap: () => _showBackup(context),
          ),
          const ListTile(leading: Icon(Icons.lock_outline), title: Text('Privacy'), subtitle: Text('Your family data stays on this device.')),
          const ListTile(leading: Icon(Icons.palette_outlined), title: Text('Theme'), subtitle: Text('System theme is active')),
        ],
      );

  Future<void> _showBackup(BuildContext context) async {
    final service = FamilyTreeBackup(database: repository.database);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy backup'),
            subtitle: const Text('Copies a JSON backup to the clipboard.'),
            onTap: () async {
              final backup = await service.exportTree(treeId);
              await Clipboard.setData(ClipboardData(text: backup));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup copied to clipboard.')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore from clipboard'),
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (context.mounted) Navigator.pop(context);
              if (data?.text == null) return;
              try {
                await service.restoreTree(data!.text!);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored as a new family tree.')));
              } on FamilyTreeBackupException catch (error) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
          ),
        ]),
      ),
    );
  }
}

class _TreeCanvas extends StatelessWidget {
  const _TreeCanvas({
    required this.treeId,
    required this.items,
    required this.repository,
    required this.focusId,
    required this.onSelect,
  });
  final String treeId;
  final List<Person> items;
  final PersonRepository repository;
  final String? focusId;
  final ValueChanged<Person> onSelect;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<List<PersonRelation>>>(
        future: Future.wait([repository.parentChildRelations(treeId), repository.partnerRelations(treeId)]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return _buildCanvas(context, snapshot.data![0], snapshot.data![1]);
        },
      );

  Widget _buildCanvas(
    BuildContext context,
    List<PersonRelation> parentChildRelations,
    List<PersonRelation> partnerRelations,
  ) {
    if (items.isEmpty) {
      return Center(child: Text('Add people to begin your family tree.', style: Theme.of(context).textTheme.titleMedium));
    }
    final layout = const TreeLayoutService().layout(
      people: items,
      parentChildRelations: parentChildRelations,
      partnerRelations: partnerRelations,
    );
    return InteractiveViewer(
      constrained: false,
      minScale: .35,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(240),
      child: SizedBox(
        width: layout.width.clamp(360, 2400).toDouble(),
        height: layout.height,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _ConnectorPainter(layout: layout))),
            for (final node in layout.nodes)
              Positioned(
                left: node.position.x,
                top: node.position.y,
                child: _NodeCard(person: node.person, selected: node.person.id == focusId, onTap: () => onSelect(node.person)),
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
  const _ConnectorPainter({required this.layout});
  final TreeLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final parentPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(.45)
      ..strokeWidth = 2;
    final partnerPaint = Paint()
      ..color = Colors.pinkAccent.withOpacity(.55)
      ..strokeWidth = 2.5;
    final positions = {for (final node in layout.nodes) node.person.id: node.position};
    for (final edge in layout.edges) {
      final first = positions[edge.firstId];
      final second = positions[edge.secondId];
      if (first == null || second == null) continue;
      final paint = edge.type == TreeEdgeType.partner ? partnerPaint : parentPaint;
      final firstCenter = Offset(first.x + 84, first.y + 64);
      final secondCenter = Offset(second.x + 84, second.y + 64);
      if (edge.type == TreeEdgeType.partner) {
        canvas.drawLine(firstCenter, secondCenter, paint);
      } else {
        final start = Offset(firstCenter.dx, first.y < second.y ? first.y + 128 : first.y);
        final end = Offset(secondCenter.dx, first.y < second.y ? second.y : second.y + 128);
        final middleY = (start.dy + end.dy) / 2;
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(start.dx, middleY)
          ..lineTo(end.dx, middleY)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) => oldDelegate.layout != layout;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
