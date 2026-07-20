import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../production/data/production_repository.dart';
import '../../settings/data/business_settings_repository.dart';
import '../application/quote_pdf_service.dart';
import '../data/quote_repository.dart';

class QuotesPage extends ConsumerWidget {
  const QuotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(quotesProvider);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final date = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos')),
      body: quotes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Nenhum orçamento cadastrado.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.request_quote_outlined),
                        ),
                        title: Text(item.customerName),
                        subtitle: Text(
                          '${item.projectName} • ${item.quantity} un.\n'
                          '${date.format(item.createdAt)} • '
                          'Custo ${money.format(item.totalCost)}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          money.format(item.salePrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Chip(label: Text(item.status)),
                          const Spacer(),
                          PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'print' || action == 'share') {
                                final quote = await ref.read(
                                  quoteDetailProvider(item.id).future,
                                );
                                final company = await ref.read(
                                  businessSettingsProvider.future,
                                );

                                if (quote == null) return;

                                if (action == 'print') {
                                  await const QuotePdfService().printQuote(
                                    quote: quote,
                                    company: company,
                                  );
                                } else {
                                  await const QuotePdfService().shareQuote(
                                    quote: quote,
                                    company: company,
                                  );
                                }
                                return;
                              }

                              if (action == 'approve') {
                                await ref
                                    .read(quoteRepositoryProvider)
                                    .approve(item.id);
                                ref.invalidate(quotesProvider);
                                ref.invalidate(productionOrdersProvider);
                                ref.invalidate(productionOpenCountProvider);

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Orçamento aprovado e enviado para produção.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (action == 'billing') {
                                context.go('/billing');
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'print',
                                child: ListTile(
                                  leading: Icon(Icons.print_outlined),
                                  title: Text('Imprimir orçamento'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'share',
                                child: ListTile(
                                  leading: Icon(Icons.share_outlined),
                                  title: Text('Enviar PDF'),
                                ),
                              ),
                              if (item.status == 'Rascunho')
                                const PopupMenuItem(
                                  value: 'approve',
                                  child: ListTile(
                                    leading: Icon(Icons.check_circle_outline),
                                    title: Text('Aprovar'),
                                  ),
                                ),
                              if (item.status == 'Produzido')
                                const PopupMenuItem(
                                  value: 'billing',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.receipt_long_outlined,
                                    ),
                                    title: Text('Faturar'),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/quotes/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo orçamento'),
      ),
    );
  }
}
