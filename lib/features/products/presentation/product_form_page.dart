import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../filaments/data/filament_repository.dart';
import '../../printers/data/printer_repository.dart';
import '../../settings/data/business_settings_repository.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({this.productId, super.key});

  final int? productId;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _color = TextEditingController();
  final _weight = TextEditingController(text: '0');
  final _hours = TextEditingController(text: '0');
  final _minutes = TextEditingController(text: '0');
  final _laborMinutes = TextEditingController(text: '0');
  final _layer = TextEditingController(text: '0,20');
  final _infill = TextEditingController(text: '15');
  final _walls = TextEditingController(text: '2');
  final _nozzle = TextEditingController(text: '0,4');
  final _packaging = TextEditingController(text: '0');
  final _additional = TextEditingController(text: '0');
  final _price = TextEditingController(text: '0');
  final _notes = TextEditingController();

  int? _filamentId;
  int? _printerId;
  bool _supports = false;
  bool _active = true;
  bool _loaded = false;

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;
  int _integer(String value) => int.tryParse(value) ?? 0;

  void _fill(Product item) {
    if (_loaded) return;
    _loaded = true;
    _code.text = item.code;
    _name.text = item.name;
    _category.text = item.category;
    _description.text = item.description;
    _filamentId = item.filamentId;
    _printerId = item.printerId;
    _color.text = item.color;
    _weight.text = item.estimatedWeight.toStringAsFixed(0);
    _hours.text = (item.printMinutes ~/ 60).toString();
    _minutes.text = (item.printMinutes % 60).toString();
    _laborMinutes.text = item.laborMinutes.toString();
    _layer.text = item.layerHeight.toString().replaceAll('.', ',');
    _infill.text = item.infillPercent.toStringAsFixed(0);
    _walls.text = item.wallCount.toString();
    _supports = item.supports;
    _nozzle.text = item.nozzleSize.toString().replaceAll('.', ',');
    _packaging.text = item.packagingCost
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    _additional.text = item.additionalCost
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    _price.text = item.suggestedPrice.toStringAsFixed(2).replaceAll('.', ',');
    _active = item.active;
    _notes.text = item.notes;
  }

  Future<_CostPreview> _calculate() async {
    final settings = await ref.read(businessSettingsProvider.future);
    final filaments = await ref.read(filamentsProvider.future);
    final selected = filaments.where((item) => item.id == _filamentId);
    final costPerGram = selected.isEmpty ? 0 : selected.first.costPerGram;
    final printMinutes = (_integer(_hours.text) * 60) + _integer(_minutes.text);
    final printHours = printMinutes / 60;
    final laborHours = _integer(_laborMinutes.text) / 60;

    final material = _number(_weight.text) * costPerGram;
    final energy =
        (settings.printerPowerW / 1000) * printHours * settings.kwhPrice;
    final machine = printHours * settings.machineHour;
    final labor = laborHours * settings.laborHour;
    final packaging = _number(_packaging.text);
    final additional = _number(_additional.text);
    final subtotal =
        material + energy + machine + labor + packaging + additional;
    final maintenance = subtotal * settings.maintenancePercent / 100;
    final withMaintenance = subtotal + maintenance;
    final failures = withMaintenance * settings.failurePercent / 100;
    final total = withMaintenance + failures;
    final divisor = 1 - (settings.idealMarginPercent / 100);
    final suggested = divisor <= 0 ? total : total / divisor;

    return _CostPreview(
      material: material,
      energy: energy,
      machine: machine,
      labor: labor,
      maintenance: maintenance,
      failures: failures,
      packaging: packaging,
      additional: additional,
      total: total,
      suggested: suggested,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final preview = await _calculate();
    final enteredPrice = _number(_price.text);
    final printMinutes = (_integer(_hours.text) * 60) + _integer(_minutes.text);

    try {
      await ref
          .read(productRepositoryProvider)
          .save(
            id: widget.productId,
            code: _code.text.trim(),
            name: _name.text.trim(),
            category: _category.text.trim(),
            description: _description.text.trim(),
            filamentId: _filamentId,
            printerId: _printerId,
            color: _color.text.trim(),
            estimatedWeight: _number(_weight.text),
            printMinutes: printMinutes,
            laborMinutes: _integer(_laborMinutes.text),
            layerHeight: _number(_layer.text),
            infillPercent: _number(_infill.text),
            wallCount: _integer(_walls.text),
            supports: _supports,
            nozzleSize: _number(_nozzle.text),
            packagingCost: _number(_packaging.text),
            additionalCost: _number(_additional.text),
            totalCost: preview.total,
            suggestedPrice: enteredPrice > 0 ? enteredPrice : preview.suggested,
            active: _active,
            notes: _notes.text.trim(),
          );
      ref.invalidate(productsProvider);
      ref.invalidate(productCountProvider);
      if (mounted) context.go('/products');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.productId == null
        ? const AsyncValue<Product?>.data(null)
        : ref.watch(productByIdProvider(widget.productId!));
    final filaments = ref.watch(filamentsProvider);
    final printers = ref.watch(printersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productId == null ? 'Novo produto' : 'Editar produto',
        ),
      ),
      body: product.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (item) {
          if (item != null) _fill(item);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _SectionTitle('Dados gerais'),
                Row(
                  children: [
                    Expanded(child: _field(_code, 'Código *')),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _field(_name, 'Nome *')),
                  ],
                ),
                _field(_category, 'Categoria'),
                _field(_description, 'Descrição', lines: 3),
                const _SectionTitle('Configuração técnica'),
                filaments.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text('Erro nos filamentos: $error'),
                  data: (items) => DropdownButtonFormField<int?>(
                    initialValue: _filamentId,
                    decoration: const InputDecoration(
                      labelText: 'Filamento padrão',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Nenhum'),
                      ),
                      ...items.map(
                        (value) => DropdownMenuItem<int?>(
                          value: value.id,
                          child: Text('${value.name} • ${value.color}'),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _filamentId = value),
                  ),
                ),
                const SizedBox(height: 12),
                printers.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text('Erro nas impressoras: $error'),
                  data: (items) => DropdownButtonFormField<int?>(
                    initialValue: _printerId,
                    decoration: const InputDecoration(
                      labelText: 'Impressora recomendada',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Nenhuma'),
                      ),
                      ...items
                          .where((item) => item.active)
                          .map(
                            (value) => DropdownMenuItem<int?>(
                              value: value.id,
                              child: Text(value.name),
                            ),
                          ),
                    ],
                    onChanged: (value) => setState(() => _printerId = value),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(_color, 'Cor padrão')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(_weight, 'Peso (g) *', number: true),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _field(_hours, 'Horas', number: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_minutes, 'Minutos', number: true)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _laborMinutes,
                        'Mão de obra (min)',
                        number: true,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _field(_layer, 'Camada (mm)', number: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(_infill, 'Infill (%)', number: true),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _field(_walls, 'Paredes', number: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_nozzle, 'Bico (mm)', number: true)),
                  ],
                ),
                SwitchListTile(
                  value: _supports,
                  onChanged: (value) => setState(() => _supports = value),
                  title: const Text('Utiliza suportes'),
                  contentPadding: EdgeInsets.zero,
                ),
                const _SectionTitle('Custos e preço'),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _packaging,
                        'Embalagem (R\$)',
                        number: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _additional,
                        'Adicionais (R\$)',
                        number: true,
                      ),
                    ),
                  ],
                ),
                _field(
                  _price,
                  'Preço de venda (R\$) — 0 para usar o sugerido',
                  number: true,
                ),
                OutlinedButton.icon(
                  onPressed: _showCostPreview,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('CALCULAR CUSTO E PREÇO SUGERIDO'),
                  ),
                ),
                const SizedBox(height: 16),
                _field(_notes, 'Observações', lines: 3),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Produto ativo'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('SALVAR PRODUTO'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCostPreview() async {
    final preview = await _calculate();
    if (!mounted) return;
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Composição do custo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _costLine('Material', preview.material, money),
            _costLine('Energia', preview.energy, money),
            _costLine('Máquina', preview.machine, money),
            _costLine('Mão de obra', preview.labor, money),
            _costLine('Embalagem', preview.packaging, money),
            _costLine('Adicionais', preview.additional, money),
            _costLine('Manutenção', preview.maintenance, money),
            _costLine('Perdas e falhas', preview.failures, money),
            const Divider(),
            _costLine('Custo total', preview.total, money, bold: true),
            _costLine('Preço sugerido', preview.suggested, money, bold: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () {
              _price.text = preview.suggested
                  .toStringAsFixed(2)
                  .replaceAll('.', ',');
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Usar preço sugerido'),
          ),
        ],
      ),
    );
  }

  Widget _costLine(
    String label,
    double value,
    NumberFormat money, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            money.format(value),
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : null),
          ),
        ],
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
      child: TextFormField(
        controller: controller,
        minLines: lines,
        maxLines: lines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: label.contains('*')
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Campo obrigatório.'
                  : null
            : null,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _CostPreview {
  const _CostPreview({
    required this.material,
    required this.energy,
    required this.machine,
    required this.labor,
    required this.maintenance,
    required this.failures,
    required this.packaging,
    required this.additional,
    required this.total,
    required this.suggested,
  });

  final double material;
  final double energy;
  final double machine;
  final double labor;
  final double maintenance;
  final double failures;
  final double packaging;
  final double additional;
  final double total;
  final double suggested;
}
