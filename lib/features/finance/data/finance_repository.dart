import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/financial_entry.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.watch(appDatabaseProvider));
});

final financialEntriesProvider = FutureProvider<List<FinancialEntry>>((ref) {
  return ref.watch(financeRepositoryProvider).findAll();
});

final financeSummaryProvider = FutureProvider<FinanceSummary>((ref) {
  return ref.watch(financeRepositoryProvider).summary();
});

class FinanceRepository {
  FinanceRepository(this._database);

  final AppDatabase _database;

  Future<List<FinancialEntry>> findAll() async {
    final rows = await _database.customSelect(
      '''
      SELECT id, type, category, description, amount, due_date,
             paid_date, status, notes
      FROM financial_entries
      ORDER BY
        CASE status WHEN 'Pendente' THEN 1 ELSE 2 END,
        due_date ASC
      ''',
      readsFrom: const {},
    ).get();

    return rows.map((row) => FinancialEntry.fromMap(row.data)).toList();
  }

  Future<FinanceSummary> summary() async {
    final row = await _database.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'Receita' AND status = 'Pago'
          THEN amount ELSE 0 END), 0) AS income_paid,
        COALESCE(SUM(CASE WHEN type = 'Despesa' AND status = 'Pago'
          THEN amount ELSE 0 END), 0) AS expense_paid,
        COALESCE(SUM(CASE WHEN type = 'Receita' AND status = 'Pendente'
          THEN amount ELSE 0 END), 0) AS receivable,
        COALESCE(SUM(CASE WHEN type = 'Despesa' AND status = 'Pendente'
          THEN amount ELSE 0 END), 0) AS payable
      FROM financial_entries
      ''',
      readsFrom: const {},
    ).getSingle();

    return FinanceSummary(
      incomePaid: row.read<double>('income_paid'),
      expensePaid: row.read<double>('expense_paid'),
      receivable: row.read<double>('receivable'),
      payable: row.read<double>('payable'),
    );
  }

  Future<void> save({
    required String type,
    required String category,
    required String description,
    required double amount,
    required DateTime dueDate,
    required bool paid,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.customStatement(
      '''
      INSERT INTO financial_entries (
        type, category, description, amount, due_date, paid_date,
        status, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        type,
        category,
        description,
        amount,
        dueDate.millisecondsSinceEpoch,
        paid ? now : null,
        paid ? 'Pago' : 'Pendente',
        notes,
        now,
        now,
      ],
    );
  }

  Future<void> togglePaid(int id, bool paid) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.customStatement(
      '''
      UPDATE financial_entries
      SET status = ?, paid_date = ?, updated_at = ?
      WHERE id = ?
      ''',
      [paid ? 'Pago' : 'Pendente', paid ? now : null, now, id],
    );
  }

  Future<void> delete(int id) async {
    await _database.customStatement(
      'DELETE FROM financial_entries WHERE id = ?',
      [id],
    );
  }
}
