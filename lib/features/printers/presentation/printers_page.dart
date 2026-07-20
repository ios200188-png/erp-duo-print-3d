import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/printer_repository.dart';

class PrintersPage extends ConsumerWidget {
  const PrintersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printers = ref.watch(printersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impressoras')),
      body: printers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Nenhuma impressora cadastrada.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.print)),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.manufacturer} ${item.model}\n'
                    '${item.printedHours.toStringAsFixed(0)} h impressas • '
                    '${item.hoursUntilMaintenance.toStringAsFixed(0)} h até manutenção',
                  ),
                  isThreeLine: true,
                  onTap: () => context.go('/printers/${item.id}/edit'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref
                          .read(printerRepositoryProvider)
                          .delete(item.id);
                      ref.invalidate(printersProvider);
                      ref.invalidate(printerCountProvider);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/printers/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova impressora'),
      ),
    );
  }
}
