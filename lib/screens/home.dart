import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/person_provider.dart';
import '../widgets/person_card.dart';
import 'add_person.dart';
import 'person_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PersonProvider>(context, listen: false).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PersonProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Family Tree Maker'),
        centerTitle: true,
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.people.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('No people yet', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPersonScreen())),
                      icon: const Icon(Icons.add),
                      label: const Text('Add first person'),
                    )
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: prov.loadAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 80),
                    itemCount: prov.people.length,
                    itemBuilder: (_, i) {
                      final p = prov.people[i];
                      return PersonCard(
                        person: p,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: p.id!))),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPersonScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
