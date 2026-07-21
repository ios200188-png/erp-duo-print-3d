import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulos'),
        automaticallyImplyLeading: false,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
        children: [
          _ModuleCard(
            title: 'Filamentos',
            subtitle: 'Estoque e custos',
            icon: Icons.all_inclusive,
            onTap: () => context.go('/filaments'),
          ),
          _ModuleCard(
            title: 'Impressoras',
            subtitle: 'Horas e manutenção',
            icon: Icons.print_outlined,
            onTap: () => context.go('/printers'),
          ),
          _ModuleCard(
            title: 'Produtos',
            subtitle: 'Catálogo e custos',
            icon: Icons.inventory_2_outlined,
            onTap: () => context.go('/products'),
          ),
          _ModuleCard(
            title: 'Projetos',
            subtitle: 'Modelos e versões',
            icon: Icons.view_in_ar_outlined,
            onTap: () => context.go('/projects'),
          ),
          _ModuleCard(
            title: 'Orçamentos',
            subtitle: 'Custos e preços',
            icon: Icons.request_quote_outlined,
            onTap: () => context.go('/quotes'),
          ),
          _ModuleCard(
            title: 'Produção',
            subtitle: 'Ordens e andamento',
            icon: Icons.precision_manufacturing_outlined,
            onTap: () => context.go('/production'),
          ),
          _ModuleCard(
            title: 'Financeiro',
            subtitle: 'Caixa, pagar e receber',
            icon: Icons.account_balance_wallet_outlined,
            onTap: () => context.go('/finance'),
          ),
          _ModuleCard(
            title: 'Faturamento',
            subtitle: 'Emitir e enviar PDF',
            icon: Icons.receipt_long_outlined,
            onTap: () => context.go('/billing'),
          ),
          _ModuleCard(
            title: 'Agenda',
            subtitle: 'Prazos e alertas',
            icon: Icons.event_note_outlined,
            onTap: () => context.go('/agenda'),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
