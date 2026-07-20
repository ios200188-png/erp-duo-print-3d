import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/project_repository.dart';

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return Scaffold(
      appBar: AppBar(title: const Text('Projetos')),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Nenhum projeto cadastrado.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.view_in_ar_outlined),
                  ),
                  title: Text(
                    item.version.isEmpty
                        ? item.name
                        : '${item.name} — ${item.version}',
                  ),
                  subtitle: Text(
                    '${item.defaultMaterial} • '
                    '${item.estimatedWeight.toStringAsFixed(0)} g • '
                    '${item.formattedTime}\n'
                    'Preço sugerido: ${money.format(item.suggestedPrice)}',
                  ),
                  isThreeLine: true,
                  onTap: () => context.go('/projects/${item.id}/edit'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref.read(projectRepositoryProvider).delete(item.id);
                      ref.invalidate(projectsProvider);
                      ref.invalidate(projectCountProvider);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/projects/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo projeto'),
      ),
    );
  }
}
