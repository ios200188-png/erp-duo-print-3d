import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cloud/cloud_backup_service.dart';
import '../../../core/database/app_database.dart';

class CloudSyncPage extends ConsumerStatefulWidget {
  const CloudSyncPage({super.key});

  @override
  ConsumerState<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends ConsumerState<CloudSyncPage> {
  bool _busy = false;
  DateTime? _lastUpdate;

  CloudBackupService get _service => CloudBackupService(
    ref.read(appDatabaseProvider),
    Supabase.instance.client,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _service.lastCloudUpdate();
      if (mounted) setState(() => _lastUpdate = value);
    } catch (_) {}
  }

  Future<void> _upload() async {
    await _run(() async {
      await _service.uploadSnapshot();
      await _load();
      _message('Dados enviados para a nuvem.');
    });
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Baixar dados da nuvem?'),
        content: const Text(
          'Os dados locais deste aparelho serão substituídos pelo backup mais recente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(() async {
      await _service.restoreLatestSnapshot();
      _message('Dados restaurados. Feche e abra o aplicativo novamente.');
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _message('Erro: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final last = _lastUpdate == null
        ? 'Nenhum backup enviado'
        : DateFormat('dd/MM/yyyy HH:mm').format(_lastUpdate!);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuvem e sincronização')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(user?.email ?? 'Usuário'),
              subtitle: const Text('Conta conectada ao Supabase'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_done_outlined),
              title: const Text('Última cópia na nuvem'),
              subtitle: Text(last),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _upload,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Enviar dados deste aparelho'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _restore,
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('Baixar dados para este aparelho'),
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Esta primeira versão Cloud usa sincronização manual segura. '
                'Envie os dados no aparelho principal e depois baixe no celular ou tablet. '
                'Não edite em dois aparelhos ao mesmo tempo até a sincronização em tempo real ser liberada.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () async => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
