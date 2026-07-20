import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/invoice.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(ref.watch(appDatabaseProvider));
});

final invoicesProvider = FutureProvider<List<Invoice>>((ref) {
  return ref.watch(billingRepositoryProvider).findInvoices();
});

final billableQuotesProvider = FutureProvider<List<BillableQuote>>((ref) {
  return ref.watch(billingRepositoryProvider).findBillableQuotes();
});

final awaitingBillingCountProvider = FutureProvider<int>((ref) {
  return ref.watch(billingRepositoryProvider).awaitingCount();
});

class BillingRepository {
  BillingRepository(this._database);

  final AppDatabase _database;

  Future<List<BillableQuote>> findBillableQuotes() async {
    final rows = await _database.customSelect('''
      SELECT q.id, c.name AS customer_name, p.name AS project_name,
             q.quantity, q.sale_price
      FROM quotes q
      INNER JOIN customers c ON c.id = q.customer_id
      INNER JOIN projects p ON p.id = q.project_id
      LEFT JOIN invoices i ON i.quote_id = q.id
      WHERE q.status = 'Produzido' AND i.id IS NULL
      ORDER BY q.updated_at DESC
      ''', readsFrom: const {}).get();

    return rows.map((row) => BillableQuote.fromMap(row.data)).toList();
  }

  Future<List<Invoice>> findInvoices() async {
    final rows = await _database.customSelect('''
      SELECT i.id, i.quote_id, c.name AS customer_name,
             c.document AS customer_document, c.phone AS customer_phone,
             c.email AS customer_email, p.name AS project_name,
             q.quantity, q.sale_price, i.payment_method, i.due_date,
             i.status, i.notes, i.issued_at
      FROM invoices i
      INNER JOIN quotes q ON q.id = i.quote_id
      INNER JOIN customers c ON c.id = q.customer_id
      INNER JOIN projects p ON p.id = q.project_id
      ORDER BY i.issued_at DESC
      ''', readsFrom: const {}).get();

    return rows.map((row) => Invoice.fromMap(row.data)).toList();
  }

  Future<int> awaitingCount() async {
    final row = await _database.customSelect('''
      SELECT COUNT(*) AS total
      FROM quotes q
      LEFT JOIN invoices i ON i.quote_id = q.id
      WHERE q.status = 'Produzido' AND i.id IS NULL
      ''', readsFrom: const {}).getSingle();

    return row.read<int>('total');
  }

  Future<int> issue({
    required int quoteId,
    required String paymentMethod,
    required DateTime dueDate,
    required String notes,
  }) async {
    return _database.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final quote = await _database
          .customSelect(
            '''
        SELECT sale_price
        FROM quotes
        WHERE id = ? AND status = 'Produzido'
        LIMIT 1
        ''',
            variables: [Variable<int>(quoteId)],
            readsFrom: const {},
          )
          .getSingle();

      await _database.customStatement(
        '''
        INSERT INTO invoices (
          quote_id, payment_method, due_date, status, notes,
          issued_at, created_at, updated_at
        ) VALUES (?, ?, ?, 'Emitida', ?, ?, ?, ?)
        ''',
        [
          quoteId,
          paymentMethod,
          dueDate.millisecondsSinceEpoch,
          notes,
          now,
          now,
          now,
        ],
      );

      final invoiceIdRow = await _database
          .customSelect('SELECT last_insert_rowid() AS id', readsFrom: const {})
          .getSingle();

      await _database.customStatement(
        '''
        INSERT INTO financial_entries (
          type, category, description, amount, due_date, status,
          quote_id, notes, created_at, updated_at
        ) VALUES (
          'Receita', 'Vendas', ?, ?, ?, 'Pendente', ?, ?, ?, ?
        )
        ''',
        [
          'Faturamento do orçamento #$quoteId',
          quote.read<double>('sale_price'),
          dueDate.millisecondsSinceEpoch,
          quoteId,
          'Gerado automaticamente pelo faturamento.',
          now,
          now,
        ],
      );

      await _database.customStatement(
        '''
        UPDATE quotes
        SET status = 'Faturado', updated_at = ?
        WHERE id = ?
        ''',
        [now, quoteId],
      );

      return invoiceIdRow.read<int>('id');
    });
  }

  Future<void> markPaid(Invoice invoice) async {
    await _database.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await _database.customStatement(
        '''
        UPDATE invoices
        SET status = 'Pago', paid_at = ?, updated_at = ?
        WHERE id = ?
        ''',
        [now, now, invoice.id],
      );

      await _database.customStatement(
        '''
        UPDATE financial_entries
        SET status = 'Pago', paid_amount = amount, paid_date = ?, updated_at = ?
        WHERE quote_id = ? AND type = 'Receita'
        ''',
        [now, now, invoice.quoteId],
      );

      await _database.customStatement(
        '''
        INSERT INTO cash_transactions (
          date, description, amount, type, category,
          finance_entry_id, created_at
        )
        SELECT paid_date, description, paid_amount, type, category, id, ?
        FROM financial_entries
        WHERE quote_id = ? AND type = 'Receita'
        ON CONFLICT(finance_entry_id) DO UPDATE SET
          date = excluded.date,
          amount = excluded.amount,
          description = excluded.description
        ''',
        [now, invoice.quoteId],
      );

      await _database.customStatement(
        '''
        UPDATE quotes
        SET status = 'Pago', updated_at = ?
        WHERE id = ?
        ''',
        [now, invoice.quoteId],
      );
    });
  }
}
