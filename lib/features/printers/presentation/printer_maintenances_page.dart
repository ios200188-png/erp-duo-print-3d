import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/printer_maintenance_repository.dart';
import '../data/printer_repository.dart';

class PrinterMaintenancesPage extends ConsumerWidget {
  const PrinterMaintenancesPage({required this.printerId, super.key});

  final int printerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printer = ref.watch(printerByIdProvider(printerId));
    final maintenances = ref.watch(printerMaintenancesProvider(printerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          printer.asData?.value == null
              ? 'Manutenções'
              : 'Manutenções • ${printer.asData!.value!.name}',
        ),
      ),
      body: maintenances.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Nenhuma manutenção registrada.\nUse o botão abaixo para criar o primeiro registro.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.build_circle_outlined),
                  ),
                  title: Text(item.type),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy').format(item.performedAt)} • '
                    '${item.printerHours.toStringAsFixed(0)} h\n'
                    '${item.description.isEmpty ? 'Sem descrição' : item.description}'
                    '${item.cost > 0 ? ' • R\$ ${item.cost.toStringAsFixed(2).replaceAll('.', ',')}' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Excluir registro',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref
                          .read(printerMaintenanceRepositoryProvider)
                          .delete(item.id);
                      ref.invalidate(printerMaintenancesProvider(printerId));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar manutenção'),
      ),
    );
  }

  Future<void> _showRegisterDialog(BuildContext context, WidgetRef ref) async {
    final printer = await ref.read(printerByIdProvider(printerId).future);
    if (printer == null || !context.mounted) return;

    final formKey = GlobalKey<FormState>();
    final description = TextEditingController();
    final hours = TextEditingController(
      text: printer.printedHours.toStringAsFixed(0),
    );
    final cost = TextEditingController(text: '0');
    final nextDue = TextEditingController(
      text: (printer.printedHours + printer.maintenanceInterval)
          .toStringAsFixed(0),
    );
    final notes = TextEditingController();
    var type = 'Preventiva';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar manutenção'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Preventiva',
                          child: Text('Preventiva'),
                        ),
                        DropdownMenuItem(
                          value: 'Corretiva',
                          child: Text('Corretiva'),
                        ),
                        DropdownMenuItem(
                          value: 'Limpeza',
                          child: Text('Limpeza'),
                        ),
                        DropdownMenuItem(
                          value: 'Troca de peça',
                          child: Text('Troca de peça'),
                        ),
                      ],
                      onChanged: (value) => setState(() => type = value!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: description,
                      decoration: const InputDecoration(
                        labelText: 'Serviço realizado *',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Informe o serviço realizado.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: hours,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Horas atuais da impressora',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nextDue,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Próxima manutenção (horas)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cost,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Custo (R\$)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    double number(String value) =>
        double.tryParse(value.replaceAll(',', '.')) ?? 0;

    await ref
        .read(printerMaintenanceRepositoryProvider)
        .register(
          printerId: printerId,
          type: type,
          description: description.text.trim(),
          printerHours: number(hours.text),
          cost: number(cost.text),
          performedAt: DateTime.now(),
          nextDueHours: nextDue.text.trim().isEmpty
              ? null
              : number(nextDue.text),
          notes: notes.text.trim(),
        );
    ref.invalidate(printerMaintenancesProvider(printerId));
    ref.invalidate(printerByIdProvider(printerId));
    ref.invalidate(printersProvider);
  }
}
