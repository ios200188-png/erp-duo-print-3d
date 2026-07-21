import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/filament_repository.dart';

class FilamentMovementsPage extends ConsumerWidget {
  const FilamentMovementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movements = ref.watch(filamentMovementsProvider(null));
    final date = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Movimentações de estoque')),
      body: movements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Nenhuma movimentação registrada.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(filamentMovementsProvider(null));
              await ref.read(filamentMovementsProvider(null).future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final sign = item.quantity >= 0 ? '+' : '';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        item.quantity >= 0
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                      ),
                    ),
                    title: Text('${item.type} • ${item.filamentName}'),
                    subtitle: Text(
                      '${date.format(item.createdAt)}\n'
                      '${item.reason.isEmpty ? 'Sem observação' : item.reason}\n'
                      'Saldo: ${item.balanceBefore.toStringAsFixed(0)} g → '
                      '${item.balanceAfter.toStringAsFixed(0)} g',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      '$sign${item.quantity.toStringAsFixed(0)} g',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
