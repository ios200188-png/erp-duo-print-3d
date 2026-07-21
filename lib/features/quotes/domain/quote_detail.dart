import 'quote_item.dart';

class QuoteDetail {
  const QuoteDetail({
    required this.id,
    required this.customerName,
    required this.customerDocument,
    required this.customerPhone,
    required this.customerEmail,
    required this.items,
    required this.subtotal,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
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
  final List<QuoteItemDetail> items;
  final double subtotal;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final double salePrice;
  final double totalCost;
  final double marginPercent;
  final String status;
  final String notes;
  final DateTime createdAt;
}
