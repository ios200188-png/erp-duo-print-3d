import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/agenda/presentation/agenda_page.dart';
import '../../features/billing/presentation/billing_form_page.dart';
import '../../features/billing/presentation/billing_page.dart';
import '../../features/customers/presentation/customer_form_page.dart';
import '../../features/customers/presentation/customers_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/filaments/presentation/filament_form_page.dart';
import '../../features/filaments/presentation/filaments_page.dart';
import '../../features/finance/presentation/cash_flow_page.dart';
import '../../features/finance/presentation/finance_form_page.dart';
import '../../features/finance/presentation/finance_page.dart';
import '../../features/printers/presentation/printer_form_page.dart';
import '../../features/printers/presentation/printers_page.dart';
import '../../features/production/presentation/production_form_page.dart';
import '../../features/production/presentation/production_page.dart';
import '../../features/projects/presentation/project_form_page.dart';
import '../../features/projects/presentation/projects_page.dart';
import '../../features/quotes/presentation/quote_form_page.dart';
import '../../features/quotes/presentation/quotes_page.dart';
import '../../features/settings/presentation/business_settings_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/presentation/app_shell.dart';
import '../../shared/presentation/modules_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CustomerFormPage(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => CustomerFormPage(
                  customerId: int.tryParse(state.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/modules',
            builder: (context, state) => const ModulesPage(),
          ),
          GoRoute(
            path: '/filaments',
            builder: (context, state) => const FilamentsPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const FilamentFormPage(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => FilamentFormPage(
                  filamentId: int.tryParse(state.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/printers',
            builder: (context, state) => const PrintersPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const PrinterFormPage(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => PrinterFormPage(
                  printerId: int.tryParse(state.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ProjectFormPage(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => ProjectFormPage(
                  projectId: int.tryParse(state.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/quotes',
            builder: (context, state) => const QuotesPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const QuoteFormPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/production',
            builder: (context, state) => const ProductionPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ProductionFormPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) => const FinancePage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const FinanceFormPage(),
              ),
              GoRoute(
                path: 'cash-flow',
                builder: (context, state) => const CashFlowPage(),
              ),
            ],
          ),

          GoRoute(
            path: '/agenda',
            builder: (context, state) => const AgendaPage(),
          ),
          GoRoute(
            path: '/billing',
            builder: (context, state) => const BillingPage(),
            routes: [
              GoRoute(
                path: ':quoteId/new',
                builder: (context, state) => BillingFormPage(
                  quoteId: int.parse(state.pathParameters['quoteId']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: 'business',
                builder: (context, state) => const BusinessSettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
