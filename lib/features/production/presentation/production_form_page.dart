import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  final _planned = TextEditingController(text: '1');
  final _produced = TextEditingController(text: '0');
  final _notes = TextEditingController();
  String _status = 'Planejada';
  String _priority = 'Normal';
  DateTime? _scheduledDate;

  int _integer(String value) => int.tryParse(value) ?? 0;

  @override
  void dispose() {
    _planned.dispose();
    _produced.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null) {
      setState(() => _scheduledDate = selected);
    }
  }

  Future<void> _save() async {
    if (_projectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione um projeto.')));
      return;
    }

    await ref
        .read(productionRepositoryProvider)
        .save(
          projectId: _projectId!,
          printerId: _printerId,
          quantityPlanned: _integer(_planned.text),
          quantityProduced: _integer(_produced.text),
          status: _status,
          priority: _priority,
          scheduledDate: _scheduledDate,
          notes: _notes.text.trim(),
        );

    ref.invalidate(productionOrdersProvider);
    ref.invalidate(productionOpenCountProvider);

    if (!mounted) return;
    context.go('/production');
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final printers = ref.watch(printersProvider);
    final date = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Nova ordem de produção')),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (projectItems) => printers.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro: $error')),
          data: (printerItems) {
            return ListView(
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
                  onChanged: (value) => setState(() => _projectId = value),
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
                TextField(
                  controller: _planned,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade planejada',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _produced,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade produzida',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Planejada',
                      child: Text('Planejada'),
                    ),
                    DropdownMenuItem(
                      value: 'Imprimindo',
                      child: Text('Imprimindo'),
                    ),
                    DropdownMenuItem(value: 'Pausada', child: Text('Pausada')),
                    DropdownMenuItem(
                      value: 'Finalizada',
                      child: Text('Finalizada'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'Planejada'),
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
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _scheduledDate == null
                        ? 'Definir data prevista'
                        : 'Prevista para ${date.format(_scheduledDate!)}',
                  ),
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
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('SALVAR ORDEM'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
