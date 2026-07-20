import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/customer_repository.dart';
import '../domain/customer.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  const CustomerFormPage({this.customerId, super.key});

  final int? customerId;

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _document = TextEditingController();
  final _notes = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _document.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _fill(Customer customer) {
    if (_loaded) return;
    _loaded = true;
    _name.text = customer.name;
    _phone.text = customer.phone;
    _email.text = customer.email;
    _document.text = customer.document;
    _notes.text = customer.notes;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    await ref.read(customerRepositoryProvider).save(
          id: widget.customerId,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          document: _document.text.trim(),
          notes: _notes.text.trim(),
        );

    ref.invalidate(customersProvider);
    ref.invalidate(customerCountProvider);

    if (mounted) context.go('/customers');
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.customerId == null
        ? const AsyncValue<Customer?>.data(null)
        : ref.watch(customerByIdProvider(widget.customerId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerId == null ? 'Novo cliente' : 'Editar cliente'),
        leading: IconButton(
          onPressed: () => context.go('/customers'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (customer) {
          if (customer != null) _fill(customer);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Informe o nome.'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _document,
                  decoration: const InputDecoration(labelText: 'CPF/CNPJ'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Observações'),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('SALVAR CLIENTE'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
