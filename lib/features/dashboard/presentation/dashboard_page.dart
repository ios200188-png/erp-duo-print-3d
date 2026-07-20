import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../agenda/data/agenda_repository.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

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
              sliver: SliverToBoxAdapter(child: _Header(value: value)),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: _HeroCard(value: value, money: money),
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
            const _SectionTitle(
              title: 'Inteligência financeira',
              subtitle: 'Últimos 12 meses',
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _MonthlyFinanceChart(
                  points: value.monthlyHistory,
                  money: money,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _CashEvolutionChart(
                  points: value.cashEvolution,
                  money: money,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _ExpenseCategoryChart(
                  points: value.expenseCategories,
                  total: value.monthExpenses,
                  money: money,
                ),
              ),
            ),
            const _SectionTitle(title: 'Alertas e agenda'),
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

class _Header extends StatelessWidget {
  const _Header({required this.value});

  final DashboardSummary value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ERP DUO PRINT 3D',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Visão executiva',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value.overdueFinancial > 0
                    ? '${value.overdueFinancial} conta(s) vencida(s) precisam de atenção.'
                    : 'Produção, financeiro e operação em um só lugar.',
              ),
            ],
          ),
        ),
        const CircleAvatar(radius: 24, child: Icon(Icons.auto_graph_outlined)),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.value, required this.money});

  final DashboardSummary value;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final variation = value.profitVariationPercent;
    final positive = variation >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _HeroValue(
                    label: 'Faturamento do mês',
                    value: money.format(value.monthRevenue),
                  ),
                ),
                Container(
                  width: 1,
                  height: 54,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _HeroValue(
                    label: 'Lucro do mês',
                    value: money.format(value.monthProfit),
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  positive ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: positive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  '${positive ? '+' : ''}${variation.toStringAsFixed(1)}% em relação ao mês anterior',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroValue extends StatelessWidget {
  const _HeroValue({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: highlight ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _MonthlyFinanceChart extends StatelessWidget {
  const _MonthlyFinanceChart({required this.points, required this.money});

  final List<MonthlyFinancePoint> points;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(0, (maxValue, point) {
      return math.max(maxValue, math.max(point.revenue, point.expenses));
    });

    return _ChartCard(
      title: 'Receita × despesa',
      subtitle: 'Comparativo mensal',
      footer: const _Legend(),
      child: SizedBox(
        height: 230,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((point) {
                final revenueHeight = maxValue == 0
                    ? 0.0
                    : (point.revenue / maxValue) * 145;
                final expenseHeight = maxValue == 0
                    ? 0.0
                    : (point.expenses / maxValue) * 145;
                return Expanded(
                  child: Tooltip(
                    message:
                        '${DateFormat.MMM('pt_BR').format(point.month)}\n'
                        'Receita: ${money.format(point.revenue)}\n'
                        'Despesa: ${money.format(point.expenses)}',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _Bar(height: revenueHeight, emphasized: true),
                              const SizedBox(width: 2),
                              _Bar(height: expenseHeight, emphasized: false),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat.MMM(
                            'pt_BR',
                          ).format(point.month).replaceAll('.', ''),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.emphasized});

  final double height;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      width: 7,
      height: math.max(height, 3),
      decoration: BoxDecoration(
        color: emphasized
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          label: 'Receita',
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 18),
        _LegendItem(
          label: 'Despesa',
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CashEvolutionChart extends StatelessWidget {
  const _CashEvolutionChart({required this.points, required this.money});

  final List<CashPoint> points;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final current = points.isEmpty ? 0.0 : points.last.balance;
    return _ChartCard(
      title: 'Evolução do caixa',
      subtitle: 'Últimos 30 dias',
      trailing: Text(
        money.format(current),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: SizedBox(
        height: 180,
        child: points.isEmpty
            ? const _EmptyChart(message: 'Sem movimentações no período')
            : CustomPaint(
                painter: _LineChartPainter(
                  values: points
                      .map((point) => point.balance)
                      .toList(growable: false),
                  lineColor: Theme.of(context).colorScheme.primary,
                  gridColor: Theme.of(context).dividerColor,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: const SizedBox.expand(),
              ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.length < 2) return;
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if (minValue == maxValue) {
      minValue -= 1;
      maxValue += 1;
    }

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalized = (values[i] - minValue) / (maxValue - minValue);
      final y = size.height - (normalized * (size.height - 16)) - 8;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}

class _ExpenseCategoryChart extends StatelessWidget {
  const _ExpenseCategoryChart({
    required this.points,
    required this.total,
    required this.money,
  });

  final List<ExpenseCategoryPoint> points;
  final double total;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Despesas por categoria',
      subtitle: 'Mês atual',
      trailing: Text(
        money.format(total),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      child: points.isEmpty
          ? const SizedBox(
              height: 120,
              child: _EmptyChart(message: 'Nenhuma despesa paga neste mês'),
            )
          : Column(
              children: points.map((point) {
                final fraction = total <= 0 ? 0.0 : point.amount / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              point.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(fraction * 100).toStringAsFixed(0)}%  •  ${money.format(point.amount)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: fraction.clamp(0, 1),
                        minHeight: 8,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // ignore: use_null_aware_elements
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 18),
            child,
            if (footer != null) ...[const SizedBox(height: 14), footer!],
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
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
