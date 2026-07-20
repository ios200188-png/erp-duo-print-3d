class DashboardSummary {
  const DashboardSummary({
    required this.monthRevenue,
    required this.monthExpenses,
    required this.monthProfit,
    required this.previousMonthProfit,
    required this.cashBalance,
    required this.receivable,
    required this.payable,
    required this.openProduction,
    required this.awaitingBilling,
    required this.lowStock,
    required this.overdueFinancial,
    required this.monthOrders,
    required this.averageTicket,
    required this.printersWorking,
    required this.monthlyHistory,
    required this.cashEvolution,
    required this.expenseCategories,
  });

  final double monthRevenue;
  final double monthExpenses;
  final double monthProfit;
  final double previousMonthProfit;
  final double cashBalance;
  final double receivable;
  final double payable;
  final int openProduction;
  final int awaitingBilling;
  final int lowStock;
  final int overdueFinancial;
  final int monthOrders;
  final double averageTicket;
  final int printersWorking;
  final List<MonthlyFinancePoint> monthlyHistory;
  final List<CashPoint> cashEvolution;
  final List<ExpenseCategoryPoint> expenseCategories;

  double get profitVariationPercent {
    if (previousMonthProfit == 0) {
      return monthProfit == 0 ? 0 : 100;
    }
    return ((monthProfit - previousMonthProfit) / previousMonthProfit.abs()) *
        100;
  }
}

class MonthlyFinancePoint {
  const MonthlyFinancePoint({
    required this.month,
    required this.revenue,
    required this.expenses,
  });

  final DateTime month;
  final double revenue;
  final double expenses;

  double get profit => revenue - expenses;
}

class CashPoint {
  const CashPoint({required this.date, required this.balance});

  final DateTime date;
  final double balance;
}

class ExpenseCategoryPoint {
  const ExpenseCategoryPoint({required this.category, required this.amount});

  final String category;
  final double amount;
}
