import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/agenda_item.dart';

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  return AgendaRepository(ref.watch(appDatabaseProvider));
});

final agendaItemsProvider = FutureProvider<List<AgendaItem>>((ref) {
  return ref.watch(agendaRepositoryProvider).findUpcoming();
});

final agendaTodayCountProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(agendaRepositoryProvider).findUpcoming();
  final now = DateTime.now();
  return items.where((item) {
    return item.date.year == now.year &&
        item.date.month == now.month &&
        item.date.day == now.day;
  }).length;
});

class AgendaRepository {
  AgendaRepository(this._database);

  final AppDatabase _database;

  Future<List<AgendaItem>> findUpcoming() async {
    final items = <AgendaItem>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(const Duration(days: 30));

    final deliveries = await _database
        .customSelect(
          '''
      SELECT q.id, c.name AS customer_name, p.name AS project_name,
             q.delivery_date, q.status
      FROM quotes q
      INNER JOIN customers c ON c.id = q.customer_id
      INNER JOIN projects p ON p.id = q.project_id
      WHERE q.delivery_date IS NOT NULL
        AND q.status NOT IN ('Pago', 'Cancelado')
        AND q.delivery_date <= ?
      ORDER BY q.delivery_date
      ''',
          variables: [Variable<int>(limit.millisecondsSinceEpoch)],
          readsFrom: const {},
        )
        .get();

    for (final row in deliveries) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('delivery_date'),
      );
      items.add(
        AgendaItem(
          type: AgendaItemType.delivery,
          title: 'Entrega para ${row.read<String>('customer_name')}',
          subtitle: row.read<String>('project_name'),
          date: date,
          isUrgent: date.isBefore(today.add(const Duration(days: 1))),
          referenceId: row.read<int>('id'),
        ),
      );
    }

    final financial = await _database
        .customSelect(
          '''
      SELECT id, type, description, amount, due_date, status
      FROM financial_entries
      WHERE status = 'Pendente'
        AND due_date <= ?
      ORDER BY due_date
      ''',
          variables: [Variable<int>(limit.millisecondsSinceEpoch)],
          readsFrom: const {},
        )
        .get();

    for (final row in financial) {
      final type = row.read<String>('type');
      final date = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('due_date'),
      );
      items.add(
        AgendaItem(
          type: type == 'Receita'
              ? AgendaItemType.receivable
              : AgendaItemType.payable,
          title: type == 'Receita' ? 'Receber pagamento' : 'Pagar conta',
          subtitle: row.read<String>('description'),
          date: date,
          isUrgent: date.isBefore(today.add(const Duration(days: 1))),
          referenceId: row.read<int>('id'),
        ),
      );
    }

    final maintenance = await _database.customSelect('''
      SELECT id, name, printed_hours, maintenance_interval,
             last_maintenance_hours
      FROM printers
      WHERE active = 1
      ''', readsFrom: const {}).get();

    for (final row in maintenance) {
      final printed = row.read<double>('printed_hours');
      final interval = row.read<double>('maintenance_interval');
      final last = row.read<double>('last_maintenance_hours');
      final remaining = interval - (printed - last);

      if (remaining <= 50) {
        items.add(
          AgendaItem(
            type: AgendaItemType.maintenance,
            title: 'Manutenção de ${row.read<String>('name')}',
            subtitle: remaining <= 0
                ? 'Manutenção vencida'
                : '${remaining.toStringAsFixed(0)} h restantes',
            date: today,
            isUrgent: remaining <= 0,
            referenceId: row.read<int>('id'),
          ),
        );
      }
    }

    final stock = await _database.customSelect('''
      SELECT id, name, current_weight, minimum_stock
      FROM filaments
      WHERE current_weight <= minimum_stock
      ORDER BY current_weight
      ''', readsFrom: const {}).get();

    for (final row in stock) {
      items.add(
        AgendaItem(
          type: AgendaItemType.stock,
          title: 'Comprar ${row.read<String>('name')}',
          subtitle:
              'Restam ${row.read<double>('current_weight').toStringAsFixed(0)} g',
          date: today,
          isUrgent: true,
          referenceId: row.read<int>('id'),
        ),
      );
    }

    items.sort((a, b) {
      if (a.isUrgent != b.isUrgent) {
        return a.isUrgent ? -1 : 1;
      }
      return a.date.compareTo(b.date);
    });

    return items;
  }
}
