class DashboardSummary {
  const DashboardSummary({
    required this.monthRevenue,
    required this.monthExpenses,
    required this.monthProfit,
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
  });

  final double monthRevenue;
  final double monthExpenses;
  final double monthProfit;
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
}
