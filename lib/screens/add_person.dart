import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/person_provider.dart';

class AddPersonScreen extends StatefulWidget {
  const AddPersonScreen({Key? key}) : super(key: key);

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _birth = TextEditingController();
  int? _parentId;

  @override
  void dispose() {
    _name.dispose();
    _birth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PersonProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Person')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birth,
                decoration: const InputDecoration(labelText: 'Birth year (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _parentId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('No parent / root')),
                  ...prov.people.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList()
                ],
                onChanged: (v) => setState(() => _parentId = v),
                decoration: const InputDecoration(labelText: 'Parent (optional)'),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final person = Person(name: _name.text.trim(), birthYear: _birth.text.trim().isEmpty ? null : _birth.text.trim(), parentId: _parentId);
                    await prov.add(person);
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
