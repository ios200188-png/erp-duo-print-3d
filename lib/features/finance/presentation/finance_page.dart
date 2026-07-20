import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/finance_repository.dart';

class FinancePage extends ConsumerWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(financialEntriesProvider);
    final summary = ref.watch(financeSummaryProvider);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final date = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financialEntriesProvider);
          ref.invalidate(financeSummaryProvider);
          await ref.read(financialEntriesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            summary.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Erro: $error'),
              data: (value) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  _SummaryCard(
                    title: 'Caixa',
                    value: money.format(value.balance),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _SummaryCard(
                    title: 'A receber',
                    value: money.format(value.receivable),
                    icon: Icons.south_west,
                  ),
                  _SummaryCard(
                    title: 'A pagar',
                    value: money.format(value.payable),
                    icon: Icons.north_east,
                  ),
                  _SummaryCard(
                    title: 'Despesas pagas',
                    value: money.format(value.expensePaid),
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => context.go('/finance/cash-flow'),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('ABRIR FLUXO DE CAIXA'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Lançamentos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            entries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Erro: $error'),
              data: (items) {
                if (items.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Nenhum lançamento financeiro.'),
                    ),
                  );
                }

                return Column(
                  children: items.map((item) {
                    final isIncome = item.type == 'Receita';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              isIncome
                                  ? Icons.south_west
                                  : Icons.north_east,
                            ),
                          ),
                          title: Text(item.description),
                          subtitle: Text(
                            '${item.category} • Venc. ${date.format(item.dueDate)}\n'
                            '${item.status}',
                          ),
                          isThreeLine: true,
                          trailing: SizedBox(
                            width: 118,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    money.format(item.amount),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'toggle') {
                                      await ref
                                          .read(financeRepositoryProvider)
                                          .togglePaid(
                                            item.id,
                                            item.status != 'Pago',
                                          );
                                    } else {
                                      await ref
                                          .read(financeRepositoryProvider)
                                          .delete(item.id);
                                    }
                                    ref.invalidate(financialEntriesProvider);
                                    ref.invalidate(financeSummaryProvider);
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(
                                        item.status == 'Pago'
                                            ? 'Marcar pendente'
                                            : 'Marcar pago',
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Excluir'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/finance/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo lançamento'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(title),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
