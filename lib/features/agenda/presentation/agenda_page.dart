import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/agenda_repository.dart';
import '../domain/agenda_item.dart';
import '../domain/production_schedule_item.dart';

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  DateTime _selectedDate = DateTime.now();
  bool _weekly = false;

  DateTime get _dayStart =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  ProductionScheduleRange get _range {
    if (!_weekly) {
      return ProductionScheduleRange(
        start: _dayStart,
        end: _dayStart.add(const Duration(days: 1)),
      );
    }
    final monday = _dayStart.subtract(Duration(days: _dayStart.weekday - 1));
    return ProductionScheduleRange(
      start: monday,
      end: monday.add(const Duration(days: 7)),
    );
  }

  void _move(int amount) {
    setState(() {
      _selectedDate = _selectedDate.add(
        Duration(days: amount * (_weekly ? 7 : 1)),
      );
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (selected != null) setState(() => _selectedDate = selected);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agenda e produção'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.precision_manufacturing), text: 'Produção'),
              Tab(
                icon: Icon(Icons.notifications_active_outlined),
                text: 'Pendências',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [_productionTab(context), const _PendingAgendaTab()],
        ),
      ),
    );
  }

  Widget _productionTab(BuildContext context) {
    final range = _range;
    final schedule = ref.watch(productionScheduleProvider(range));
    final date = DateFormat('dd/MM/yyyy');
    final rangeLabel = _weekly
        ? '${date.format(range.start)} a ${date.format(range.end.subtract(const Duration(days: 1)))}'
        : date.format(range.start);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productionScheduleProvider(range));
        await ref.read(productionScheduleProvider(range).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Dia'),
                        icon: Icon(Icons.today),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Semana'),
                        icon: Icon(Icons.date_range),
                      ),
                    ],
                    selected: {_weekly},
                    onSelectionChanged: (value) =>
                        setState(() => _weekly = value.first),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Anterior',
                        onPressed: () => _move(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              rangeLabel,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Próximo',
                        onPressed: () => _move(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          schedule.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _MessageCard(
              icon: Icons.error_outline,
              text: 'Não foi possível carregar a agenda: $error',
            ),
            data: (items) => _buildSchedule(context, items),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule(
    BuildContext context,
    List<ProductionScheduleItem> items,
  ) {
    if (items.isEmpty) {
      return const _MessageCard(
        icon: Icons.event_available_outlined,
        text: 'Nenhuma ordem programada neste período.',
      );
    }

    final grouped = <String, List<ProductionScheduleItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.printerName, () => []).add(item);
    }

    final conflicts = items.where((item) => item.isConflict).length;
    final occupiedMinutes = items.fold<int>(
      0,
      (total, item) => total + item.estimatedMinutes,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Ordens',
                value: items.length.toString(),
                icon: Icons.assignment_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Horas programadas',
                value: (occupiedMinutes / 60).toStringAsFixed(1),
                icon: Icons.schedule,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Conflitos',
                value: conflicts.toString(),
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...grouped.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.print_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text('${entry.value.length} ordem(ns)'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...entry.value.map((item) => _ScheduleTile(item: item)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item});

  final ProductionScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('EEE dd/MM', 'pt_BR');
    final hour = DateFormat('HH:mm');
    final subtitle =
        '${day.format(item.start)} • '
        '${hour.format(item.start)}–${hour.format(item.end)} • '
        '${item.estimatedMinutes} min';

    return ListTile(
      onTap: () => context.go('/production'),
      leading: CircleAvatar(child: Text('#${item.id}')),
      title: Text(item.projectName),
      subtitle: Text('$subtitle\n${item.status} • Prioridade ${item.priority}'),
      isThreeLine: true,
      trailing: item.isConflict
          ? const Tooltip(
              message: 'Conflito de horário nesta impressora',
              child: Icon(Icons.warning_amber_rounded),
            )
          : item.isOverdue
          ? const Tooltip(
              message: 'Ordem atrasada',
              child: Icon(Icons.timer_off_outlined),
            )
          : const Icon(Icons.chevron_right),
    );
  }
}

class _PendingAgendaTab extends ConsumerWidget {
  const _PendingAgendaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenda = ref.watch(agendaItemsProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return RefreshIndicator(
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
                _MessageCard(
                  icon: Icons.event_available_outlined,
                  text: 'Nenhuma pendência nos próximos 30 dias.',
                ),
              ],
            );
          }
          final grouped = <String, List<AgendaItem>>{};
          for (final item in items) {
            grouped
                .putIfAbsent(dateFormat.format(item.date), () => [])
                .add(item);
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
                      (item) => Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(_icon(item.type))),
                          title: Text(item.title),
                          subtitle: Text(item.subtitle),
                          trailing: item.isUrgent
                              ? const Icon(Icons.warning_amber_rounded)
                              : null,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
