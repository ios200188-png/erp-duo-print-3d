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
  final _notes = TextEditingController();

  QuoteCalculation? _calculation;

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;

  int _integer(String value) => int.tryParse(value) ?? 0;

  @override
  void dispose() {
    _quantity.dispose();
    _laborMinutes.dispose();
    _additionalCost.dispose();
    _margin.dispose();
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

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (customerItems.isEmpty ||
                        projectItems.isEmpty ||
                        filamentItems.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Cadastre pelo menos um cliente, um projeto e um filamento antes de criar o orçamento.',
                          ),
                        ),
                      ),
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: _productId,
                      decoration: const InputDecoration(
                        labelText: 'Produto inteligente',
                        helperText:
                            'Preenche material, custos e preço automaticamente.',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Orçamento sem produto cadastrado'),
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
                            _calculation = null;
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
                    _field(_notes, 'Observações', lines: 3),
                    FilledButton.icon(
                      onPressed: () {
                        if (_customerId == null ||
                            _projectId == null ||
                            _filamentId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selecione cliente, projeto e filamento.',
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

                        setState(() {
                          final quantity = _integer(
                            _quantity.text,
                          ).clamp(1, 999999);
                          final selectedProducts = productItems.where(
                            (item) => item.id == _productId,
                          );
                          if (selectedProducts.isNotEmpty) {
                            final item = selectedProducts.first;
                            final total = item.totalCost * quantity;
                            final sale = item.suggestedPrice * quantity;
                            _calculation = QuoteCalculation(
                              materialCost: total,
                              energyCost: 0,
                              machineCost: 0,
                              laborCost: 0,
                              packagingCost: item.packagingCost * quantity,
                              maintenanceCost: 0,
                              failureCost: 0,
                              additionalCost: item.additionalCost * quantity,
                              totalCost: total,
                              marginPercent: sale <= 0
                                  ? 0
                                  : ((sale - total) / sale) * 100,
                              salePrice: sale,
                            );
                          } else {
                            _calculation = const QuoteCalculator().calculate(
                              project: project,
                              filament: filament,
                              settings: business,
                              quantity: quantity,
                              laborMinutes: _integer(_laborMinutes.text),
                              additionalCost: _number(_additionalCost.text),
                              marginPercent: _number(_margin.text),
                            );
                          }
                        });
                      },
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('CALCULAR ORÇAMENTO'),
                      ),
                    ),
                    if (_calculation != null) ...[
                      const SizedBox(height: 18),
                      _ResultCard(
                        calculation: _calculation!,
                        money: money,
                        quantity: _integer(_quantity.text),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(quoteRepositoryProvider)
                              .save(
                                customerId: _customerId!,
                                productId: _productId,
                                projectId: _projectId!,
                                filamentId: _filamentId!,
                                quantity: _integer(_quantity.text),
                                laborMinutes: _integer(_laborMinutes.text),
                                additionalCost: _number(_additionalCost.text),
                                calculation: _calculation!,
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.calculation,
    required this.money,
    required this.quantity,
  });

  final QuoteCalculation calculation;
  final NumberFormat money;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _row('Material', calculation.materialCost),
            _row('Energia', calculation.energyCost),
            _row('Máquina', calculation.machineCost),
            _row('Mão de obra', calculation.laborCost),
            _row('Embalagem', calculation.packagingCost),
            _row('Reserva de manutenção', calculation.maintenanceCost),
            _row('Perdas e falhas', calculation.failureCost),
            _row('Adicionais', calculation.additionalCost),
            const Divider(height: 28),
            _row('Custo total', calculation.totalCost, strong: true),
            _row('Lucro estimado', calculation.profit, strong: true),
            _row('Custo por unidade', calculation.unitCost(quantity)),
            _row('Preço por unidade', calculation.unitPrice(quantity)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Margem real sobre a venda: '
                '${calculation.profitPercent.toStringAsFixed(1)}%',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              money.format(calculation.salePrice),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Text('PREÇO DE VENDA'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
