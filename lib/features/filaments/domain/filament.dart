class Filament {
  const Filament({
    required this.id,
    required this.name,
    required this.materialType,
    required this.brand,
    required this.color,
    required this.initialWeight,
    required this.currentWeight,
    required this.purchasePrice,
    required this.minimumStock,
    required this.supplier,
    required this.notes,
  });

  final int id;
  final String name;
  final String materialType;
  final String brand;
  final String color;
  final double initialWeight;
  final double currentWeight;
  final double purchasePrice;
  final double minimumStock;
  final String supplier;
  final String notes;

  double get costPerGram =>
      initialWeight <= 0 ? 0 : purchasePrice / initialWeight;

  bool get lowStock => currentWeight <= minimumStock;

  factory Filament.fromMap(Map<String, Object?> map) {
    return Filament(
      id: map['id']! as int,
      name: map['name']! as String,
      materialType: map['material_type']! as String,
      brand: map['brand']! as String,
      color: map['color']! as String,
      initialWeight: (map['initial_weight']! as num).toDouble(),
      currentWeight: (map['current_weight']! as num).toDouble(),
      purchasePrice: (map['purchase_price']! as num).toDouble(),
      minimumStock: (map['minimum_stock']! as num).toDouble(),
      supplier: map['supplier']! as String,
      notes: map['notes']! as String,
    );
  }
}
