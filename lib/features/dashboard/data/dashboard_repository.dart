import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/dashboard_summary.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(appDatabaseProvider));
});

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).load();
});

class DashboardRepository {
  DashboardRepository(this._database);

  final AppDatabase _database;

  Future<DashboardSummary> load() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final previousMonthStart = DateTime(now.year, now.month - 1);

    final financial = await _database
        .customSelect(
          '''
      SELECT
        COALESCE(SUM(CASE
          WHEN type = 'Receita' AND status = 'Pago'
            AND paid_date >= ? AND paid_date < ?
          THEN amount ELSE 0 END), 0) AS month_revenue,
        COALESCE(SUM(CASE
          WHEN type = 'Despesa' AND status = 'Pago'
            AND paid_date >= ? AND paid_date < ?
          THEN amount ELSE 0 END), 0) AS month_expenses,
        COALESCE(SUM(CASE
          WHEN type = 'Receita' AND status = 'Pago'
            AND paid_date >= ? AND paid_date < ?
          THEN amount
          WHEN type = 'Despesa' AND status = 'Pago'
            AND paid_date >= ? AND paid_date < ?
          THEN -amount ELSE 0 END), 0) AS previous_profit,
        COALESCE(SUM(CASE
          WHEN type = 'Receita' AND status = 'Pago'
          THEN amount
          WHEN type = 'Despesa' AND status = 'Pago'
          THEN -amount
          ELSE 0 END), 0) AS cash_balance,
        COALESCE(SUM(CASE
          WHEN type = 'Receita' AND status = 'Pendente'
          THEN amount ELSE 0 END), 0) AS receivable,
        COALESCE(SUM(CASE
          WHEN type = 'Despesa' AND status = 'Pendente'
          THEN amount ELSE 0 END), 0) AS payable,
        COALESCE(SUM(CASE
          WHEN status = 'Pendente' AND due_date < ?
          THEN 1 ELSE 0 END), 0) AS overdue
      FROM financial_entries
      ''',
          variables: [
            Variable<int>(monthStart.millisecondsSinceEpoch),
            Variable<int>(nextMonth.millisecondsSinceEpoch),
            Variable<int>(monthStart.millisecondsSinceEpoch),
            Variable<int>(nextMonth.millisecondsSinceEpoch),
            Variable<int>(previousMonthStart.millisecondsSinceEpoch),
            Variable<int>(monthStart.millisecondsSinceEpoch),
            Variable<int>(previousMonthStart.millisecondsSinceEpoch),
            Variable<int>(monthStart.millisecondsSinceEpoch),
            Variable<int>(
              DateTime(now.year, now.month, now.day).millisecondsSinceEpoch,
            ),
          ],
          readsFrom: const {},
        )
        .getSingle();

    final operations = await _database
        .customSelect(
          '''
      SELECT
        (SELECT COUNT(*) FROM production_orders
          WHERE status NOT IN ('Finalizada', 'Cancelada')) AS open_production,
        (SELECT COUNT(*) FROM quotes q
          LEFT JOIN invoices i ON i.quote_id = q.id
          WHERE q.status = 'Produzido' AND i.id IS NULL) AS awaiting_billing,
        (SELECT COUNT(*) FROM filaments
          WHERE current_weight <= minimum_stock) AS low_stock,
        (SELECT COUNT(*) FROM quotes
          WHERE created_at >= ? AND created_at < ?) AS month_orders,
        (SELECT COALESCE(AVG(sale_price), 0) FROM quotes
          WHERE created_at >= ? AND created_at < ?) AS average_ticket,
        (SELECT COUNT(*) FROM production_orders
          WHERE status = 'Imprimindo') AS printers_working
      ''',
          variables: [
            Variable<int>(monthStart.millisecondsSinceEpoch),
            Variable<int>(nextMonth.millisecondsSinceEpoch),
            Variable<int>(monthStart.millisecondsSinceEpoch),
            Variable<int>(nextMonth.millisecondsSinceEpoch),
          ],
          readsFrom: const {},
        )
        .getSingle();

    final monthlyHistory = await _loadMonthlyHistory(now);
    final cashEvolution = await _loadCashEvolution(now);
    final expenseCategories = await _loadExpenseCategories(
      monthStart,
      nextMonth,
    );

    final revenue = financial.read<double>('month_revenue');
    final expenses = financial.read<double>('month_expenses');

    return DashboardSummary(
      monthRevenue: revenue,
      monthExpenses: expenses,
      monthProfit: revenue - expenses,
      previousMonthProfit: financial.read<double>('previous_profit'),
      cashBalance: financial.read<double>('cash_balance'),
      receivable: financial.read<double>('receivable'),
      payable: financial.read<double>('payable'),
      overdueFinancial: financial.read<int>('overdue'),
      openProduction: operations.read<int>('open_production'),
      awaitingBilling: operations.read<int>('awaiting_billing'),
      lowStock: operations.read<int>('low_stock'),
      monthOrders: operations.read<int>('month_orders'),
      averageTicket: operations.read<double>('average_ticket'),
      printersWorking: operations.read<int>('printers_working'),
      monthlyHistory: monthlyHistory,
      cashEvolution: cashEvolution,
      expenseCategories: expenseCategories,
    );
  }

  Future<List<MonthlyFinancePoint>> _loadMonthlyHistory(DateTime now) async {
    final firstMonth = DateTime(now.year, now.month - 11);
    final nextMonth = DateTime(now.year, now.month + 1);

    final rows = await _database
        .customSelect(
          '''
      SELECT
        CAST(strftime('%Y', paid_date / 1000, 'unixepoch', 'localtime') AS INTEGER) AS year,
        CAST(strftime('%m', paid_date / 1000, 'unixepoch', 'localtime') AS INTEGER) AS month,
        COALESCE(SUM(CASE WHEN type = 'Receita' THEN amount ELSE 0 END), 0) AS revenue,
        COALESCE(SUM(CASE WHEN type = 'Despesa' THEN amount ELSE 0 END), 0) AS expenses
      FROM financial_entries
      WHERE status = 'Pago' AND paid_date >= ? AND paid_date < ?
      GROUP BY year, month
      ORDER BY year, month
      ''',
          variables: [
            Variable<int>(firstMonth.millisecondsSinceEpoch),
            Variable<int>(nextMonth.millisecondsSinceEpoch),
          ],
          readsFrom: const {},
        )
        .get();

    final values = <String, MonthlyFinancePoint>{};
    for (final row in rows) {
      final year = row.read<int>('year');
      final month = row.read<int>('month');
      values['$year-$month'] = MonthlyFinancePoint(
        month: DateTime(year, month),
        revenue: row.read<double>('revenue'),
        expenses: row.read<double>('expenses'),
      );
    }

    return List.generate(12, (index) {
      final date = DateTime(firstMonth.year, firstMonth.month + index);
      return values['${date.year}-${date.month}'] ??
          MonthlyFinancePoint(month: date, revenue: 0, expenses: 0);
    });
  }

  Future<List<CashPoint>> _loadCashEvolution(DateTime now) async {
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29));
    final end = DateTime(now.year, now.month, now.day + 1);

    final before = await _database
        .customSelect(
          '''
      SELECT COALESCE(SUM(CASE
        WHEN type = 'Receita' THEN amount
        WHEN type = 'Despesa' THEN -amount
        ELSE 0 END), 0) AS balance
      FROM financial_entries
      WHERE status = 'Pago' AND paid_date < ?
      ''',
          variables: [Variable<int>(start.millisecondsSinceEpoch)],
          readsFrom: const {},
        )
        .getSingle();

    final rows = await _database
        .customSelect(
          '''
      SELECT
        date(paid_date / 1000, 'unixepoch', 'localtime') AS day,
        COALESCE(SUM(CASE
          WHEN type = 'Receita' THEN amount
          WHEN type = 'Despesa' THEN -amount
          ELSE 0 END), 0) AS movement
      FROM financial_entries
      WHERE status = 'Pago' AND paid_date >= ? AND paid_date < ?
      GROUP BY day
      ORDER BY day
      ''',
          variables: [
            Variable<int>(start.millisecondsSinceEpoch),
            Variable<int>(end.millisecondsSinceEpoch),
          ],
          readsFrom: const {},
        )
        .get();

    final movements = <String, double>{
      for (final row in rows)
        row.read<String>('day'): row.read<double>('movement'),
    };

    var balance = before.read<double>('balance');
    return List.generate(30, (index) {
      final date = DateTime(start.year, start.month, start.day + index);
      final key =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      balance += movements[key] ?? 0;
      return CashPoint(date: date, balance: balance);
    });
  }

  Future<List<ExpenseCategoryPoint>> _loadExpenseCategories(
    DateTime monthStart,
    DateTime nextMonth,
  ) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT
        CASE WHEN TRIM(category) = '' THEN 'Sem categoria' ELSE category END AS category_name,
        COALESCE(SUM(amount), 0) AS total
      FROM financial_entries
      WHERE type = 'Despesa' AND status = 'Pago'
        AND paid_date >= ? AND paid_date < ?
      GROUP BY category_name
      ORDER BY total DESC
      LIMIT 6
      ''',
          variables: [
            Variable<int>(monthStart.millisecondsSinceEpoch),
            Variable<int>(nextMonth.millisecondsSinceEpoch),
          ],
          readsFrom: const {},
        )
        .get();

    return rows
        .map(
          (row) => ExpenseCategoryPoint(
            category: row.read<String>('category_name'),
            amount: row.read<double>('total'),
          ),
        )
        .toList(growable: false);
  }
}
