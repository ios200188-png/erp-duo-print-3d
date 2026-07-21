import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/product_assets_repository.dart';
import '../data/product_repository.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({required this.productId, super.key});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));
    return product.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Erro: $error'))),
      data: (item) {
        if (item == null) {
          return const Scaffold(
            body: Center(child: Text('Produto não encontrado.')),
          );
        }
        final money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(item.name),
              actions: [
                IconButton(
                  tooltip: 'Editar produto',
                  onPressed: () => context.go('/products/${item.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.info_outline), text: 'Resumo'),
                  Tab(icon: Icon(Icons.image_outlined), text: 'Imagens'),
                  Tab(icon: Icon(Icons.folder_open_outlined), text: 'Arquivos'),
                  Tab(icon: Icon(Icons.history_outlined), text: 'Versões'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.code,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(item.description),
                            ],
                            const Divider(height: 28),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Text(
                                    '${item.estimatedWeight.toStringAsFixed(0)} g',
                                  ),
                                ),
                                Chip(label: Text(item.formattedTime)),
                                if (item.filamentName.isNotEmpty)
                                  Chip(label: Text(item.filamentName)),
                                if (item.printerName.isNotEmpty)
                                  Chip(label: Text(item.printerName)),
                                Chip(
                                  label: Text(
                                    item.active ? 'Ativo' : 'Inativo',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                'Custo',
                                money.format(item.totalCost),
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                'Venda',
                                money.format(item.suggestedPrice),
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                'Margem',
                                '${item.marginPercent.toStringAsFixed(1)}%',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                _ImagesTab(productId: productId),
                _FilesTab(productId: productId),
                _VersionsTab(
                  productId: productId,
                  defaultWeight: item.estimatedWeight,
                  defaultMinutes: item.printMinutes,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _ImagesTab extends ConsumerWidget {
  const _ImagesTab({required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(productImagesProvider(productId));
    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Nenhuma imagem cadastrada.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        item.isPrimary ? Icons.star : Icons.image_outlined,
                      ),
                      title: Text(
                        item.caption.isEmpty ? item.filePath : item.caption,
                      ),
                      subtitle: Text(item.filePath),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          final repo = ref.read(
                            productAssetsRepositoryProvider,
                          );
                          if (value == 'primary') {
                            await repo.setPrimary(productId, item.id);
                          }

                          if (value == 'delete') {
                            await repo.deleteImage(item.id);
                          }

                          ref.invalidate(productImagesProvider(productId));
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'primary',
                            child: Text('Definir como principal'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addImage(context, ref),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Adicionar imagem'),
      ),
    );
  }

  Future<void> _addImage(BuildContext context, WidgetRef ref) async {
    final path = TextEditingController();
    final caption = TextEditingController();
    var primary = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar imagem'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: path,
                  decoration: const InputDecoration(
                    labelText: 'Caminho ou URL da imagem *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caption,
                  decoration: const InputDecoration(labelText: 'Legenda'),
                ),
                CheckboxListTile(
                  value: primary,
                  onChanged: (v) => setState(() => primary = v ?? false),
                  title: const Text('Imagem principal'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, path.text.trim().isNotEmpty),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    await ref
        .read(productAssetsRepositoryProvider)
        .addImage(
          productId: productId,
          filePath: path.text.trim(),
          caption: caption.text.trim(),
          primary: primary,
        );
    ref.invalidate(productImagesProvider(productId));
  }
}

class _FilesTab extends ConsumerWidget {
  const _FilesTab({required this.productId});
  final int productId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(productFilesProvider(productId));
    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Nenhum arquivo cadastrado.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(item.fileType)),
                      title: Text(item.fileName),
                      subtitle: Text(
                        '${item.filePath}${item.version.isEmpty ? '' : '\nVersão ${item.version}'}',
                      ),
                      isThreeLine: item.version.isNotEmpty,
                      trailing: IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref
                              .read(productAssetsRepositoryProvider)
                              .deleteFile(item.id);
                          ref.invalidate(productFilesProvider(productId));
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFile(context, ref),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Adicionar arquivo'),
      ),
    );
  }

  Future<void> _addFile(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final path = TextEditingController();
    final version = TextEditingController();
    final notes = TextEditingController();
    var type = 'STL';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar arquivo'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const ['STL', '3MF', 'GCODE', 'PDF', 'FOTO', 'OUTRO']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v ?? type),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nome do arquivo *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: path,
                    decoration: const InputDecoration(
                      labelText: 'Caminho do arquivo *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: version,
                    decoration: const InputDecoration(labelText: 'Versão'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Observações'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                name.text.trim().isNotEmpty && path.text.trim().isNotEmpty,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    await ref
        .read(productAssetsRepositoryProvider)
        .addFile(
          productId: productId,
          type: type,
          name: name.text.trim(),
          path: path.text.trim(),
          version: version.text.trim(),
          notes: notes.text.trim(),
        );
    ref.invalidate(productFilesProvider(productId));
  }
}

class _VersionsTab extends ConsumerWidget {
  const _VersionsTab({
    required this.productId,
    required this.defaultWeight,
    required this.defaultMinutes,
  });
  final int productId;
  final double defaultWeight;
  final int defaultMinutes;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(productVersionsProvider(productId));
    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Nenhuma versão registrada.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.history)),
                      title: Text('Versão ${item.version}'),
                      subtitle: Text(
                        '${item.description}\n${item.weight.toStringAsFixed(0)} g • ${item.printMinutes} min',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref
                              .read(productAssetsRepositoryProvider)
                              .deleteVersion(item.id);
                          ref.invalidate(productVersionsProvider(productId));
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addVersion(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova versão'),
      ),
    );
  }

  Future<void> _addVersion(BuildContext context, WidgetRef ref) async {
    final version = TextEditingController();
    final description = TextEditingController();
    final weight = TextEditingController(
      text: defaultWeight.toStringAsFixed(0),
    );
    final minutes = TextEditingController(text: defaultMinutes.toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar versão'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: version,
                  decoration: const InputDecoration(labelText: 'Versão *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Alterações'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Peso (g)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minutes,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tempo (min)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, version.text.trim().isNotEmpty),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    double n(String v) => double.tryParse(v.replaceAll(',', '.')) ?? 0;
    await ref
        .read(productAssetsRepositoryProvider)
        .addVersion(
          productId: productId,
          version: version.text.trim(),
          description: description.text.trim(),
          weight: n(weight.text),
          printMinutes: int.tryParse(minutes.text) ?? 0,
        );
    ref.invalidate(productVersionsProvider(productId));
  }
}
