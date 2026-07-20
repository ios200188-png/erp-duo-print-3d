import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/agenda_repository.dart';
import '../domain/agenda_item.dart';

class AgendaPage extends ConsumerWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenda = ref.watch(agendaItemsProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda inteligente'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(agendaItemsProvider);
          await ref.read(agendaItemsProvider.future);
        },
        child: agenda.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('Erro: $error')),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.event_available_outlined, size: 72),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Nenhuma pendência nos próximos 30 dias.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            final grouped = <String, List<AgendaItem>>{};
            for (final item in items) {
              final key = dateFormat.format(item.date);
              grouped.putIfAbsent(key, () => []).add(item);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: grouped.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...entry.value.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(_icon(item.type)),
                              ),
                              title: Text(item.title),
                              subtitle: Text(item.subtitle),
                              trailing: item.isUrgent
                                  ? const Icon(
                                      Icons.warning_amber_rounded,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  static IconData _icon(AgendaItemType type) {
    switch (type) {
      case AgendaItemType.delivery:
        return Icons.local_shipping_outlined;
      case AgendaItemType.receivable:
        return Icons.south_west;
      case AgendaItemType.payable:
        return Icons.north_east;
      case AgendaItemType.maintenance:
        return Icons.build_outlined;
      case AgendaItemType.stock:
        return Icons.inventory_2_outlined;
    }
  }
}
