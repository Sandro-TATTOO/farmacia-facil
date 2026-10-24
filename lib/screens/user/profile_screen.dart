import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../app/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header com avatar
            Container(
              width: double.infinity,
              color: AppTheme.primaryGreen,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Usuário',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Informações
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meus dados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _InfoCard(
                    items: [
                      _InfoItem(
                        icon: Icons.person_outlined,
                        label: 'Nome',
                        value: user?.name ?? 'Não informado',
                      ),
                      _InfoItem(
                        icon: Icons.email_outlined,
                        label: 'E-mail',
                        value: user?.email ?? 'Não informado',
                      ),
                      _InfoItem(
                        icon: Icons.phone_outlined,
                        label: 'Telefone',
                        value: user?.phone.isNotEmpty == true
                            ? user!.phone
                            : 'Não informado',
                      ),
                      _InfoItem(
                        icon: Icons.location_on_outlined,
                        label: 'Endereço',
                        value: user?.address.isNotEmpty == true
                            ? user!.address
                            : 'Não informado',
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Configurações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        _SettingsItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notificações',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 56),
                        _SettingsItem(
                          icon: Icons.edit_outlined,
                          label: 'Editar perfil',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 56),
                        _SettingsItem(
                          icon: Icons.lock_outlined,
                          label: 'Alterar senha',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 56),
                        _SettingsItem(
                          icon: Icons.help_outline,
                          label: 'Ajuda e suporte',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 56),
                        _SettingsItem(
                          icon: Icons.info_outline,
                          label: 'Sobre o app',
                          onTap: () => _showAbout(context),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sair
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Sair da conta',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_pharmacy, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Farmácia Fácil'),
          ],
        ),
        content: const Text(
          'Versão 1.0.0\n\nEste aplicativo é uma ferramenta de apoio informativo. Não substitui orientação médica. Sempre confirme medicamentos e dosagens com seu médico ou farmacêutico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(item.icon, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                              color: AppTheme.textGrey, fontSize: 12),
                        ),
                        Text(
                          item.value,
                          style: const TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!item.isLast) const Divider(height: 1, indent: 52),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryGreen),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
      onTap: onTap,
    );
  }
}
