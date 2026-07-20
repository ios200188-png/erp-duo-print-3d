import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../finance/data/finance_repository.dart';
import '../../settings/data/business_settings_repository.dart';
import '../application/invoice_pdf_service.dart';
import '../data/billing_repository.dart';

class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoicesProvider);
    final billable = ref.watch(billableQuotesProvider);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final date = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Faturamento')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Text(
            'Prontos para faturar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          billable.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Erro: $error'),
            data: (items) {
              if (items.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nenhuma produção finalizada aguardando faturamento.',
                    ),
                  ),
                );
              }

              return Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.inventory_2_outlined),
                        ),
                        title: Text(item.customerName),
                        subtitle: Text(
                          '${item.projectName} • ${item.quantity} un.',
                        ),
                        trailing: FilledButton(
                          onPressed: () =>
                              context.go('/billing/${item.id}/new'),
                          child: Text(money.format(item.salePrice)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 22),
          Text(
            'Faturas emitidas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          invoices.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Erro: $error'),
            data: (items) {
              if (items.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhuma fatura emitida.'),
                  ),
                );
              }

              return Column(
                children: items.map((invoice) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.picture_as_pdf_outlined),
                        ),
                        title: Text(invoice.customerName),
                        subtitle: Text(
                          '${invoice.projectName} • ${invoice.paymentMethod}\n'
                          'Venc. ${date.format(invoice.dueDate)} • ${invoice.status}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'pdf') {
                              final company = await ref.read(
                                businessSettingsProvider.future,
                              );
                              await const InvoicePdfService().share(
                                invoice: invoice,
                                company: company,
                              );
                              return;
                            }

                            if (action == 'paid') {
                              await ref
                                  .read(billingRepositoryProvider)
                                  .markPaid(invoice);
                              ref.invalidate(invoicesProvider);
                              ref.invalidate(financeSummaryProvider);
                              ref.invalidate(financialEntriesProvider);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'pdf',
                              child: ListTile(
                                leading: Icon(Icons.share_outlined),
                                title: Text('Enviar PDF'),
                              ),
                            ),
                            if (invoice.status != 'Pago')
                              const PopupMenuItem(
                                value: 'paid',
                                child: ListTile(
                                  leading: Icon(Icons.check_circle_outline),
                                  title: Text('Marcar como pago'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
