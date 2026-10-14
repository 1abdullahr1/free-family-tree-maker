import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/name_utils.dart';
import 'tree_list_screen.dart';

class CreateTreeScreen extends ConsumerStatefulWidget {
  const CreateTreeScreen({super.key});

  @override
  ConsumerState<CreateTreeScreen> createState() => _CreateTreeScreenState();
}

class _CreateTreeScreenState extends ConsumerState<CreateTreeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(familyTreeRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Create family tree')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start with a tree name.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'You can add people and relationships in later milestones.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tree name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (!isValidTreeName(value ?? '')) {
                      return 'Enter a tree name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              if (!(_formKey.currentState?.validate() ?? false)) {
                                return;
                              }

                              setState(() => _saving = true);
                              try {
                                final tree = await repo.createTree(_nameController.text);
                                if (!mounted) return;
                                context.go('/tree/${tree.id}');
                              } finally {
                                if (mounted) {
                                  setState(() => _saving = false);
                                }
                              }
                            },
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
