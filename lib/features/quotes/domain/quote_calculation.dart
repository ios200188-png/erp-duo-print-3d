class QuoteCalculation {
  const QuoteCalculation({
    required this.materialCost,
    required this.energyCost,
    required this.machineCost,
    required this.laborCost,
    required this.packagingCost,
    required this.maintenanceCost,
    required this.failureCost,
    required this.additionalCost,
    required this.totalCost,
    required this.marginPercent,
    required this.salePrice,
  });

  final double materialCost;
  final double energyCost;
  final double machineCost;
  final double laborCost;
  final double packagingCost;
  final double maintenanceCost;
  final double failureCost;
  final double additionalCost;
  final double totalCost;
  final double marginPercent;
  final double salePrice;

  double get profit => salePrice - totalCost;

  double get profitPercent => salePrice <= 0 ? 0 : (profit / salePrice) * 100;

  double unitCost(int quantity) {
    final safeQuantity = quantity < 1 ? 1 : quantity;
    return totalCost / safeQuantity;
  }

  double unitPrice(int quantity) {
    final safeQuantity = quantity < 1 ? 1 : quantity;
    return salePrice / safeQuantity;
  }
}
