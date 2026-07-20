import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/printer_repository.dart';
import '../domain/printer.dart';

class PrinterFormPage extends ConsumerStatefulWidget {
  const PrinterFormPage({this.printerId, super.key});

  final int? printerId;

  @override
  ConsumerState<PrinterFormPage> createState() => _PrinterFormPageState();
}

class _PrinterFormPageState extends ConsumerState<PrinterFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _manufacturer = TextEditingController(text: 'Bambu Lab');
  final _model = TextEditingController();
  final _serial = TextEditingController();
  final _nozzle = TextEditingController(text: '0,4');
  final _price = TextEditingController();
  final _hours = TextEditingController(text: '0');
  final _interval = TextEditingController(text: '500');
  final _lastMaintenance = TextEditingController(text: '0');
  final _notes = TextEditingController();
  bool _active = true;
  bool _loaded = false;

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;

  void _fill(Printer item) {
    if (_loaded) return;
    _loaded = true;
    _name.text = item.name;
    _manufacturer.text = item.manufacturer;
    _model.text = item.model;
    _serial.text = item.serialNumber;
    _nozzle.text = item.nozzleSize.toString().replaceAll('.', ',');
    _price.text = item.purchasePrice.toStringAsFixed(2).replaceAll('.', ',');
    _hours.text = item.printedHours.toStringAsFixed(0);
    _interval.text = item.maintenanceInterval.toStringAsFixed(0);
    _lastMaintenance.text = item.lastMaintenanceHours.toStringAsFixed(0);
    _notes.text = item.notes;
    _active = item.active;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(printerRepositoryProvider)
        .save(
          id: widget.printerId,
          name: _name.text.trim(),
          manufacturer: _manufacturer.text.trim(),
          model: _model.text.trim(),
          serialNumber: _serial.text.trim(),
          nozzleSize: _number(_nozzle.text),
          purchasePrice: _number(_price.text),
          printedHours: _number(_hours.text),
          maintenanceInterval: _number(_interval.text),
          lastMaintenanceHours: _number(_lastMaintenance.text),
          active: _active,
          notes: _notes.text.trim(),
        );

    ref.invalidate(printersProvider);
    ref.invalidate(printerCountProvider);

    if (mounted) context.go('/printers');
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.printerId == null
        ? const AsyncValue<Printer?>.data(null)
        : ref.watch(printerByIdProvider(widget.printerId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.printerId == null ? 'Nova impressora' : 'Editar impressora',
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
                _field(_manufacturer, 'Fabricante'),
                _field(_model, 'Modelo'),
                _field(_serial, 'Número de série'),
                _field(_nozzle, 'Bico (mm)', number: true),
                _field(_price, 'Valor de compra (R\$)', number: true),
                _field(_hours, 'Horas impressas', number: true),
                _field(_interval, 'Intervalo de manutenção (h)', number: true),
                _field(
                  _lastMaintenance,
                  'Horas na última manutenção',
                  number: true,
                ),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Impressora ativa'),
                ),
                _field(_notes, 'Observações', lines: 3),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('SALVAR IMPRESSORA'),
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
