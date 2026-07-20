import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../agenda/data/agenda_repository.dart';
import '../data/dashboard_repository.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final agendaCount = ref.watch(agendaTodayCountProvider);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(agendaTodayCountProvider);
        await ref.read(dashboardSummaryProvider.future);
      },
      child: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          children: [
            const SizedBox(height: 100),
            Center(child: Text('Erro: $error')),
          ],
        ),
        data: (value) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ERP DUO PRINT 3D',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Visão executiva',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Text(
                            'Produção, financeiro e operação em um só lugar.',
                          ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      radius: 24,
                      child: Icon(Icons.auto_graph_outlined),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: _HeroCard(
                  revenue: value.monthRevenue,
                  profit: value.monthProfit,
                  money: money,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.28,
                children: [
                  _MetricCard(
                    title: 'Caixa atual',
                    value: money.format(value.cashBalance),
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => context.go('/finance'),
                  ),
                  _MetricCard(
                    title: 'A receber',
                    value: money.format(value.receivable),
                    icon: Icons.south_west,
                    onTap: () => context.go('/finance'),
                  ),
                  _MetricCard(
                    title: 'A pagar',
                    value: money.format(value.payable),
                    icon: Icons.north_east,
                    onTap: () => context.go('/finance'),
                  ),
                  _MetricCard(
                    title: 'Produção',
                    value: '${value.openProduction} ordens',
                    icon: Icons.precision_manufacturing_outlined,
                    onTap: () => context.go('/production'),
                  ),
                  _MetricCard(
                    title: 'Imprimindo',
                    value: '${value.printersWorking} ordens',
                    icon: Icons.print_outlined,
                    onTap: () => context.go('/production'),
                  ),
                  _MetricCard(
                    title: 'A faturar',
                    value: '${value.awaitingBilling} pedidos',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => context.go('/billing'),
                  ),
                  _MetricCard(
                    title: 'Pedidos no mês',
                    value: '${value.monthOrders}',
                    icon: Icons.shopping_bag_outlined,
                    onTap: () => context.go('/quotes'),
                  ),
                  _MetricCard(
                    title: 'Ticket médio',
                    value: money.format(value.averageTicket),
                    icon: Icons.analytics_outlined,
                    onTap: () => context.go('/quotes'),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Alertas e agenda',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _AlertCard(
                    title: 'Agenda de hoje',
                    value: agendaCount.when(
                      data: (count) => '$count itens',
                      loading: () => '...',
                      error: (_, _) => '-',
                    ),
                    icon: Icons.event_note_outlined,
                    onTap: () => context.go('/agenda'),
                  ),
                  _AlertCard(
                    title: 'Estoque baixo',
                    value: '${value.lowStock} alertas',
                    icon: Icons.inventory_2_outlined,
                    onTap: () => context.go('/filaments'),
                  ),
                  _AlertCard(
                    title: 'Financeiro vencido',
                    value: '${value.overdueFinancial} itens',
                    icon: Icons.warning_amber_rounded,
                    onTap: () => context.go('/finance'),
                  ),
                  _AlertCard(
                    title: 'Despesas do mês',
                    value: money.format(value.monthExpenses),
                    icon: Icons.receipt_long_outlined,
                    onTap: () => context.go('/finance'),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverToBoxAdapter(
                child: FilledButton.icon(
                  onPressed: () => context.go('/quotes/new'),
                  icon: const Icon(Icons.add),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('NOVO ORÇAMENTO'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.revenue,
    required this.profit,
    required this.money,
  });

  final double revenue;
  final double profit;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Faturamento do mês'),
                  const SizedBox(height: 4),
                  Text(
                    money.format(revenue),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 54,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lucro do mês'),
                  const SizedBox(height: 4),
                  Text(
                    money.format(profit),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const Spacer(),
              Text(title),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
