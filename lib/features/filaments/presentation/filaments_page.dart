import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/filament_repository.dart';
import '../domain/filament.dart';

class FilamentsPage extends ConsumerStatefulWidget {
  const FilamentsPage({super.key});

  @override
  ConsumerState<FilamentsPage> createState() => _FilamentsPageState();
}

class _FilamentsPageState extends ConsumerState<FilamentsPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(filamentsProvider);
    ref.invalidate(filamentCountProvider);
    ref.invalidate(lowStockCountProvider);
    ref.invalidate(filamentMovementsProvider(null));
  }

  Future<void> _movement(Filament filament) async {
    final result = await showDialog<_MovementData>(
      context: context,
      builder: (context) => _MovementDialog(filament: filament),
    );
    if (result == null) return;

    try {
      await ref
          .read(filamentRepositoryProvider)
          .registerMovement(
            filamentId: filament.id,
            type: result.type,
            quantity: result.quantity,
            reason: result.reason,
            unitCost: result.unitCost,
          );
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movimentação registrada.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filaments = ref.watch(filamentsProvider);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque de filamentos'),
        actions: [
          IconButton(
            tooltip: 'Histórico',
            onPressed: () => context.go('/filaments/movements'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: filaments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (items) {
          final query = _search.text.trim().toLowerCase();
          final filtered = items.where((item) {
            if (query.isEmpty) return true;
            return '${item.name} ${item.materialType} ${item.brand} ${item.color}'
                .toLowerCase()
                .contains(query);
          }).toList();
          final totalWeight = items.fold<double>(
            0,
            (value, item) => value + item.currentWeight,
          );
          final totalReserved = items.fold<double>(
            0,
            (value, item) => value + item.reservedWeight,
          );
          final lowStock = items.where((item) => item.lowStock).length;

          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await ref.read(filamentsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SummaryCard(
                      label: 'Filamentos',
                      value: '${items.length}',
                      icon: Icons.inventory_2_outlined,
                    ),
                    _SummaryCard(
                      label: 'Saldo total',
                      value: '${(totalWeight / 1000).toStringAsFixed(2)} kg',
                      icon: Icons.scale_outlined,
                    ),
                    _SummaryCard(
                      label: 'Reservado',
                      value: '${totalReserved.toStringAsFixed(0)} g',
                      icon: Icons.lock_clock_outlined,
                    ),
                    _SummaryCard(
                      label: 'Estoque baixo',
                      value: '$lowStock',
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Pesquisar filamento',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: Text('Nenhum filamento encontrado.')),
                  )
                else
                  ...filtered.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    child: Icon(
                                      item.lowStock
                                          ? Icons.warning_amber_rounded
                                          : Icons.all_inclusive,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          '${item.materialType} • ${item.color}'
                                          '${item.brand.isEmpty ? '' : ' • ${item.brand}'}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        context.go(
                                          '/filaments/${item.id}/edit',
                                        );
                                      } else if (value == 'delete') {
                                        await ref
                                            .read(filamentRepositoryProvider)
                                            .delete(item.id);
                                        _refresh();
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar cadastro'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: item.initialWeight <= 0
                                    ? 0
                                    : (item.availableWeight /
                                              item.initialWeight)
                                          .clamp(0, 1),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Disponível: ${item.availableWeight.toStringAsFixed(0)} g • '
                                'Físico: ${item.currentWeight.toStringAsFixed(0)} g • '
                                'Reservado: ${item.reservedWeight.toStringAsFixed(0)} g',
                              ),
                              Text(
                                '${money.format(item.costPerGram)}/g • '
                                'Mínimo: ${item.minimumStock.toStringAsFixed(0)} g',
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _movement(item),
                                  icon: const Icon(Icons.swap_vert),
                                  label: const Text('MOVIMENTAR ESTOQUE'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                    Text(label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementData {
  const _MovementData({
    required this.type,
    required this.quantity,
    required this.reason,
    required this.unitCost,
  });

  final String type;
  final double quantity;
  final String reason;
  final double unitCost;
}

class _MovementDialog extends StatefulWidget {
  const _MovementDialog({required this.filament});

  final Filament filament;

  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<_MovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  final _cost = TextEditingController();
  String _type = 'Entrada';

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Movimentar ${widget.filament.name}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'Entrada', child: Text('Entrada')),
                  DropdownMenuItem(value: 'Saída', child: Text('Saída')),
                  DropdownMenuItem(
                    value: 'Ajuste',
                    child: Text('Ajuste de inventário'),
                  ),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _type == 'Ajuste'
                      ? 'Novo saldo físico (g)'
                      : 'Quantidade (g)',
                ),
                validator: (value) {
                  if (_number(value ?? '') <= 0 && _type != 'Ajuste') {
                    return 'Informe uma quantidade maior que zero.';
                  }
                  if (_number(value ?? '') < 0) {
                    return 'O saldo não pode ser negativo.';
                  }
                  return null;
                },
              ),
              if (_type == 'Entrada') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Custo por grama (opcional)',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _reason,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo ou observação',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _MovementData(
                type: _type,
                quantity: _number(_quantity.text),
                reason: _reason.text.trim(),
                unitCost: _number(_cost.text),
              ),
            );
          },
          child: const Text('REGISTRAR'),
        ),
      ],
    );
  }
}
