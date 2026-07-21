import 'quote_calculation.dart';

class QuoteItemInput {
  const QuoteItemInput({
    required this.productId,
    required this.projectId,
    required this.filamentId,
    required this.description,
    required this.quantity,
    required this.laborMinutes,
    required this.additionalCost,
    required this.calculation,
  });

  final int? productId;
  final int projectId;
  final int filamentId;
  final String description;
  final int quantity;
  final int laborMinutes;
  final double additionalCost;
  final QuoteCalculation calculation;
}

class QuoteItemDetail {
  const QuoteItemDetail({
    required this.id,
    required this.productId,
    required this.projectId,
    required this.filamentId,
    required this.description,
    required this.projectName,
    required this.projectVersion,
    required this.materialName,
    required this.materialType,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.totalCost,
  });

  final int id;
  final int? productId;
  final int projectId;
  final int filamentId;
  final String description;
  final String projectName;
  final String projectVersion;
  final String materialName;
  final String materialType;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double totalCost;

  factory QuoteItemDetail.fromMap(Map<String, Object?> map) {
    return QuoteItemDetail(
      id: map['id']! as int,
      productId: map['product_id'] as int?,
      projectId: map['project_id']! as int,
      filamentId: map['filament_id']! as int,
      description: map['description']! as String,
      projectName: map['project_name']! as String,
      projectVersion: map['project_version']! as String,
      materialName: map['material_name']! as String,
      materialType: map['material_type']! as String,
      quantity: map['quantity']! as int,
      unitPrice: (map['unit_price']! as num).toDouble(),
      totalPrice: (map['total_price']! as num).toDouble(),
      totalCost: (map['total_cost']! as num).toDouble(),
    );
  }
}
