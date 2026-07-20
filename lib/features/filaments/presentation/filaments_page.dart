import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/filament_repository.dart';

class FilamentsPage extends ConsumerWidget {
  const FilamentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filaments = ref.watch(filamentsProvider);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return Scaffold(
      appBar: AppBar(title: const Text('Filamentos')),
      body: filaments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Nenhum filamento cadastrado.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      item.lowStock
                          ? Icons.warning_amber_rounded
                          : Icons.all_inclusive,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.materialType} • ${item.color}\n'
                    '${item.currentWeight.toStringAsFixed(0)} g restantes • '
                    '${money.format(item.costPerGram)}/g',
                  ),
                  isThreeLine: true,
                  onTap: () => context.go('/filaments/${item.id}/edit'),
                  trailing: IconButton(
                    onPressed: () async {
                      await ref
                          .read(filamentRepositoryProvider)
                          .delete(item.id);
                      ref.invalidate(filamentsProvider);
                      ref.invalidate(filamentCountProvider);
                      ref.invalidate(lowStockCountProvider);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/filaments/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo filamento'),
      ),
    );
  }
}
