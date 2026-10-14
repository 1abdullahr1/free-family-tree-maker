import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/trees/create_tree_screen.dart';
import '../features/trees/tree_list_screen.dart';
import '../features/workspace/tree_workspace_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const TreeListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const CreateTreeScreen(),
          ),
          GoRoute(
            path: 'tree/:treeId',
            builder: (context, state) {
              final treeId = state.pathParameters['treeId']!;
              return TreeWorkspaceScreen(treeId: treeId);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
