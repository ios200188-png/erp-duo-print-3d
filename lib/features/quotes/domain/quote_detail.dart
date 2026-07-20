class QuoteDetail {
  const QuoteDetail({
    required this.id,
    required this.customerName,
    required this.customerDocument,
    required this.customerPhone,
    required this.customerEmail,
    required this.projectName,
    required this.projectVersion,
    required this.quantity,
    required this.materialName,
    required this.materialType,
    required this.salePrice,
    required this.totalCost,
    required this.marginPercent,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final String customerName;
  final String customerDocument;
  final String customerPhone;
  final String customerEmail;
  final String projectName;
  final String projectVersion;
  final int quantity;
  final String materialName;
  final String materialType;
  final double salePrice;
  final double totalCost;
  final double marginPercent;
  final String status;
  final String notes;
  final DateTime createdAt;

  factory QuoteDetail.fromMap(Map<String, Object?> map) {
    return QuoteDetail(
      id: map['id']! as int,
      customerName: map['customer_name']! as String,
      customerDocument: map['customer_document']! as String,
      customerPhone: map['customer_phone']! as String,
      customerEmail: map['customer_email']! as String,
      projectName: map['project_name']! as String,
      projectVersion: map['project_version']! as String,
      quantity: map['quantity']! as int,
      materialName: map['material_name']! as String,
      materialType: map['material_type']! as String,
      salePrice: (map['sale_price']! as num).toDouble(),
      totalCost: (map['total_cost']! as num).toDouble(),
      marginPercent: (map['margin_percent']! as num).toDouble(),
      status: map['status']! as String,
      notes: map['notes']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at']! as int,
      ),
    );
  }
}
