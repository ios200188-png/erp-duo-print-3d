import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../finance/data/finance_repository.dart';
import '../data/billing_repository.dart';

class BillingFormPage extends ConsumerStatefulWidget {
  const BillingFormPage({required this.quoteId, super.key});

  final int quoteId;

  @override
  ConsumerState<BillingFormPage> createState() => _BillingFormPageState();
}

class _BillingFormPageState extends ConsumerState<BillingFormPage> {
  String _paymentMethod = 'PIX';
  DateTime _dueDate = DateTime.now();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  Future<void> _issue() async {
    await ref
        .read(billingRepositoryProvider)
        .issue(
          quoteId: widget.quoteId,
          paymentMethod: _paymentMethod,
          dueDate: _dueDate,
          notes: _notes.text.trim(),
        );

    ref.invalidate(invoicesProvider);
    ref.invalidate(billableQuotesProvider);
    ref.invalidate(awaitingBillingCountProvider);
    ref.invalidate(financeSummaryProvider);
    ref.invalidate(financialEntriesProvider);

    if (!mounted) return;
    context.go('/billing');
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Emitir faturamento')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _paymentMethod,
            decoration: const InputDecoration(labelText: 'Forma de pagamento'),
            items: const [
              DropdownMenuItem(value: 'PIX', child: Text('PIX')),
              DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
              DropdownMenuItem(
                value: 'Cartão de débito',
                child: Text('Cartão de débito'),
              ),
              DropdownMenuItem(
                value: 'Cartão de crédito',
                child: Text('Cartão de crédito'),
              ),
              DropdownMenuItem(
                value: 'Transferência',
                child: Text('Transferência'),
              ),
              DropdownMenuItem(value: 'Boleto', child: Text('Boleto')),
            ],
            onChanged: (value) {
              setState(() => _paymentMethod = value ?? 'PIX');
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text('Vencimento: ${date.format(_dueDate)}'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Observações de pagamento',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _issue,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('EMITIR FATURA'),
            ),
          ),
        ],
      ),
    );
  }
}
