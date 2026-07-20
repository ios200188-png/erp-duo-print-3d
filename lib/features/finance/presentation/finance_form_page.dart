import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/finance_repository.dart';

class FinanceFormPage extends ConsumerStatefulWidget {
  const FinanceFormPage({super.key});

  @override
  ConsumerState<FinanceFormPage> createState() => _FinanceFormPageState();
}

class _FinanceFormPageState extends ConsumerState<FinanceFormPage> {
  String _type = 'Receita';
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  DateTime _dueDate = DateTime.now();
  bool _paid = false;

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _category.dispose();
    _description.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  Future<void> _save() async {
    if (_description.text.trim().isEmpty || _number(_amount.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe descrição e valor maior que zero.'),
        ),
      );
      return;
    }

    await ref
        .read(financeRepositoryProvider)
        .save(
          type: _type,
          category: _category.text.trim(),
          description: _description.text.trim(),
          amount: _number(_amount.text),
          dueDate: _dueDate,
          paid: _paid,
          notes: _notes.text.trim(),
        );

    ref.invalidate(financialEntriesProvider);
    ref.invalidate(financeSummaryProvider);

    if (!mounted) return;
    context.go('/finance');
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Novo lançamento')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'Receita',
                label: Text('Receita'),
                icon: Icon(Icons.south_west),
              ),
              ButtonSegment(
                value: 'Despesa',
                label: Text('Despesa'),
                icon: Icon(Icons.north_east),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) {
              setState(() => _type = value.first);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Descrição *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Categoria'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor (R\$) *'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text('Vencimento: ${date.format(_dueDate)}'),
          ),
          SwitchListTile(
            value: _paid,
            onChanged: (value) => setState(() => _paid = value),
            title: Text(_type == 'Receita' ? 'Já recebida' : 'Já paga'),
          ),
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
              child: Text('SALVAR LANÇAMENTO'),
            ),
          ),
        ],
      ),
    );
  }
}
