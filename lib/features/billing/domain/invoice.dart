class Invoice {
  const Invoice({
    required this.id,
    required this.quoteId,
    required this.customerName,
    required this.customerDocument,
    required this.customerPhone,
    required this.customerEmail,
    required this.projectName,
    required this.quantity,
    required this.salePrice,
    required this.paymentMethod,
    required this.dueDate,
    required this.status,
    required this.notes,
    required this.issuedAt,
  });

  final int id;
  final int quoteId;
  final String customerName;
  final String customerDocument;
  final String customerPhone;
  final String customerEmail;
  final String projectName;
  final int quantity;
  final double salePrice;
  final String paymentMethod;
  final DateTime dueDate;
  final String status;
  final String notes;
  final DateTime issuedAt;

  factory Invoice.fromMap(Map<String, Object?> map) {
    return Invoice(
      id: map['id']! as int,
      quoteId: map['quote_id']! as int,
      customerName: map['customer_name']! as String,
      customerDocument: map['customer_document']! as String,
      customerPhone: map['customer_phone']! as String,
      customerEmail: map['customer_email']! as String,
      projectName: map['project_name']! as String,
      quantity: map['quantity']! as int,
      salePrice: (map['sale_price']! as num).toDouble(),
      paymentMethod: map['payment_method']! as String,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date']! as int),
      status: map['status']! as String,
      notes: map['notes']! as String,
      issuedAt: DateTime.fromMillisecondsSinceEpoch(map['issued_at']! as int),
    );
  }
}

class BillableQuote {
  const BillableQuote({
    required this.id,
    required this.customerName,
    required this.projectName,
    required this.quantity,
    required this.salePrice,
  });

  final int id;
  final String customerName;
  final String projectName;
  final int quantity;
  final double salePrice;

  factory BillableQuote.fromMap(Map<String, Object?> map) {
    return BillableQuote(
      id: map['id']! as int,
      customerName: map['customer_name']! as String,
      projectName: map['project_name']! as String,
      quantity: map['quantity']! as int,
      salePrice: (map['sale_price']! as num).toDouble(),
    );
  }
}
