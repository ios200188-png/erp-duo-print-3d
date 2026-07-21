class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.description,
    required this.filamentId,
    required this.filamentName,
    required this.printerId,
    required this.printerName,
    required this.color,
    required this.estimatedWeight,
    required this.printMinutes,
    required this.laborMinutes,
    required this.layerHeight,
    required this.infillPercent,
    required this.wallCount,
    required this.supports,
    required this.nozzleSize,
    required this.packagingCost,
    required this.additionalCost,
    required this.totalCost,
    required this.suggestedPrice,
    required this.active,
    required this.notes,
  });

  final int id;
  final String code;
  final String name;
  final String category;
  final String description;
  final int? filamentId;
  final String filamentName;
  final int? printerId;
  final String printerName;
  final String color;
  final double estimatedWeight;
  final int printMinutes;
  final int laborMinutes;
  final double layerHeight;
  final double infillPercent;
  final int wallCount;
  final bool supports;
  final double nozzleSize;
  final double packagingCost;
  final double additionalCost;
  final double totalCost;
  final double suggestedPrice;
  final bool active;
  final String notes;

  double get estimatedProfit => suggestedPrice - totalCost;
  double get marginPercent =>
      suggestedPrice <= 0 ? 0 : (estimatedProfit / suggestedPrice) * 100;

  String get formattedTime {
    final hours = printMinutes ~/ 60;
    final minutes = printMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id']! as int,
      code: map['code']! as String,
      name: map['name']! as String,
      category: map['category']! as String,
      description: map['description']! as String,
      filamentId: map['filament_id'] as int?,
      filamentName: (map['filament_name'] as String?) ?? '',
      printerId: map['printer_id'] as int?,
      printerName: (map['printer_name'] as String?) ?? '',
      color: map['color']! as String,
      estimatedWeight: (map['estimated_weight']! as num).toDouble(),
      printMinutes: map['print_minutes']! as int,
      laborMinutes: map['labor_minutes']! as int,
      layerHeight: (map['layer_height']! as num).toDouble(),
      infillPercent: (map['infill_percent']! as num).toDouble(),
      wallCount: map['wall_count']! as int,
      supports: (map['supports']! as int) == 1,
      nozzleSize: (map['nozzle_size']! as num).toDouble(),
      packagingCost: (map['packaging_cost']! as num).toDouble(),
      additionalCost: (map['additional_cost']! as num).toDouble(),
      totalCost: (map['total_cost']! as num).toDouble(),
      suggestedPrice: (map['suggested_price']! as num).toDouble(),
      active: (map['active']! as int) == 1,
      notes: map['notes']! as String,
    );
  }
}
