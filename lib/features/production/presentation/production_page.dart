import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agenda/data/agenda_repository.dart';
import '../../billing/data/billing_repository.dart';
import '../../quotes/data/quote_repository.dart';
import '../data/production_repository.dart';
import '../domain/production_order.dart';

class ProductionPage extends ConsumerWidget {
  const ProductionPage({super.key});

  static const _columns = [
    'Planejada',
    'Imprimindo',
    'Pausada',
    'Finalizada',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(productionOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produção Kanban'),
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (items) {
          return DefaultTabController(
            length: _columns.length,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Planejada'),
                    Tab(text: 'Imprimindo'),
                    Tab(text: 'Pausada'),
                    Tab(text: 'Finalizada'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: _columns.map((status) {
                      final filtered = items
                          .where((item) => item.status == status)
                          .toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma ordem nesta etapa.'),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _KanbanCard(order: filtered[index]);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KanbanCard extends ConsumerWidget {
  const _KanbanCard({required this.order});

  final ProductionOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(_icon(order.status)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.projectName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text('${order.printerName} • ${order.priority}'),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (status) =>
                      _changeStatus(context, ref, status),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'Planejada',
                      child: Text('Mover para Planejada'),
                    ),
                    PopupMenuItem(
                      value: 'Imprimindo',
                      child: Text('Mover para Imprimindo'),
                    ),
                    PopupMenuItem(
                      value: 'Pausada',
                      child: Text('Mover para Pausada'),
                    ),
                    PopupMenuItem(
                      value: 'Finalizada',
                      child: Text('Mover para Finalizada'),
                    ),
                    PopupMenuItem(
                      value: 'Cancelada',
                      child: Text('Cancelar ordem'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(value: order.progress),
            const SizedBox(height: 8),
            Text(
              '${order.quantityProduced} de ${order.quantityPlanned} unidades • '
              '${(order.progress * 100).toStringAsFixed(0)}%',
            ),
            if (order.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                order.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    await ref.read(productionRepositoryProvider).updateStatus(
          order.id,
          status,
          quantityProduced:
              status == 'Finalizada' ? order.quantityPlanned : null,
        );

    ref.invalidate(productionOrdersProvider);
    ref.invalidate(productionOpenCountProvider);
    ref.invalidate(quotesProvider);
    ref.invalidate(billableQuotesProvider);
    ref.invalidate(invoicesProvider);
    ref.invalidate(awaitingBillingCountProvider);
    ref.invalidate(agendaItemsProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ordem movida para $status.')),
    );
  }

  static IconData _icon(String status) {
    switch (status) {
      case 'Imprimindo':
        return Icons.print_outlined;
      case 'Pausada':
        return Icons.pause_circle_outline;
      case 'Finalizada':
        return Icons.check_circle_outline;
      default:
        return Icons.schedule_outlined;
    }
  }
}
