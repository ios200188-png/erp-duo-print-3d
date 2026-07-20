import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/project_repository.dart';
import '../domain/project.dart';

class ProjectFormPage extends ConsumerStatefulWidget {
  const ProjectFormPage({this.projectId, super.key});

  final int? projectId;

  @override
  ConsumerState<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends ConsumerState<ProjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _version = TextEditingController();
  final _material = TextEditingController(text: 'PLA');
  final _weight = TextEditingController();
  final _hours = TextEditingController(text: '0');
  final _minutes = TextEditingController(text: '0');
  final _infill = TextEditingController(text: '15');
  final _layer = TextEditingController(text: '0,20');
  final _nozzle = TextEditingController(text: '0,4');
  final _price = TextEditingController();
  final _file = TextEditingController();
  final _notes = TextEditingController();
  bool _active = true;
  bool _loaded = false;

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;

  int _integer(String value) => int.tryParse(value) ?? 0;

  void _fill(Project item) {
    if (_loaded) return;
    _loaded = true;
    _name.text = item.name;
    _version.text = item.version;
    _material.text = item.defaultMaterial;
    _weight.text = item.estimatedWeight.toStringAsFixed(0);
    _hours.text = (item.printMinutes ~/ 60).toString();
    _minutes.text = (item.printMinutes % 60).toString();
    _infill.text = item.infillPercent.toStringAsFixed(0);
    _layer.text = item.layerHeight.toString().replaceAll('.', ',');
    _nozzle.text = item.nozzleSize.toString().replaceAll('.', ',');
    _price.text = item.suggestedPrice.toStringAsFixed(2).replaceAll('.', ',');
    _file.text = item.filePath;
    _notes.text = item.notes;
    _active = item.active;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final printMinutes = (_integer(_hours.text) * 60) + _integer(_minutes.text);

    await ref
        .read(projectRepositoryProvider)
        .save(
          id: widget.projectId,
          name: _name.text.trim(),
          version: _version.text.trim(),
          defaultMaterial: _material.text.trim(),
          estimatedWeight: _number(_weight.text),
          printMinutes: printMinutes,
          infillPercent: _number(_infill.text),
          layerHeight: _number(_layer.text),
          nozzleSize: _number(_nozzle.text),
          suggestedPrice: _number(_price.text),
          filePath: _file.text.trim(),
          notes: _notes.text.trim(),
          active: _active,
        );

    ref.invalidate(projectsProvider);
    ref.invalidate(projectCountProvider);

    if (mounted) context.go('/projects');
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.projectId == null
        ? const AsyncValue<Project?>.data(null)
        : ref.watch(projectByIdProvider(widget.projectId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.projectId == null ? 'Novo projeto' : 'Editar projeto',
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
                _field(_name, 'Nome do projeto *'),
                _field(_version, 'Versão/tamanho'),
                _field(_material, 'Material padrão *'),
                _field(_weight, 'Peso estimado (g) *', number: true),
                Row(
                  children: [
                    Expanded(child: _field(_hours, 'Horas', number: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_minutes, 'Minutos', number: true)),
                  ],
                ),
                _field(_infill, 'Infill (%)', number: true),
                _field(_layer, 'Altura de camada (mm)', number: true),
                _field(_nozzle, 'Bico (mm)', number: true),
                _field(_price, 'Preço sugerido (R\$)', number: true),
                _field(_file, 'Arquivo STL/3MF/GCODE'),
                _field(_notes, 'Observações', lines: 3),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Projeto ativo'),
                ),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('SALVAR PROJETO'),
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
