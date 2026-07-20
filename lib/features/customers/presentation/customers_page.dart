import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/customer_repository.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                hintText: 'Buscar cliente',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: customers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erro: $error')),
              data: (items) {
                final query = _search.trim().toLowerCase();
                final filtered = items.where((customer) {
                  if (query.isEmpty) return true;
                  return customer.name.toLowerCase().contains(query) ||
                      customer.phone.toLowerCase().contains(query) ||
                      customer.email.toLowerCase().contains(query) ||
                      customer.document.toLowerCase().contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.people_outline,
                    title: 'Nenhum cliente encontrado',
                    subtitle: 'Cadastre o primeiro cliente para começar.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(customer.name[0].toUpperCase()),
                        ),
                        title: Text(customer.name),
                        subtitle: Text(
                          [customer.phone, customer.email]
                              .where((item) => item.isNotEmpty)
                              .join(' • '),
                        ),
                        onTap: () =>
                            context.go('/customers/${customer.id}/edit'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref
                                .read(customerRepositoryProvider)
                                .delete(customer.id);
                            ref.invalidate(customersProvider);
                            ref.invalidate(customerCountProvider);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/customers/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Novo cliente'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
