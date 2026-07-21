import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/business_settings.dart';

final businessSettingsRepositoryProvider = Provider<BusinessSettingsRepository>(
  (ref) {
    return BusinessSettingsRepository(ref.watch(appDatabaseProvider));
  },
);

final businessSettingsProvider = FutureProvider<BusinessSettings>((ref) {
  return ref.watch(businessSettingsRepositoryProvider).load();
});

class BusinessSettingsRepository {
  BusinessSettingsRepository(this._database);

  final AppDatabase _database;

  Future<BusinessSettings> load() async {
    final row = await _database
        .customSelect(
          'SELECT * FROM business_settings WHERE id = 1',
          readsFrom: const {},
        )
        .getSingle();

    return BusinessSettings.fromMap(row.data);
  }

  Future<void> save(BusinessSettings settings) async {
    await _database.customStatement(
      '''
      UPDATE business_settings
      SET company_name = ?, whatsapp = ?, document = ?, email = ?,
          address = ?, city = ?, kwh_price = ?, printer_power_w = ?,
          labor_hour = ?, machine_hour = ?, packaging_cost = ?,
          maintenance_percent = ?, failure_percent = ?,
          ideal_margin_percent = ?, default_observation = ?, updated_at = ?
      WHERE id = 1
      ''',
      [
        settings.companyName,
        settings.whatsapp,
        settings.document,
        settings.email,
        settings.address,
        settings.city,
        settings.kwhPrice,
        settings.printerPowerW,
        settings.laborHour,
        settings.machineHour,
        settings.packagingCost,
        settings.maintenancePercent,
        settings.failurePercent,
        settings.idealMarginPercent,
        settings.defaultObservation,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }
}
