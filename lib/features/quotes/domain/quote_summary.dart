class QuoteSummary {
  const QuoteSummary({
    required this.id,
    required this.customerName,
    required this.projectName,
    required this.projectId,
    required this.quantity,
    required this.totalCost,
    required this.salePrice,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String customerName;
  final String projectName;
  final int projectId;
  final int quantity;
  final double totalCost;
  final double salePrice;
  final String status;
  final DateTime createdAt;

  factory QuoteSummary.fromMap(Map<String, Object?> map) {
    return QuoteSummary(
      id: map['id']! as int,
      customerName: map['customer_name']! as String,
      projectName: map['project_name']! as String,
      projectId: map['project_id']! as int,
      quantity: map['quantity']! as int,
      totalCost: (map['total_cost']! as num).toDouble(),
      salePrice: (map['sale_price']! as num).toDouble(),
      status: map['status']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at']! as int,
      ),
    );
  }
}
