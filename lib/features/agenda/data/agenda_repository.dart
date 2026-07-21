import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/agenda_item.dart';
import '../domain/production_schedule_item.dart';

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

  Future<List<ProductionScheduleItem>> findProductionSchedule({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT po.id, p.name AS project_name,
             COALESCE(pr.name, 'Sem impressora') AS printer_name,
             po.status, po.priority, po.scheduled_date,
             po.estimated_minutes
      FROM production_orders po
      INNER JOIN projects p ON p.id = po.project_id
      LEFT JOIN printers pr ON pr.id = po.printer_id
      WHERE po.scheduled_date IS NOT NULL
        AND po.status <> 'Cancelada'
        AND po.scheduled_date >= ?
        AND po.scheduled_date < ?
      ORDER BY printer_name, po.scheduled_date, po.priority DESC
      ''',
          variables: [
            Variable<int>(start.millisecondsSinceEpoch),
            Variable<int>(end.millisecondsSinceEpoch),
          ],
          readsFrom: const {},
        )
        .get();

    final raw = rows.map((row) {
      final scheduled = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('scheduled_date'),
      );
      final minutes = row.read<int>('estimated_minutes');
      return ProductionScheduleItem(
        id: row.read<int>('id'),
        projectName: row.read<String>('project_name'),
        printerName: row.read<String>('printer_name'),
        status: row.read<String>('status'),
        priority: row.read<String>('priority'),
        start: scheduled,
        end: scheduled.add(Duration(minutes: minutes <= 0 ? 1 : minutes)),
        estimatedMinutes: minutes,
        isConflict: false,
      );
    }).toList();

    return raw.map((item) {
      final conflict = raw.any((other) {
        if (item.printerName == 'Sem impressora' ||
            other.id == item.id ||
            other.printerName != item.printerName) {
          return false;
        }
        return item.start.isBefore(other.end) && item.end.isAfter(other.start);
      });
      return ProductionScheduleItem(
        id: item.id,
        projectName: item.projectName,
        printerName: item.printerName,
        status: item.status,
        priority: item.priority,
        start: item.start,
        end: item.end,
        estimatedMinutes: item.estimatedMinutes,
        isConflict: conflict,
      );
    }).toList();
  }
}

final productionScheduleProvider =
    FutureProvider.family<
      List<ProductionScheduleItem>,
      ProductionScheduleRange
    >((ref, range) {
      return ref
          .watch(agendaRepositoryProvider)
          .findProductionSchedule(start: range.start, end: range.end);
    });
