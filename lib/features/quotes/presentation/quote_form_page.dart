import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../customers/data/customer_repository.dart';
import '../../filaments/data/filament_repository.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';
import '../../projects/data/project_repository.dart';
import '../../settings/data/business_settings_repository.dart';
import '../application/quote_calculator.dart';
import '../data/quote_repository.dart';
import '../domain/quote_calculation.dart';
import '../domain/quote_item.dart';

class QuoteFormPage extends ConsumerStatefulWidget {
  const QuoteFormPage({super.key});

  @override
  ConsumerState<QuoteFormPage> createState() => _QuoteFormPageState();
}

class _QuoteFormPageState extends ConsumerState<QuoteFormPage> {
  int? _customerId;
  int? _productId;
  int? _projectId;
  int? _filamentId;

  final _quantity = TextEditingController(text: '1');
  final _laborMinutes = TextEditingController(text: '0');
  final _additionalCost = TextEditingController(text: '0');
  final _margin = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _notes = TextEditingController();

  String _discountType = 'Percentual';
  bool _defaultObservationLoaded = false;
  final List<QuoteItemInput> _items = [];

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;

  int _integer(String value) => int.tryParse(value) ?? 0;

  double get _subtotal => _items.fold<double>(
    0,
    (total, item) => total + item.calculation.salePrice,
  );

  double get _totalCost => _items.fold<double>(
    0,
    (total, item) => total + item.calculation.totalCost,
  );

  double get _discountAmount {
    final value = _number(_discount.text);
    final raw = _discountType == 'Valor' ? value : _subtotal * (value / 100);
    return raw.clamp(0, _subtotal).toDouble();
  }

  double get _grandTotal => _subtotal - _discountAmount;

  @override
  void dispose() {
    _quantity.dispose();
    _laborMinutes.dispose();
    _additionalCost.dispose();
    _margin.dispose();
    _discount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final products = ref.watch(productsProvider);
    final projects = ref.watch(projectsProvider);
    final filaments = ref.watch(filamentsProvider);
    final settings = ref.watch(businessSettingsProvider);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return Scaffold(
      appBar: AppBar(title: const Text('Novo orçamento')),
      body: customers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (customerItems) => projects.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro: $error')),
          data: (projectItems) => filaments.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erro: $error')),
            data: (filamentItems) => settings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erro: $error')),
              data: (business) {
                final productItems = products.asData?.value ?? <Product>[];
                if (_margin.text.isEmpty) {
                  _margin.text = business.idealMarginPercent
                      .toStringAsFixed(1)
                      .replaceAll('.', ',');
                }
                if (!_defaultObservationLoaded) {
                  _defaultObservationLoaded = true;
                  _notes.text = business.defaultObservation;
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _customerId,
                      decoration: const InputDecoration(labelText: 'Cliente *'),
                      items: customerItems
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _customerId = value),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Adicionar produto',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: _productId,
                      decoration: const InputDecoration(
                        labelText: 'Produto inteligente',
                        helperText:
                            'Opcional. Preenche material e preço automaticamente.',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Item personalizado'),
                        ),
                        ...productItems
                            .where((item) => item.active)
                            .map(
                              (item) => DropdownMenuItem<int?>(
                                value: item.id,
                                child: Text('${item.code} • ${item.name}'),
                              ),
                            ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _productId = value;
                          final matches = productItems.where(
                            (item) => item.id == value,
                          );
                          if (matches.isNotEmpty) {
                            final item = matches.first;
                            _filamentId = item.filamentId;
                            _laborMinutes.text = item.laborMinutes.toString();
                            _additionalCost.text = item.additionalCost
                                .toStringAsFixed(2)
                                .replaceAll('.', ',');
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _projectId,
                      decoration: const InputDecoration(labelText: 'Projeto *'),
                      items: projectItems
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                item.version.isEmpty
                                    ? item.name
                                    : '${item.name} — ${item.version}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _projectId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _filamentId,
                      decoration: const InputDecoration(
                        labelText: 'Filamento *',
                      ),
                      items: filamentItems
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _filamentId = value),
                    ),
                    const SizedBox(height: 12),
                    _field(_quantity, 'Quantidade *', number: true),
                    _field(
                      _laborMinutes,
                      'Mão de obra total (minutos)',
                      number: true,
                    ),
                    _field(
                      _additionalCost,
                      'Custos adicionais (R\$)',
                      number: true,
                    ),
                    _field(_margin, 'Margem de lucro (%) *', number: true),
                    FilledButton.icon(
                      onPressed: () {
                        if (_projectId == null || _filamentId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selecione projeto e filamento para adicionar o item.',
                              ),
                            ),
                          );
                          return;
                        }

                        final project = projectItems.firstWhere(
                          (item) => item.id == _projectId,
                        );
                        final filament = filamentItems.firstWhere(
                          (item) => item.id == _filamentId,
                        );
                        final quantity = _integer(
                          _quantity.text,
                        ).clamp(1, 999999).toInt();
                        final selectedProducts = productItems.where(
                          (item) => item.id == _productId,
                        );

                        late final QuoteCalculation calculation;
                        late final String description;

                        if (selectedProducts.isNotEmpty) {
                          final product = selectedProducts.first;
                          final totalCost = product.totalCost * quantity;
                          final salePrice = product.suggestedPrice * quantity;
                          calculation = QuoteCalculation(
                            materialCost: totalCost,
                            energyCost: 0,
                            machineCost: 0,
                            laborCost: 0,
                            packagingCost: product.packagingCost * quantity,
                            maintenanceCost: 0,
                            failureCost: 0,
                            additionalCost: product.additionalCost * quantity,
                            totalCost: totalCost,
                            marginPercent: salePrice <= 0
                                ? 0
                                : ((salePrice - totalCost) / salePrice) * 100,
                            salePrice: salePrice,
                          );
                          description = product.name;
                        } else {
                          calculation = const QuoteCalculator().calculate(
                            project: project,
                            filament: filament,
                            settings: business,
                            quantity: quantity,
                            laborMinutes: _integer(_laborMinutes.text),
                            additionalCost: _number(_additionalCost.text),
                            marginPercent: _number(_margin.text),
                          );
                          description = project.version.isEmpty
                              ? project.name
                              : '${project.name} — ${project.version}';
                        }

                        setState(() {
                          _items.add(
                            QuoteItemInput(
                              productId: _productId,
                              projectId: _projectId!,
                              filamentId: _filamentId!,
                              description: description,
                              quantity: quantity,
                              laborMinutes: _integer(_laborMinutes.text),
                              additionalCost: _number(_additionalCost.text),
                              calculation: calculation,
                            ),
                          );
                          _productId = null;
                          _projectId = null;
                          _filamentId = null;
                          _quantity.text = '1';
                          _laborMinutes.text = '0';
                          _additionalCost.text = '0';
                        });
                      },
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('ADICIONAR AO ORÇAMENTO'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Itens do orçamento (${_items.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_items.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Nenhum produto adicionado.'),
                        ),
                      )
                    else
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Card(
                          child: ListTile(
                            title: Text(item.description),
                            subtitle: Text(
                              '${item.quantity} un. • '
                              '${money.format(item.calculation.unitPrice(item.quantity))} por un.',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  money.format(item.calculation.salePrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remover item',
                                  onPressed: () =>
                                      setState(() => _items.removeAt(index)),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 430;
                        final typeField = DropdownButtonFormField<String>(
                          initialValue: _discountType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de desconto',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Percentual',
                              child: Text('Percentual'),
                            ),
                            DropdownMenuItem(
                              value: 'Valor',
                              child: Text('Valor'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _discountType = value);
                          },
                        );
                        final discountField = TextField(
                          controller: _discount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: _discountType == 'Valor'
                                ? 'Desconto (R\$)'
                                : 'Desconto (%)',
                          ),
                          onChanged: (_) => setState(() {}),
                        );

                        if (compact) {
                          return Column(
                            children: [
                              typeField,
                              const SizedBox(height: 12),
                              discountField,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: typeField),
                            const SizedBox(width: 12),
                            Expanded(child: discountField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _field(_notes, 'Observações', lines: 3),
                    _TotalsCard(
                      subtotal: _subtotal,
                      discount: _discountAmount,
                      total: _grandTotal,
                      totalCost: _totalCost,
                      money: money,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _items.isEmpty || _customerId == null
                          ? null
                          : () async {
                              await ref
                                  .read(quoteRepositoryProvider)
                                  .save(
                                    customerId: _customerId!,
                                    items: List.unmodifiable(_items),
                                    discountType: _discountType,
                                    discountValue: _number(_discount.text),
                                    notes: _notes.text.trim(),
                                  );

                              ref.invalidate(quotesProvider);
                              ref.invalidate(quoteCountProvider);

                              if (!context.mounted) return;
                              context.go('/quotes');
                            },
                      icon: const Icon(Icons.save_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('SALVAR ORÇAMENTO'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: lines,
        maxLines: lines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.totalCost,
    required this.money,
  });

  final double subtotal;
  final double discount;
  final double total;
  final double totalCost;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final profit = total - totalCost;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _row('Subtotal', subtotal),
            _row('Desconto', -discount),
            const Divider(height: 24),
            _row('Total do orçamento', total, strong: true),
            _row('Custo estimado', totalCost),
            _row('Lucro estimado', profit),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? const TextStyle(fontWeight: FontWeight.w800)
                  : null,
            ),
          ),
          Text(
            money.format(value),
            style: strong ? const TextStyle(fontWeight: FontWeight.w800) : null,
          ),
        ],
      ),
    );
  }
}
