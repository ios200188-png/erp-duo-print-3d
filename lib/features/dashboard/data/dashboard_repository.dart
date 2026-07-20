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

    final financial = await _database.customSelect(
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
        Variable<int>(DateTime(now.year, now.month, now.day)
            .millisecondsSinceEpoch),
      ],
      readsFrom: const {},
    ).getSingle();

    final operations = await _database.customSelect(
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
    ).getSingle();

    final revenue = financial.read<double>('month_revenue');
    final expenses = financial.read<double>('month_expenses');

    return DashboardSummary(
      monthRevenue: revenue,
      monthExpenses: expenses,
      monthProfit: revenue - expenses,
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
    );
  }
}
