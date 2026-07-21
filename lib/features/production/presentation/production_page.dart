import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../agenda/data/agenda_repository.dart';
import '../../billing/data/billing_repository.dart';
import '../../filaments/data/filament_repository.dart';
import '../../quotes/data/quote_repository.dart';
import '../data/production_repository.dart';
import '../domain/production_order.dart';

class ProductionPage extends ConsumerWidget {
  const ProductionPage({super.key});

  static const _columns = [
    'Aguardando',
    'Preparando',
    'Imprimindo',
    'Acabamento',
    'Concluído',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(productionOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produção Kanban'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(productionOrdersProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/production/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova ordem'),
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (items) => LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _columns
                      .map(
                        (status) => SizedBox(
                          width: 315,
                          child: _KanbanColumn(
                            status: status,
                            items: items
                                .where((item) => item.status == status)
                                .toList(),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            }

            return DefaultTabController(
              length: _columns.length,
              child: Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Aguardando'),
                      Tab(text: 'Preparando'),
                      Tab(text: 'Imprimindo'),
                      Tab(text: 'Acabamento'),
                      Tab(text: 'Concluído'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: _columns
                          .map(
                            (status) => _OrderList(
                              items: items
                                  .where((item) => item.status == status)
                                  .toList(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({required this.status, required this.items});

  final String status;
  final List<ProductionOrder> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_statusIcon(status)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Badge(label: Text('${items.length}')),
              ],
            ),
            const Divider(),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text('Nenhuma ordem'),
              )
            else
              ...items.map((item) => _OrderCard(order: item)),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.items});

  final List<ProductionOrder> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Nenhuma ordem.'));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: items.length,
      itemBuilder: (_, index) => _OrderCard(order: items[index]),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final ProductionOrder order;

  static const _workflow = [
    'Aguardando',
    'Preparando',
    'Imprimindo',
    'Acabamento',
    'Concluído',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateFormat('dd/MM/yyyy');
    final currentIndex = _workflow.indexOf(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${order.id} • ${order.projectName}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(order.priority),
                ),
              ],
            ),
            _InfoLine(icon: Icons.print_outlined, text: order.printerName),
            _InfoLine(
              icon: Icons.inventory_2_outlined,
              text: order.filamentName,
            ),
            _InfoLine(
              icon: Icons.scale_outlined,
              text: order.status == 'Concluído'
                  ? 'Consumo: ${order.actualWeight.toStringAsFixed(1)} g '
                        '(previsto ${order.estimatedWeight.toStringAsFixed(1)} g)'
                  : 'Previsto: ${order.estimatedWeight.toStringAsFixed(1)} g'
                        '${order.reservedMaterialWeight > 0 ? ' • reservado ${order.reservedMaterialWeight.toStringAsFixed(1)} g' : ''}',
            ),
            _InfoLine(
              icon: Icons.schedule_outlined,
              text: order.status == 'Concluído'
                  ? 'Tempo real: ${_formatMinutes(order.actualMinutes)} '
                        '(previsto ${_formatMinutes(order.estimatedMinutes)})'
                  : 'Tempo previsto: ${_formatMinutes(order.estimatedMinutes)}',
            ),
            if (order.scheduledDate != null)
              _InfoLine(
                icon: Icons.event_outlined,
                text: 'Prazo: ${date.format(order.scheduledDate!)}',
                highlight: order.isOverdue,
              ),
            if (order.status == 'Concluído')
              _InfoLine(
                icon: Icons.payments_outlined,
                text:
                    'Material: R\$ ${order.actualMaterialCost.toStringAsFixed(2)}',
              ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: order.progress),
            const SizedBox(height: 5),
            Text(
              '${order.quantityProduced}/${order.quantityPlanned} unidades',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (currentIndex > 0 && order.status != 'Concluído')
                  OutlinedButton.icon(
                    onPressed: () => _changeStatus(
                      context,
                      ref,
                      _workflow[currentIndex - 1],
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                  ),
                if (currentIndex >= 0 && currentIndex < _workflow.length - 1)
                  FilledButton.icon(
                    onPressed: () async {
                      final next = _workflow[currentIndex + 1];
                      if (next == 'Concluído') {
                        final data = await _showCompletionDialog(
                          context,
                          order,
                        );
                        if (data == null || !context.mounted) return;
                        await _changeStatus(
                          context,
                          ref,
                          next,
                          actualWeight: data.weight,
                          actualMinutes: data.minutes,
                        );
                      } else {
                        await _changeStatus(context, ref, next);
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      order.status == 'Preparando'
                          ? 'Iniciar impressão'
                          : 'Avançar',
                    ),
                  ),
                if (order.status != 'Concluído')
                  TextButton.icon(
                    onPressed: () => _changeStatus(context, ref, 'Cancelada'),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    String status, {
    double? actualWeight,
    int? actualMinutes,
  }) async {
    try {
      await ref
          .read(productionRepositoryProvider)
          .updateStatus(
            order.id,
            status,
            quantityProduced: status == 'Concluído'
                ? order.quantityPlanned
                : null,
            actualWeight: actualWeight,
            actualMinutes: actualMinutes,
          );

      ref.invalidate(productionOrdersProvider);
      ref.invalidate(productionOpenCountProvider);
      ref.invalidate(filamentsProvider);
      ref.invalidate(lowStockCountProvider);
      ref.invalidate(filamentMovementsProvider(null));
      ref.invalidate(quotesProvider);
      ref.invalidate(billableQuotesProvider);
      ref.invalidate(invoicesProvider);
      ref.invalidate(awaitingBillingCountProvider);
      ref.invalidate(agendaItemsProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ordem movida para $status.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst('Bad state: ', '')
                .replaceFirst('Invalid argument(s): ', ''),
          ),
        ),
      );
    }
  }
}

Future<_CompletionData?> _showCompletionDialog(
  BuildContext context,
  ProductionOrder order,
) async {
  final weight = TextEditingController(
    text: order.estimatedWeight.toStringAsFixed(1),
  );
  final minutes = TextEditingController(
    text: order.estimatedMinutes.toString(),
  );

  final result = await showDialog<_CompletionData>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Concluir produção'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Informe os dados reais. O consumo será baixado do estoque e a reserva será liberada.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: weight,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Filamento consumido (g)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Tempo real (min)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final parsedWeight =
                double.tryParse(weight.text.trim().replaceAll(',', '.')) ?? 0;
            final parsedMinutes = int.tryParse(minutes.text.trim()) ?? 0;
            if (parsedWeight <= 0) return;
            Navigator.pop(
              context,
              _CompletionData(weight: parsedWeight, minutes: parsedMinutes),
            );
          },
          child: const Text('Concluir e baixar estoque'),
        ),
      ],
    ),
  );

  weight.dispose();
  minutes.dispose();
  return result;
}

class _CompletionData {
  const _CompletionData({required this.weight, required this.minutes});

  final double weight;
  final int minutes;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Theme.of(context).colorScheme.error : null;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: highlight ? FontWeight.w700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMinutes(int total) {
  final hours = total ~/ 60;
  final minutes = total % 60;
  if (hours <= 0) return '${minutes}min';
  return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'Preparando':
      return Icons.tune_outlined;
    case 'Imprimindo':
      return Icons.print_outlined;
    case 'Acabamento':
      return Icons.auto_fix_high_outlined;
    case 'Concluído':
      return Icons.check_circle_outline;
    default:
      return Icons.schedule_outlined;
  }
}
