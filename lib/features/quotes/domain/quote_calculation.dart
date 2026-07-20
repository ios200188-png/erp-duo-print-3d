class QuoteCalculation {
  const QuoteCalculation({
    required this.materialCost,
    required this.energyCost,
    required this.machineCost,
    required this.laborCost,
    required this.packagingCost,
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
  final double failureCost;
  final double additionalCost;
  final double totalCost;
  final double marginPercent;
  final double salePrice;

  double get profit => salePrice - totalCost;
}
