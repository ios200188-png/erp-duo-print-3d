import '../../filaments/domain/filament.dart';
import '../../projects/domain/project.dart';
import '../../settings/domain/business_settings.dart';
import '../domain/quote_calculation.dart';

class QuoteCalculator {
  const QuoteCalculator();

  QuoteCalculation calculate({
    required Project project,
    required Filament filament,
    required BusinessSettings settings,
    required int quantity,
    required int laborMinutes,
    required double additionalCost,
    required double marginPercent,
  }) {
    final safeQuantity = quantity < 1 ? 1 : quantity;
    final printHours = (project.printMinutes * safeQuantity) / 60;

    final materialCost =
        project.estimatedWeight * safeQuantity * filament.costPerGram;
    final energyCost =
        printHours * (settings.printerPowerW / 1000) * settings.kwhPrice;
    final machineCost = printHours * settings.machineHour;
    final laborCost = (laborMinutes / 60) * settings.laborHour;
    final packagingCost = settings.packagingCost;

    final subtotal =
        materialCost +
        energyCost +
        machineCost +
        laborCost +
        packagingCost +
        additionalCost;

    final maintenanceCost = subtotal * (settings.maintenancePercent / 100);
    final failureBase = subtotal + maintenanceCost;
    final failureCost = failureBase * (settings.failurePercent / 100);
    final totalCost = failureBase + failureCost;
    final salePrice = totalCost * (1 + (marginPercent / 100));

    return QuoteCalculation(
      materialCost: materialCost,
      energyCost: energyCost,
      machineCost: machineCost,
      laborCost: laborCost,
      packagingCost: packagingCost,
      maintenanceCost: maintenanceCost,
      failureCost: failureCost,
      additionalCost: additionalCost,
      totalCost: totalCost,
      marginPercent: marginPercent,
      salePrice: salePrice,
    );
  }
}
