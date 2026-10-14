import 'package:flutter/material.dart';
import '../models/person.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;
  const PersonCard({Key? key, required this.person, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade300,
          child: Text(person.name.isNotEmpty ? person.name[0].toUpperCase() : '?'),
        ),
        title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: person.birthYear != null ? Text('b. ${person.birthYear}') : null,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
