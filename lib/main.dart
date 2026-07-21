import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/cloud/cloud_config.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  if (!CloudConfig.isConfigured) {
    throw StateError('Supabase não configurado.');
  }

  await Supabase.initialize(
    url: CloudConfig.supabaseUrl,
    publishableKey: CloudConfig.supabasePublishableKey,
  );

  final database = AppDatabase();
  await database.initialize();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const AuthGate(),
    ),
  );
}
