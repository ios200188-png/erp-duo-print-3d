import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../filaments/data/filament_repository.dart';
import '../../printers/data/printer_repository.dart';
import '../../projects/data/project_repository.dart';
import '../data/production_repository.dart';

class ProductionFormPage extends ConsumerStatefulWidget {
  const ProductionFormPage({super.key});

  @override
  ConsumerState<ProductionFormPage> createState() => _ProductionFormPageState();
}

class _ProductionFormPageState extends ConsumerState<ProductionFormPage> {
  int? _projectId;
  int? _printerId;
  int? _filamentId;
  final _planned = TextEditingController(text: '1');
  final _produced = TextEditingController(text: '0');
  final _estimatedWeight = TextEditingController(text: '0');
  final _estimatedMinutes = TextEditingController(text: '0');
  final _notes = TextEditingController();
  String _status = 'Aguardando';
  String _priority = 'Normal';
  DateTime? _scheduledDate;
  bool _saving = false;

  int _integer(String value) => int.tryParse(value.trim()) ?? 0;
  double _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _planned.dispose();
    _produced.dispose();
    _estimatedWeight.dispose();
    _estimatedMinutes.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = _scheduledDate ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected == null) return;
    setState(() {
      _scheduledDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        current.hour,
        current.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final current = _scheduledDate ?? DateTime.now();
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (selected == null) return;
    setState(() {
      _scheduledDate = DateTime(
        current.year,
        current.month,
        current.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_projectId == null) {
      _message('Selecione um projeto.');
      return;
    }
    if (_filamentId == null) {
      _message('Selecione o filamento que será utilizado.');
      return;
    }
    if (_integer(_planned.text) <= 0) {
      _message('Informe uma quantidade planejada válida.');
      return;
    }
    if (_number(_estimatedWeight.text) <= 0) {
      _message('Informe o peso previsto em gramas.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(productionRepositoryProvider)
          .save(
            projectId: _projectId!,
            printerId: _printerId,
            filamentId: _filamentId,
            quantityPlanned: _integer(_planned.text),
            quantityProduced: _integer(_produced.text),
            status: _status,
            priority: _priority,
            scheduledDate: _scheduledDate,
            estimatedWeight: _number(_estimatedWeight.text),
            estimatedMinutes: _integer(_estimatedMinutes.text),
            notes: _notes.text.trim(),
          );

      ref.invalidate(productionOrdersProvider);
      ref.invalidate(productionOpenCountProvider);
      if (mounted) context.go('/production');
    } catch (error) {
      _message(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final printers = ref.watch(printersProvider);
    final filaments = ref.watch(filamentsProvider);
    final date = DateFormat('dd/MM/yyyy');
    final time = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Nova ordem de produção')),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (projectItems) => printers.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro: $error')),
          data: (printerItems) => filaments.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erro: $error')),
            data: (filamentItems) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                  onChanged: (value) {
                    setState(() {
                      _projectId = value;
                      final matches = projectItems.where(
                        (item) => item.id == value,
                      );
                      final project = matches.isEmpty ? null : matches.first;
                      if (project != null) {
                        _estimatedWeight.text =
                            (project.estimatedWeight * _integer(_planned.text))
                                .toStringAsFixed(1);
                        _estimatedMinutes.text =
                            (project.printMinutes * _integer(_planned.text))
                                .toString();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _printerId,
                  decoration: const InputDecoration(labelText: 'Impressora'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Definir depois'),
                    ),
                    ...printerItems.map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _printerId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _filamentId,
                  decoration: const InputDecoration(
                    labelText: 'Filamento *',
                    helperText:
                        'O material será reservado ao iniciar a impressão.',
                  ),
                  items: filamentItems
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} — ${item.availableWeight.toStringAsFixed(0)} g disponíveis',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _filamentId = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _planned,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade planejada',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _produced,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade produzida',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _estimatedWeight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Peso previsto total (g)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _estimatedMinutes,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tempo previsto (min)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status inicial',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Aguardando',
                      child: Text('Aguardando'),
                    ),
                    DropdownMenuItem(
                      value: 'Preparando',
                      child: Text('Preparando'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'Aguardando'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Prioridade'),
                  items: const [
                    DropdownMenuItem(value: 'Baixa', child: Text('Baixa')),
                    DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                    DropdownMenuItem(value: 'Urgente', child: Text('Urgente')),
                  ],
                  onChanged: (value) =>
                      setState(() => _priority = value ?? 'Normal'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          _scheduledDate == null
                              ? 'Definir data'
                              : date.format(_scheduledDate!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(
                          _scheduledDate == null
                              ? 'Definir horário'
                              : time.format(_scheduledDate!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Observações'),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('SALVAR ORDEM'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
