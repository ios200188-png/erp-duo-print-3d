import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/cash_transaction.dart';

final cashRepositoryProvider = Provider<CashRepository>((ref) {
  return CashRepository(ref.watch(appDatabaseProvider));
});

class CashRepository {
  CashRepository(this._database);

  final AppDatabase _database;

  Future<List<CashTransaction>> findByPeriod({
    required DateTime start,
    required DateTime end,
  }) async {
    final startMs = DateTime(
      start.year,
      start.month,
      start.day,
    ).millisecondsSinceEpoch;
    final endExclusive = DateTime(
      end.year,
      end.month,
      end.day,
    ).add(const Duration(days: 1)).millisecondsSinceEpoch;

    final rows = await _database
        .customSelect(
          '''
      SELECT id, date, description, amount, type, category, finance_entry_id
      FROM cash_transactions
      WHERE date >= ? AND date < ?
      ORDER BY date DESC, id DESC
      ''',
          variables: [
            Variable.withInt(startMs),
            Variable.withInt(endExclusive),
          ],
          readsFrom: const {},
        )
        .get();

    return rows.map((row) => CashTransaction.fromMap(row.data)).toList();
  }

  Future<CashFlowSummary> summaryByPeriod({
    required DateTime start,
    required DateTime end,
  }) async {
    final startMs = DateTime(
      start.year,
      start.month,
      start.day,
    ).millisecondsSinceEpoch;
    final endExclusive = DateTime(
      end.year,
      end.month,
      end.day,
    ).add(const Duration(days: 1)).millisecondsSinceEpoch;

    final openingRow = await _database
        .customSelect(
          '''
      SELECT COALESCE(SUM(
        CASE WHEN type = 'Receita' THEN amount ELSE -amount END
      ), 0) AS opening_balance
      FROM cash_transactions
      WHERE date < ?
      ''',
          variables: [Variable.withInt(startMs)],
          readsFrom: const {},
        )
        .getSingle();

    final periodRow = await _database
        .customSelect(
          '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'Receita' THEN amount ELSE 0 END), 0)
          AS income,
        COALESCE(SUM(CASE WHEN type = 'Despesa' THEN amount ELSE 0 END), 0)
          AS expense
      FROM cash_transactions
      WHERE date >= ? AND date < ?
      ''',
          variables: [
            Variable.withInt(startMs),
            Variable.withInt(endExclusive),
          ],
          readsFrom: const {},
        )
        .getSingle();

    return CashFlowSummary(
      openingBalance: openingRow.read<double>('opening_balance'),
      income: periodRow.read<double>('income'),
      expense: periodRow.read<double>('expense'),
    );
  }

  Future<void> synchronizePaidEntries() async {
    await _database.customStatement('''
      INSERT OR IGNORE INTO cash_transactions (
        date, description, amount, type, category, finance_entry_id, created_at
      )
      SELECT
        paid_date, description, amount, type, category, id, updated_at
      FROM financial_entries
      WHERE status = 'Pago' AND paid_date IS NOT NULL
    ''');
  }
}
