import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/business_settings_repository.dart';
import '../domain/business_settings.dart';

class BusinessSettingsPage extends ConsumerStatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  ConsumerState<BusinessSettingsPage> createState() =>
      _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends ConsumerState<BusinessSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _whatsapp = TextEditingController();
  final _document = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _kwh = TextEditingController();
  final _power = TextEditingController();
  final _labor = TextEditingController();
  final _machine = TextEditingController();
  final _packaging = TextEditingController();
  final _maintenance = TextEditingController();
  final _failure = TextEditingController();
  final _margin = TextEditingController();
  bool _loaded = false;

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;

  void _fill(BusinessSettings value) {
    if (_loaded) return;
    _loaded = true;
    _company.text = value.companyName;
    _whatsapp.text = value.whatsapp;
    _document.text = value.document;
    _email.text = value.email;
    _address.text = value.address;
    _city.text = value.city;
    _kwh.text = value.kwhPrice.toStringAsFixed(2).replaceAll('.', ',');
    _power.text = value.printerPowerW.toStringAsFixed(0);
    _labor.text = value.laborHour.toStringAsFixed(2).replaceAll('.', ',');
    _machine.text = value.machineHour.toStringAsFixed(2).replaceAll('.', ',');
    _packaging.text = value.packagingCost
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    _maintenance.text = value.maintenancePercent
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    _failure.text = value.failurePercent
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    _margin.text = value.idealMarginPercent
        .toStringAsFixed(1)
        .replaceAll('.', ',');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(businessSettingsRepositoryProvider)
        .save(
          BusinessSettings(
            companyName: _company.text.trim(),
            whatsapp: _whatsapp.text.trim(),
            document: _document.text.trim(),
            email: _email.text.trim(),
            address: _address.text.trim(),
            city: _city.text.trim(),
            kwhPrice: _number(_kwh.text),
            printerPowerW: _number(_power.text),
            laborHour: _number(_labor.text),
            machineHour: _number(_machine.text),
            packagingCost: _number(_packaging.text),
            maintenancePercent: _number(_maintenance.text),
            failurePercent: _number(_failure.text),
            idealMarginPercent: _number(_margin.text),
          ),
        );

    ref.invalidate(businessSettingsProvider);

    if (!mounted) return;
    context.go('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(businessSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dados e custos da empresa')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (value) {
          _fill(value);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Dados para o PDF',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _field(_company, 'Nome da empresa *'),
                _field(_document, 'CNPJ/CPF da empresa'),
                _field(_whatsapp, 'WhatsApp'),
                _field(_email, 'E-mail'),
                _field(_address, 'Endereço'),
                _field(_city, 'Cidade/UF'),
                const SizedBox(height: 10),
                Text(
                  'Parâmetros de custos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _field(_kwh, 'Valor do kWh (R\$) *', number: true),
                _field(
                  _power,
                  'Consumo médio da impressora (W) *',
                  number: true,
                ),
                _field(
                  _labor,
                  'Valor da hora de trabalho (R\$) *',
                  number: true,
                ),
                _field(
                  _machine,
                  'Custo da máquina por hora (R\$) *',
                  number: true,
                ),
                _field(
                  _packaging,
                  'Custo padrão da embalagem (R\$) *',
                  number: true,
                ),
                _field(
                  _maintenance,
                  'Reserva para manutenção (%) *',
                  number: true,
                ),
                _field(
                  _failure,
                  'Percentual de perdas/falhas (%) *',
                  number: true,
                ),
                _field(_margin, 'Margem ideal (%) *', number: true),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('SALVAR CONFIGURAÇÕES'),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
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
