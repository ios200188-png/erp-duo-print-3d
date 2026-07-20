import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/financial_entry.dart';

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(appDatabaseProvider)),
);

final financialEntriesProvider = FutureProvider<List<FinancialEntry>>(
  (ref) => ref.watch(financeRepositoryProvider).findAll(),
);

final financeSummaryProvider = FutureProvider<FinanceSummary>(
  (ref) => ref.watch(financeRepositoryProvider).summary(),
);

class FinanceRepository {
  FinanceRepository(this._database);

  final AppDatabase _database;

  Future<List<FinancialEntry>> findAll() async {
    final rows = await _database
        .customSelect(
          'SELECT id,type,category,description,amount,paid_amount,due_date,paid_date,status,notes '
          'FROM financial_entries '
          "ORDER BY CASE status WHEN 'Pendente' THEN 1 WHEN 'Parcial' THEN 2 ELSE 3 END, "
          'due_date ASC',
          readsFrom: const {},
        )
        .get();

    return rows.map((row) => FinancialEntry.fromMap(row.data)).toList();
  }

  Future<FinanceSummary> summary() async {
    final row = await _database
        .customSelect(
          "SELECT "
          "COALESCE(SUM(CASE WHEN type='Receita' THEN paid_amount ELSE 0 END),0) income_paid,"
          "COALESCE(SUM(CASE WHEN type='Despesa' THEN paid_amount ELSE 0 END),0) expense_paid,"
          "COALESCE(SUM(CASE WHEN type='Receita' THEN MAX(amount-paid_amount,0) ELSE 0 END),0) receivable,"
          "COALESCE(SUM(CASE WHEN type='Despesa' THEN MAX(amount-paid_amount,0) ELSE 0 END),0) payable "
          'FROM financial_entries',
          readsFrom: const {},
        )
        .getSingle();

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

    await _database.transaction(() async {
      await _database.customStatement(
        'INSERT INTO financial_entries('
        'type,category,description,amount,paid_amount,due_date,paid_date,status,'
        'notes,created_at,updated_at'
        ') VALUES(?,?,?,?,?,?,?,?,?,?,?)',
        [
          type,
          category,
          description,
          amount,
          paid ? amount : 0,
          dueDate.millisecondsSinceEpoch,
          paid ? now : null,
          paid ? 'Pago' : 'Pendente',
          notes,
          now,
          now,
        ],
      );

      if (paid) {
        await _database.customStatement(
          'INSERT INTO cash_transactions('
          'date,description,amount,type,category,finance_entry_id,created_at'
          ') '
          'SELECT paid_date,description,paid_amount,type,category,id,? '
          'FROM financial_entries WHERE id=last_insert_rowid()',
          [now],
        );
      }
    });
  }

  Future<void> registerPayment({
    required FinancialEntry entry,
    required double amount,
  }) async {
    if (amount <= 0 || amount > entry.remainingAmount) {
      throw ArgumentError('Valor inválido');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final total = entry.paidAmount + amount;

    // Evita problemas de arredondamento com valores decimais.
    const epsilon = 0.001;
    final isFullyPaid = (entry.amount - total).abs() < epsilon;

    await _database.transaction(() async {
      await _database.customStatement(
        'UPDATE financial_entries '
        'SET paid_amount=?,status=?,paid_date=?,updated_at=? '
        'WHERE id=?',
        [total, isFullyPaid ? 'Pago' : 'Parcial', now, now, entry.id],
      );

      await _database.customStatement(
        'INSERT INTO cash_transactions('
        'date,description,amount,type,category,finance_entry_id,created_at'
        ') VALUES(?,?,?,?,?,?,?) '
        'ON CONFLICT(finance_entry_id) DO UPDATE SET '
        'date=excluded.date,'
        'description=excluded.description,'
        'amount=excluded.amount,'
        'type=excluded.type,'
        'category=excluded.category',
        [
          now,
          entry.description,
          total,
          entry.type,
          entry.category,
          entry.id,
          now,
        ],
      );
    });
  }

  Future<void> togglePaid(int id, bool paid) async {
    final rows = await _database
        .customSelect(
          'SELECT id,type,category,description,amount,paid_amount,due_date,'
          'paid_date,status,notes '
          'FROM financial_entries WHERE id=?',
          variables: [Variable<int>(id)],
          readsFrom: const {},
        )
        .get();

    if (rows.isEmpty) {
      return;
    }

    final entry = FinancialEntry.fromMap(rows.single.data);

    if (paid) {
      await registerPayment(entry: entry, amount: entry.remainingAmount);
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.transaction(() async {
      await _database.customStatement(
        "UPDATE financial_entries "
        "SET status='Pendente',paid_amount=0,paid_date=NULL,updated_at=? "
        'WHERE id=?',
        [now, id],
      );

      await _database.customStatement(
        'DELETE FROM cash_transactions WHERE finance_entry_id=?',
        [id],
      );
    });
  }

  Future<void> delete(int id) async {
    await _database.transaction(() async {
      await _database.customStatement(
        'DELETE FROM cash_transactions WHERE finance_entry_id=?',
        [id],
      );

      await _database.customStatement(
        'DELETE FROM financial_entries WHERE id=?',
        [id],
      );
    });
  }
}
