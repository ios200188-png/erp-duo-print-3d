import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/filament_repository.dart';
import '../domain/filament.dart';

class FilamentFormPage extends ConsumerStatefulWidget {
  const FilamentFormPage({this.filamentId, super.key});

  final int? filamentId;

  @override
  ConsumerState<FilamentFormPage> createState() => _FilamentFormPageState();
}

class _FilamentFormPageState extends ConsumerState<FilamentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _type = TextEditingController(text: 'PLA');
  final _brand = TextEditingController();
  final _color = TextEditingController();
  final _initialWeight = TextEditingController(text: '1000');
  final _currentWeight = TextEditingController(text: '1000');
  final _price = TextEditingController();
  final _minimum = TextEditingController(text: '200');
  final _supplier = TextEditingController();
  final _notes = TextEditingController();
  bool _loaded = false;

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;

  void _fill(Filament item) {
    if (_loaded) return;
    _loaded = true;
    _name.text = item.name;
    _type.text = item.materialType;
    _brand.text = item.brand;
    _color.text = item.color;
    _initialWeight.text = item.initialWeight.toStringAsFixed(0);
    _currentWeight.text = item.currentWeight.toStringAsFixed(0);
    _price.text = item.purchasePrice.toStringAsFixed(2).replaceAll('.', ',');
    _minimum.text = item.minimumStock.toStringAsFixed(0);
    _supplier.text = item.supplier;
    _notes.text = item.notes;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(filamentRepositoryProvider)
        .save(
          id: widget.filamentId,
          name: _name.text.trim(),
          materialType: _type.text.trim(),
          brand: _brand.text.trim(),
          color: _color.text.trim(),
          initialWeight: _number(_initialWeight.text),
          currentWeight: _number(_currentWeight.text),
          purchasePrice: _number(_price.text),
          minimumStock: _number(_minimum.text),
          supplier: _supplier.text.trim(),
          notes: _notes.text.trim(),
        );

    ref.invalidate(filamentsProvider);
    ref.invalidate(filamentCountProvider);
    ref.invalidate(lowStockCountProvider);

    if (mounted) context.go('/filaments');
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.filamentId == null
        ? const AsyncValue<Filament?>.data(null)
        : ref.watch(filamentByIdProvider(widget.filamentId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filamentId == null ? 'Novo filamento' : 'Editar filamento',
        ),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (item) {
          if (item != null) _fill(item);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _field(_name, 'Nome *'),
                _field(_type, 'Material *'),
                _field(_brand, 'Marca'),
                _field(_color, 'Cor'),
                _field(_initialWeight, 'Peso inicial (g) *', number: true),
                _field(_currentWeight, 'Peso restante (g) *', number: true),
                _field(_price, 'Valor pago (R\$) *', number: true),
                _field(_minimum, 'Estoque mínimo (g)', number: true),
                _field(_supplier, 'Fornecedor'),
                _field(_notes, 'Observações', lines: 3),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('SALVAR FILAMENTO'),
                  ),
                ),
              ],
            ),
          );
        },
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
