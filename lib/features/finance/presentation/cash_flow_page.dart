import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/cash_service.dart';
import '../domain/cash_transaction.dart';

enum _CashPeriod { today, sevenDays, thirtyDays, month, custom }

enum _CashTypeFilter { all, income, expense }

class CashFlowPage extends ConsumerStatefulWidget {
  const CashFlowPage({super.key});

  @override
  ConsumerState<CashFlowPage> createState() => _CashFlowPageState();
}

class _CashFlowPageState extends ConsumerState<CashFlowPage> {
  final _searchController = TextEditingController();
  _CashPeriod _period = _CashPeriod.month;
  _CashTypeFilter _typeFilter = _CashTypeFilter.all;
  DateTimeRange? _customRange;
  late Future<CashFlowData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  DateTimeRange get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (_period) {
      _CashPeriod.today => DateTimeRange(start: today, end: today),
      _CashPeriod.sevenDays => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      _CashPeriod.thirtyDays => DateTimeRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
      _CashPeriod.month => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      _CashPeriod.custom =>
        _customRange ?? DateTimeRange(start: today, end: today),
    };
  }

  Future<CashFlowData> _load() {
    final range = _range;
    return ref
        .read(cashServiceProvider)
        .load(start: range.start, end: range.end);
  }

  // Remover este bloco inteiro
  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _selectCustomRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange:
          _customRange ??
          DateTimeRange(start: DateTime(now.year, now.month), end: now),
      helpText: 'Selecione o período',
      saveText: 'APLICAR',
      cancelText: 'CANCELAR',
    );

    if (selected == null || !mounted) return;
    setState(() {
      _customRange = selected;
      _period = _CashPeriod.custom;
      _future = _load();
    });
  }

  List<CashTransaction> _filteredTransactions(List<CashTransaction> source) {
    final query = _searchController.text.trim().toLowerCase();
    return source
        .where((transaction) {
          final matchesType = switch (_typeFilter) {
            _CashTypeFilter.all => true,
            _CashTypeFilter.income => transaction.isIncome,
            _CashTypeFilter.expense => !transaction.isIncome,
          };
          final matchesSearch =
              query.isEmpty ||
              transaction.description.toLowerCase().contains(query) ||
              transaction.category.toLowerCase().contains(query);
          return matchesType && matchesSearch;
        })
        .toList(growable: false);
  }

  Map<DateTime, List<CashTransaction>> _groupByDay(
    List<CashTransaction> transactions,
  ) {
    final grouped = <DateTime, List<CashTransaction>>{};
    for (final transaction in transactions) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      grouped.putIfAbsent(day, () => <CashTransaction>[]).add(transaction);
    }
    return grouped;
  }

  String _periodLabel(DateFormat formatter) {
    final range = _range;
    if (range.start == range.end) return formatter.format(range.start);
    return '${formatter.format(range.start)} a ${formatter.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final date = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fluxo de caixa'),
        actions: [
          IconButton(
            onPressed: _selectCustomRange,
            tooltip: 'Período personalizado',
            icon: const Icon(Icons.date_range_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final future = _load();
          setState(() => _future = future);
          await future;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_CashPeriod>(
                segments: const [
                  ButtonSegment(value: _CashPeriod.today, label: Text('Hoje')),
                  ButtonSegment(
                    value: _CashPeriod.sevenDays,
                    label: Text('7 dias'),
                  ),
                  ButtonSegment(
                    value: _CashPeriod.thirtyDays,
                    label: Text('30 dias'),
                  ),
                  ButtonSegment(value: _CashPeriod.month, label: Text('Mês')),
                  ButtonSegment(
                    value: _CashPeriod.custom,
                    label: Text('Personalizado'),
                  ),
                ],
                selected: {_period},
                showSelectedIcon: false,
                onSelectionChanged: (selection) async {
                  final selected = selection.first;
                  if (selected == _CashPeriod.custom) {
                    await _selectCustomRange();
                    return;
                  }
                  setState(() {
                    _period = selected;
                    _future = _load();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _periodLabel(date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FutureBuilder<CashFlowData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Erro: ${snapshot.error}'),
                    ),
                  );
                }

                final data = snapshot.requireData;
                final transactions = _filteredTransactions(data.transactions);
                final grouped = _groupByDay(transactions);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.42,
                      children: [
                        _CashSummaryCard(
                          title: 'Saldo inicial',
                          value: money.format(data.summary.openingBalance),
                          icon: Icons.history,
                        ),
                        _CashSummaryCard(
                          title: 'Entradas',
                          value: money.format(data.summary.income),
                          icon: Icons.south_west,
                        ),
                        _CashSummaryCard(
                          title: 'Saídas',
                          value: money.format(data.summary.expense),
                          icon: Icons.north_east,
                        ),
                        _CashSummaryCard(
                          title: 'Saldo final',
                          value: money.format(data.summary.closingBalance),
                          icon: Icons.account_balance_wallet_outlined,
                          emphasized: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ResultCard(
                      result: data.summary.periodResult,
                      money: money,
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Pesquisar movimentação',
                        hintText: 'Descrição ou categoria',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: _searchController.clear,
                                tooltip: 'Limpar pesquisa',
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<_CashTypeFilter>(
                      segments: const [
                        ButtonSegment(
                          value: _CashTypeFilter.all,
                          label: Text('Tudo'),
                        ),
                        ButtonSegment(
                          value: _CashTypeFilter.income,
                          label: Text('Entradas'),
                        ),
                        ButtonSegment(
                          value: _CashTypeFilter.expense,
                          label: Text('Saídas'),
                        ),
                      ],
                      selected: {_typeFilter},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        setState(() => _typeFilter = selection.first);
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Movimentações',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${transactions.length} item(ns)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (transactions.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Nenhuma movimentação encontrada.'),
                        ),
                      )
                    else
                      ...grouped.entries.expand((entry) {
                        return <Widget>[
                          _DayHeader(date: entry.key),
                          ...entry.value.map(
                            (transaction) => _TransactionCard(
                              transaction: transaction,
                              accumulatedBalance:
                                  data.balanceByTransactionId[transaction.id] ??
                                  0,
                              money: money,
                              date: date,
                            ),
                          ),
                        ];
                      }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CashSummaryCard extends StatelessWidget {
  const _CashSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool emphasized;

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
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: emphasized
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.money});

  final double result;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final positive = result >= 0;
    final color = positive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(positive ? Icons.trending_up : Icons.trending_down),
        ),
        title: const Text('Resultado do período'),
        subtitle: Text(
          positive ? 'Caixa positivo' : 'Saídas acima das entradas',
        ),
        trailing: Text(
          money.format(result),
          style: TextStyle(fontWeight: FontWeight.w900, color: color),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final normalized = DateTime(date.year, date.month, date.day);
    final label = normalized == today
        ? 'Hoje'
        : normalized == yesterday
        ? 'Ontem'
        : DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.accumulatedBalance,
    required this.money,
    required this.date,
  });

  final CashTransaction transaction;
  final double accumulatedBalance;
  final NumberFormat money;
  final DateFormat date;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: CircleAvatar(
            child: Icon(
              transaction.isIncome ? Icons.south_west : Icons.north_east,
            ),
          ),
          title: Text(
            transaction.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${transaction.category} • ${date.format(transaction.date)}\n'
            'Saldo após lançamento: ${money.format(accumulatedBalance)}',
          ),
          isThreeLine: true,
          trailing: Text(
            '${transaction.isIncome ? '+' : '-'} ${money.format(transaction.amount)}',
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ),
      ),
    );
  }
}
