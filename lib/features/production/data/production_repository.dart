import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/production_order.dart';

final productionRepositoryProvider = Provider<ProductionRepository>((ref) {
  return ProductionRepository(ref.watch(appDatabaseProvider));
});

final productionOrdersProvider = FutureProvider<List<ProductionOrder>>((ref) {
  return ref.watch(productionRepositoryProvider).findAll();
});

final productionOpenCountProvider = FutureProvider<int>((ref) {
  return ref.watch(productionRepositoryProvider).openCount();
});

class ProductionRepository {
  ProductionRepository(this._database);

  final AppDatabase _database;

  Future<List<ProductionOrder>> findAll() async {
    final rows = await _database.customSelect(
      '''
      SELECT po.id, p.name AS project_name, pr.name AS printer_name,
             po.quantity_planned, po.quantity_produced, po.status,
             po.priority, po.scheduled_date, po.notes
      FROM production_orders po
      INNER JOIN projects p ON p.id = po.project_id
      LEFT JOIN printers pr ON pr.id = po.printer_id
      ORDER BY
        CASE po.status
          WHEN 'Imprimindo' THEN 1
          WHEN 'Planejada' THEN 2
          WHEN 'Pausada' THEN 3
          ELSE 4
        END,
        po.created_at DESC
      ''',
      readsFrom: const {},
    ).get();

    return rows.map((row) => ProductionOrder.fromMap(row.data)).toList();
  }

  Future<int> openCount() async {
    final row = await _database.customSelect(
      '''
      SELECT COUNT(*) AS total
      FROM production_orders
      WHERE status NOT IN ('Finalizada', 'Cancelada')
      ''',
      readsFrom: const {},
    ).getSingle();
    return row.read<int>('total');
  }

  Future<void> save({
    required int projectId,
    int? printerId,
    required int quantityPlanned,
    required int quantityProduced,
    required String status,
    required String priority,
    DateTime? scheduledDate,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final startedAt = status == 'Imprimindo' ? now : null;
    final finishedAt = status == 'Finalizada' ? now : null;

    await _database.customStatement(
      '''
      INSERT INTO production_orders (
        project_id, printer_id, quantity_planned, quantity_produced,
        status, priority, scheduled_date, started_at, finished_at,
        notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        projectId,
        printerId,
        quantityPlanned,
        quantityProduced,
        status,
        priority,
        scheduledDate?.millisecondsSinceEpoch,
        startedAt,
        finishedAt,
        notes,
        now,
        now,
      ],
    );
  }

  Future<void> updateStatus(
    int id,
    String status, {
    int? quantityProduced,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final startedAt = status == 'Imprimindo' ? now : null;
    final finishedAt = status == 'Finalizada' ? now : null;

    await _database.transaction(() async {
      await _database.customStatement(
        '''
        UPDATE production_orders
        SET status = ?,
            quantity_produced = COALESCE(?, quantity_produced),
            started_at = COALESCE(started_at, ?),
            finished_at = COALESCE(?, finished_at),
            updated_at = ?
        WHERE id = ?
        ''',
        [status, quantityProduced, startedAt, finishedAt, now, id],
      );

      if (status == 'Finalizada') {
        final linkedQuote = await _database.customSelect(
          '''
          SELECT quote_id
          FROM production_orders
          WHERE id = ?
          LIMIT 1
          ''',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        ).getSingleOrNull();

        final quoteId = linkedQuote?.readNullable<int>('quote_id');
        if (quoteId != null) {
          await _database.customStatement(
            '''
            UPDATE quotes
            SET status = 'Produzido', updated_at = ?
            WHERE id = ?
            ''',
            [now, quoteId],
          );
        }
      }
    });
  }

  Future<void> delete(int id) async {
    await _database.customStatement(
      'DELETE FROM production_orders WHERE id = ?',
      [id],
    );
  }
}
