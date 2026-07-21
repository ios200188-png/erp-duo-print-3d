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
                    '${item.hoursUntilMaintenance.toStringAsFixed(0)} h até manutenção'
                    '${item.hoursUntilMaintenance <= 50 ? ' • ATENÇÃO' : ''}',
                  ),
                  isThreeLine: true,
                  onTap: () => context.go('/printers/${item.id}/edit'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'maintenance') {
                        context.go('/printers/${item.id}/maintenances');
                        return;
                      }
                      if (value == 'edit') {
                        context.go('/printers/${item.id}/edit');
                        return;
                      }
                      if (value == 'delete') {
                        await ref
                            .read(printerRepositoryProvider)
                            .delete(item.id);
                        ref.invalidate(printersProvider);
                        ref.invalidate(printerCountProvider);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'maintenance',
                        child: ListTile(
                          leading: Icon(Icons.build_circle_outlined),
                          title: Text('Manutenções'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Excluir'),
                        ),
                      ),
                    ],
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
