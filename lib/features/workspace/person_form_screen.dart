import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/person.dart';
import 'tree_workspace_screen.dart';

class PersonFormScreen extends ConsumerStatefulWidget {
  const PersonFormScreen({super.key, required this.treeId, this.person});
  final String treeId;
  final Person? person;
  @override
  ConsumerState<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends ConsumerState<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _given;
  late final TextEditingController _middle;
  late final TextEditingController _surname;
  late final TextEditingController _nickname;
  late final TextEditingController _birthYear;
  late final TextEditingController _deathYear;
  late final TextEditingController _birthPlace;
  late final TextEditingController _deathPlace;
  late final TextEditingController _biography;
  late final TextEditingController _notes;
  String _status = 'unknown';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _given = TextEditingController(text: p?.givenName);
    _middle = TextEditingController(text: p?.middleName);
    _surname = TextEditingController(text: p?.surname);
    _nickname = TextEditingController(text: p?.nickname);
    _birthYear = TextEditingController(text: p?.birthYear?.toString());
    _deathYear = TextEditingController(text: p?.deathYear?.toString());
    _birthPlace = TextEditingController(text: p?.birthPlace);
    _deathPlace = TextEditingController(text: p?.deathPlace);
    _biography = TextEditingController(text: p?.biography);
    _notes = TextEditingController(text: p?.notes);
    _status = p?.lifeStatus ?? 'unknown';
  }

  @override
  void dispose() {
    for (final controller in [_given, _middle, _surname, _nickname, _birthYear, _deathYear, _birthPlace, _deathPlace, _biography, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.person == null ? 'Add person' : 'Edit person')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(controller: _given, decoration: const InputDecoration(labelText: 'Given name'), validator: (_) => _given.text.trim().isEmpty && _surname.text.trim().isEmpty ? 'Enter a given name or surname' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _middle, decoration: const InputDecoration(labelText: 'Middle name')),
              const SizedBox(height: 12),
              TextFormField(controller: _surname, decoration: const InputDecoration(labelText: 'Surname')),
              const SizedBox(height: 12),
              TextFormField(controller: _nickname, decoration: const InputDecoration(labelText: 'Nickname (optional)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Life status'), items: const [
                DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                DropdownMenuItem(value: 'living', child: Text('Living')),
                DropdownMenuItem(value: 'deceased', child: Text('Deceased')),
              ], onChanged: (value) => setState(() => _status = value!)),
              const SizedBox(height: 20),
              Text('Life details', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: _birthYear, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Birth year'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _deathYear, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Death year'))),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _birthPlace, decoration: const InputDecoration(labelText: 'Birth place')),
              const SizedBox(height: 12),
              TextFormField(controller: _deathPlace, decoration: const InputDecoration(labelText: 'Death place')),
              const SizedBox(height: 12),
              TextFormField(controller: _biography, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Biography')),
              const SizedBox(height: 12),
              TextFormField(controller: _notes, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 20),
              FilledButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Save person')),
            ],
          ),
        ),
      );

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final repo = ref.read(personRepositoryProvider(widget.treeId));
    final birth = int.tryParse(_birthYear.text.trim());
    final death = int.tryParse(_deathYear.text.trim());
    try {
      if (widget.person == null) {
        await repo.create(treeId: widget.treeId, givenName: _given.text, middleName: _middle.text, surname: _surname.text, nickname: _nickname.text, lifeStatus: _status, birthYear: birth, deathYear: death, birthPlace: _birthPlace.text, deathPlace: _deathPlace.text, biography: _biography.text, notes: _notes.text);
      } else {
        await repo.update(id: widget.person!.id, givenName: _given.text, middleName: _middle.text, surname: _surname.text, nickname: _nickname.text, lifeStatus: _status, birthYear: birth, deathYear: death, birthPlace: _birthPlace.text, deathPlace: _deathPlace.text, biography: _biography.text, notes: _notes.text);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
