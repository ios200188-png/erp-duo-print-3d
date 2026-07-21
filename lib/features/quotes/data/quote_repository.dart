import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/quote_calculation.dart';
import '../domain/quote_detail.dart';
import '../domain/quote_summary.dart';

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository(ref.watch(appDatabaseProvider));
});

final quotesProvider = FutureProvider<List<QuoteSummary>>((ref) {
  return ref.watch(quoteRepositoryProvider).findAll();
});

final quoteCountProvider = FutureProvider<int>((ref) {
  return ref.watch(quoteRepositoryProvider).count();
});

final quoteDetailProvider = FutureProvider.family<QuoteDetail?, int>((ref, id) {
  return ref.watch(quoteRepositoryProvider).findDetail(id);
});

class QuoteRepository {
  QuoteRepository(this._database);

  final AppDatabase _database;

  Future<List<QuoteSummary>> findAll() async {
    final rows = await _database.customSelect('''
      SELECT q.id, c.name AS customer_name, p.name AS project_name,
             q.project_id, q.quantity, q.total_cost, q.sale_price,
             q.status, q.created_at
      FROM quotes q
      INNER JOIN customers c ON c.id = q.customer_id
      INNER JOIN projects p ON p.id = q.project_id
      ORDER BY q.created_at DESC
      ''', readsFrom: const {}).get();

    return rows.map((row) => QuoteSummary.fromMap(row.data)).toList();
  }

  Future<QuoteDetail?> findDetail(int id) async {
    final row = await _database
        .customSelect(
          '''
      SELECT q.id,
             c.name AS customer_name,
             c.document AS customer_document,
             c.phone AS customer_phone,
             c.email AS customer_email,
             p.name AS project_name,
             p.version AS project_version,
             q.quantity,
             f.name AS material_name,
             f.material_type,
             q.sale_price,
             q.total_cost,
             q.margin_percent,
             q.status,
             q.notes,
             q.created_at
      FROM quotes q
      INNER JOIN customers c ON c.id = q.customer_id
      INNER JOIN projects p ON p.id = q.project_id
      INNER JOIN filaments f ON f.id = q.filament_id
      WHERE q.id = ?
      LIMIT 1
      ''',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .getSingleOrNull();

    return row == null ? null : QuoteDetail.fromMap(row.data);
  }

  Future<int> count() async {
    final row = await _database
        .customSelect(
          'SELECT COUNT(*) AS total FROM quotes',
          readsFrom: const {},
        )
        .getSingle();

    return row.read<int>('total');
  }

  Future<void> save({
    required int customerId,
    required int projectId,
    required int filamentId,
    required int quantity,
    required int laborMinutes,
    required double additionalCost,
    required QuoteCalculation calculation,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.customStatement(
      '''
      INSERT INTO quotes (
        customer_id, project_id, filament_id, quantity, labor_minutes,
        additional_cost, material_cost, energy_cost, machine_cost,
        labor_cost, packaging_cost, maintenance_cost, failure_cost,
        total_cost, margin_percent, sale_price, status, notes,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        customerId,
        projectId,
        filamentId,
        quantity,
        laborMinutes,
        additionalCost,
        calculation.materialCost,
        calculation.energyCost,
        calculation.machineCost,
        calculation.laborCost,
        calculation.packagingCost,
        calculation.maintenanceCost,
        calculation.failureCost,
        calculation.totalCost,
        calculation.marginPercent,
        calculation.salePrice,
        'Rascunho',
        notes,
        now,
        now,
      ],
    );
  }

  Future<void> approve(int quoteId) async {
    await _database.transaction(() async {
      final quote = await _database
          .customSelect(
            '''
        SELECT id, project_id, quantity, status
        FROM quotes
        WHERE id = ?
        LIMIT 1
        ''',
            variables: [Variable<int>(quoteId)],
            readsFrom: const {},
          )
          .getSingle();

      if (quote.read<String>('status') != 'Rascunho') return;

      final now = DateTime.now().millisecondsSinceEpoch;
      await _database.customStatement(
        '''
        UPDATE quotes
        SET status = 'Aprovado', updated_at = ?
        WHERE id = ?
        ''',
        [now, quoteId],
      );

      await _database.customStatement(
        '''
        INSERT OR IGNORE INTO production_orders (
          quote_id, project_id, quantity_planned, quantity_produced,
          status, priority, notes, created_at, updated_at
        ) VALUES (?, ?, ?, 0, 'Aguardando', 'Normal', ?, ?, ?)
        ''',
        [
          quoteId,
          quote.read<int>('project_id'),
          quote.read<int>('quantity'),
          'Gerada automaticamente após aprovação do orçamento.',
          now,
          now,
        ],
      );
    });
  }

  Future<int> producedAwaitingInvoiceCount() async {
    final row = await _database.customSelect('''
      SELECT COUNT(*) AS total
      FROM quotes q
      LEFT JOIN invoices i ON i.quote_id = q.id
      WHERE q.status = 'Produzido' AND i.id IS NULL
      ''', readsFrom: const {}).getSingle();
    return row.read<int>('total');
  }

  Future<void> delete(int id) async {
    await _database.customStatement('DELETE FROM quotes WHERE id = ?', [id]);
  }
}
