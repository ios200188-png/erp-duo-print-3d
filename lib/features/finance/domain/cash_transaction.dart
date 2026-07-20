class CashTransaction {
  const CashTransaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.financeEntryId,
  });

  final int id;
  final DateTime date;
  final String description;
  final double amount;
  final String type;
  final String category;
  final int? financeEntryId;

  bool get isIncome => type == 'Receita';
  double get signedAmount => isIncome ? amount : -amount;

  factory CashTransaction.fromMap(Map<String, Object?> map) {
    return CashTransaction(
      id: map['id']! as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date']! as int),
      description: map['description']! as String,
      amount: (map['amount']! as num).toDouble(),
      type: map['type']! as String,
      category: map['category']! as String,
      financeEntryId: map['finance_entry_id'] as int?,
    );
  }
}

class CashFlowSummary {
  const CashFlowSummary({
    required this.openingBalance,
    required this.income,
    required this.expense,
  });

  final double openingBalance;
  final double income;
  final double expense;

  double get periodResult => income - expense;
  double get closingBalance => openingBalance + periodResult;
}
