import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/quote_detail.dart';
import '../domain/quote_item.dart';
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
      SELECT q.id,
             c.name AS customer_name,
             COALESCE(
               (SELECT GROUP_CONCAT(description, ', ')
                FROM quote_items qi WHERE qi.quote_id = q.id),
               p.name
             ) AS project_name,
             q.project_id,
             COALESCE(
               (SELECT SUM(quantity) FROM quote_items qi WHERE qi.quote_id = q.id),
               q.quantity
             ) AS quantity,
             q.total_cost,
             q.sale_price,
             q.status,
             q.created_at
      FROM quotes q
      INNER JOIN customers c ON c.id = q.customer_id
      LEFT JOIN projects p ON p.id = q.project_id
      ORDER BY q.created_at DESC
      ''', readsFrom: const {}).get();

    return rows.map((row) => QuoteSummary.fromMap(row.data)).toList();
  }

  Future<QuoteDetail?> findDetail(int id) async {
    final header = await _database
        .customSelect(
          '''
      SELECT q.id,
             c.name AS customer_name,
             c.document AS customer_document,
             c.phone AS customer_phone,
             c.email AS customer_email,
             q.subtotal,
             q.discount_type,
             q.discount_value,
             q.discount_amount,
             q.sale_price,
             q.total_cost,
             q.margin_percent,
             q.status,
             q.notes,
             q.created_at
      FROM quotes q
      INNER JOIN customers c ON c.id = q.customer_id
      WHERE q.id = ?
      LIMIT 1
      ''',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .getSingleOrNull();

    if (header == null) return null;

    final itemRows = await _database
        .customSelect(
          '''
      SELECT qi.id, qi.product_id, qi.project_id, qi.filament_id,
             qi.description, p.name AS project_name,
             p.version AS project_version, f.name AS material_name,
             f.material_type, qi.quantity, qi.unit_price,
             qi.total_price, qi.total_cost
      FROM quote_items qi
      INNER JOIN projects p ON p.id = qi.project_id
      INNER JOIN filaments f ON f.id = qi.filament_id
      WHERE qi.quote_id = ?
      ORDER BY qi.id
      ''',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .get();

    return QuoteDetail(
      id: header.read<int>('id'),
      customerName: header.read<String>('customer_name'),
      customerDocument: header.read<String>('customer_document'),
      customerPhone: header.read<String>('customer_phone'),
      customerEmail: header.read<String>('customer_email'),
      items: itemRows.map((row) => QuoteItemDetail.fromMap(row.data)).toList(),
      subtotal: header.read<double>('subtotal'),
      discountType: header.read<String>('discount_type'),
      discountValue: header.read<double>('discount_value'),
      discountAmount: header.read<double>('discount_amount'),
      salePrice: header.read<double>('sale_price'),
      totalCost: header.read<double>('total_cost'),
      marginPercent: header.read<double>('margin_percent'),
      status: header.read<String>('status'),
      notes: header.read<String>('notes'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        header.read<int>('created_at'),
      ),
    );
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
    required List<QuoteItemInput> items,
    required String discountType,
    required double discountValue,
    required String notes,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('O orçamento precisa ter pelo menos um item.');
    }

    final subtotal = items.fold<double>(
      0,
      (total, item) => total + item.calculation.salePrice,
    );
    final totalCost = items.fold<double>(
      0,
      (total, item) => total + item.calculation.totalCost,
    );
    final rawDiscount = discountType == 'Valor'
        ? discountValue
        : subtotal * (discountValue / 100);
    final discountAmount = rawDiscount.clamp(0, subtotal).toDouble();
    final salePrice = subtotal - discountAmount;
    final marginPercent = salePrice <= 0
        ? 0.0
        : ((salePrice - totalCost) / salePrice) * 100;
    final now = DateTime.now().millisecondsSinceEpoch;
    final first = items.first;

    await _database.transaction(() async {
      await _database.customStatement(
        '''
        INSERT INTO quotes (
          customer_id, product_id, project_id, filament_id, quantity,
          labor_minutes, additional_cost, material_cost, energy_cost,
          machine_cost, labor_cost, packaging_cost, maintenance_cost,
          failure_cost, total_cost, margin_percent, subtotal,
          discount_type, discount_value, discount_amount, sale_price,
          status, notes, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          customerId,
          first.productId,
          first.projectId,
          first.filamentId,
          items.fold<int>(0, (total, item) => total + item.quantity),
          items.fold<int>(0, (total, item) => total + item.laborMinutes),
          items.fold<double>(0, (total, item) => total + item.additionalCost),
          items.fold<double>(
            0,
            (total, item) => total + item.calculation.materialCost,
          ),
          items.fold<double>(
            0,
            (total, item) => total + item.calculation.energyCost,
          ),
          items.fold<double>(
            0,
            (total, item) => total + item.calculation.machineCost,
          ),
          items.fold<double>(
            0,
            (total, item) => total + item.calculation.laborCost,
          ),
          items.fold<double>(
            0,
            (total, item) => total + item.calculation.packagingCost,
          ),
          items.fold<double>(
            0,
            (total, item) => total + item.calculation.maintenanceCost,
          ),
          items.fold<double>(
            0,
            (total, item) => total + item.calculation.failureCost,
          ),
          totalCost,
          marginPercent,
          subtotal,
          discountType,
          discountValue,
          discountAmount,
          salePrice,
          'Rascunho',
          notes,
          now,
          now,
        ],
      );

      final quoteIdRow = await _database
          .customSelect('SELECT last_insert_rowid() AS id', readsFrom: const {})
          .getSingle();
      final quoteId = quoteIdRow.read<int>('id');

      for (final item in items) {
        await _database.customStatement(
          '''
          INSERT INTO quote_items (
            quote_id, product_id, project_id, filament_id, description,
            quantity, labor_minutes, additional_cost, material_cost,
            energy_cost, machine_cost, labor_cost, packaging_cost,
            maintenance_cost, failure_cost, total_cost, margin_percent,
            unit_price, total_price, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            quoteId,
            item.productId,
            item.projectId,
            item.filamentId,
            item.description,
            item.quantity,
            item.laborMinutes,
            item.additionalCost,
            item.calculation.materialCost,
            item.calculation.energyCost,
            item.calculation.machineCost,
            item.calculation.laborCost,
            item.calculation.packagingCost,
            item.calculation.maintenanceCost,
            item.calculation.failureCost,
            item.calculation.totalCost,
            item.calculation.marginPercent,
            item.calculation.unitPrice(item.quantity),
            item.calculation.salePrice,
            now,
            now,
          ],
        );
      }
    });
  }

  Future<void> approve(int quoteId) async {
    await _database.transaction(() async {
      final quote = await _database
          .customSelect(
            'SELECT status FROM quotes WHERE id = ? LIMIT 1',
            variables: [Variable<int>(quoteId)],
            readsFrom: const {},
          )
          .getSingle();

      if (quote.read<String>('status') != 'Rascunho') return;

      final now = DateTime.now().millisecondsSinceEpoch;
      await _database.customStatement(
        "UPDATE quotes SET status = 'Aprovado', updated_at = ? WHERE id = ?",
        [now, quoteId],
      );

      final items = await _database
          .customSelect(
            '''
        SELECT id, product_id, project_id, filament_id, quantity
        FROM quote_items
        WHERE quote_id = ?
        ORDER BY id
        ''',
            variables: [Variable<int>(quoteId)],
            readsFrom: const {},
          )
          .get();

      for (final item in items) {
        final itemId = item.read<int>('id');
        final productId = item.readNullable<int>('product_id');
        final projectId = item.read<int>('project_id');
        final filamentId = item.read<int>('filament_id');
        final quantity = item.read<int>('quantity');

        await _database.customStatement(
          '''
          INSERT OR IGNORE INTO production_orders (
            quote_id, quote_item_id, product_id, project_id, printer_id,
            filament_id, quantity_planned, quantity_produced, status,
            priority, estimated_weight, estimated_minutes, notes,
            created_at, updated_at
          )
          SELECT ?, ?, ?, ?, p.printer_id, ?, ?, 0, 'Aguardando', 'Normal',
                 COALESCE(p.estimated_weight, pr.estimated_weight, 0) * ?,
                 COALESCE(p.print_minutes, pr.print_minutes, 0) * ?, ?, ?, ?
          FROM projects pr
          LEFT JOIN products p ON p.id = ?
          WHERE pr.id = ?
          ''',
          [
            quoteId,
            itemId,
            productId,
            projectId,
            filamentId,
            quantity,
            quantity,
            quantity,
            'Gerada automaticamente após aprovação do orçamento.',
            now,
            now,
            productId,
            projectId,
          ],
        );
      }
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
