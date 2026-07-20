class FinancialEntry {
  const FinancialEntry({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.paidAmount,
    required this.dueDate,
    required this.paidDate,
    required this.status,
    required this.notes,
  });
  final int id;
  final String type;
  final String category;
  final String description;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status;
  final String notes;
  double get remainingAmount => (amount - paidAmount).clamp(0, amount);
  bool get isOverdue => status != 'Pago' && dueDate.isBefore(DateTime.now());
  String get displayStatus => isOverdue ? 'Vencido' : status;
  factory FinancialEntry.fromMap(Map<String, Object?> map) {
    final paid = map['paid_date'] as int?;
    return FinancialEntry(
      id: map['id']! as int,
      type: map['type']! as String,
      category: map['category']! as String,
      description: map['description']! as String,
      amount: (map['amount']! as num).toDouble(),
      paidAmount: (map['paid_amount'] as num? ?? 0).toDouble(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date']! as int),
      paidDate: paid == null ? null : DateTime.fromMillisecondsSinceEpoch(paid),
      status: map['status']! as String,
      notes: map['notes']! as String,
    );
  }
}

class FinanceSummary {
  const FinanceSummary({
    required this.incomePaid,
    required this.expensePaid,
    required this.receivable,
    required this.payable,
  });
  final double incomePaid, expensePaid, receivable, payable;
  double get balance => incomePaid - expensePaid;
}
