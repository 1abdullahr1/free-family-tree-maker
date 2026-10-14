import 'package:flutter/material.dart';
import '../db/database.dart';
import '../models/person.dart';

class PersonProvider with ChangeNotifier {
  List<Person> _people = [];
  bool _loading = true;

  List<Person> get people => _people;
  bool get loading => _loading;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    _people = await DatabaseHelper.instance.getAllPersons();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(Person p) async {
    await DatabaseHelper.instance.createPerson(p);
    await loadAll();
  }

  Future<void> update(Person p) async {
    if (p.id != null) {
      await DatabaseHelper.instance.updatePerson(p);
      await loadAll();
    }
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.instance.deletePerson(id);
    await loadAll();
  }
}
