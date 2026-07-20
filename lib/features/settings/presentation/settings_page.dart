import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.business_outlined),
              title: Text('Dados da empresa'),
              subtitle: Text('Duo Print 3D'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              onTap: () => context.go('/settings/business'),
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Parâmetros de custos'),
              subtitle: const Text(
                'Energia, máquina, mão de obra, embalagem e margem',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Versão'),
              subtitle: Text('Founders Edition 0.6.2'),
            ),
          ),
        ],
      ),
    );
  }
}
