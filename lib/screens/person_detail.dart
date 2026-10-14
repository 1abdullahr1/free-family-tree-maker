import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../models/person.dart';
import '../providers/person_provider.dart';

class PersonDetailScreen extends StatefulWidget {
  final int personId;
  const PersonDetailScreen({Key? key, required this.personId}) : super(key: key);

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  Person? _person;
  List<Person> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _person = await DatabaseHelper.instance.getPerson(widget.personId);
    final all = await DatabaseHelper.instance.getAllPersons();
    _children = all.where((p) => p.parentId == widget.personId).toList();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PersonProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(_person?.name ?? 'Person'),
        actions: [
          IconButton(
              onPressed: () async {
                if (_person?.id != null) {
                  await prov.delete(_person!.id!);
                  if (mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_person?.name ?? '', style: Theme.of(context).textTheme.headline6),
                const SizedBox(height: 8),
                if (_person?.birthYear != null) Text('Born: ${_person!.birthYear}'),
                const SizedBox(height: 16),
                const Text('Children', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _children.isEmpty
                    ? const Text('No children recorded')
                    : Column(children: _children.map((c) => ListTile(title: Text(c.name))).toList()),
              ]),
            ),
    );
  }
}
