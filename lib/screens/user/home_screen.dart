import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../app/theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final medications = ref.watch(medicationProvider);
    final runningLow = medications.where((m) => m.isActive && m.isRunningLow).toList();
    final activeMeds = medications.where((m) => m.isActive).toList();

    final firstName = authState.user?.name.split(' ').first ?? 'Usuário';

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: CustomScrollView(
        slivers: [
          // Header verde
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.primaryGreen,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Olá, $firstName! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Como você está hoje?',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Alerta de reposição
                if (runningLow.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${runningLow.length} remédio(s) acabando!',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                runningLow.map((m) => m.name).join(', '),
                                style: TextStyle(
                                    color: Colors.orange.shade600,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/pharmacies'),
                          child: const Text('Repor'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Resumo rápido
                Row(
                  children: [
                    _SummaryCard(
                      icon: Icons.medication,
                      label: 'Remédios\nativos',
                      value: '${activeMeds.length}',
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      icon: Icons.local_pharmacy,
                      label: 'Farmácias\npróximas',
                      value: '12',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      icon: Icons.health_and_safety,
                      label: 'Dicas\ndisponíveis',
                      value: '8',
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Ações rápidas
                const Text(
                  'O que você precisa?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _ActionCard(
                      icon: Icons.add_circle_outline,
                      label: 'Adicionar\nRemédio',
                      color: AppTheme.primaryGreen,
                      onTap: () => context.go('/medications'),
                    ),
                    _ActionCard(
                      icon: Icons.store_outlined,
                      label: 'Buscar\nFarmácia',
                      color: Colors.blue,
                      onTap: () => context.go('/pharmacies'),
                    ),
                    _ActionCard(
                      icon: Icons.alarm_outlined,
                      label: 'Meus\nLembretes',
                      color: Colors.orange,
                      onTap: () => context.go('/medications'),
                    ),
                    _ActionCard(
                      icon: Icons.tips_and_updates_outlined,
                      label: 'Dicas de\nSaúde',
                      color: Colors.purple,
                      onTap: () => context.go('/health-tips'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Próximas doses
                if (activeMeds.isNotEmpty) ...[
                  const Text(
                    'Próximas doses de hoje',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...activeMeds.take(3).map((med) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accentGreen,
                            child: const Icon(Icons.medication,
                                color: Colors.white),
                          ),
                          title: Text(med.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${med.dosage} • ${med.times.isNotEmpty ? med.times[0] : ""}'),
                          trailing: med.isRunningLow
                              ? const Icon(Icons.warning_amber,
                                  color: Colors.orange)
                              : const Icon(Icons.check_circle_outline,
                                  color: AppTheme.primaryGreen),
                        ),
                      )),
                ],

                // Aviso
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⚕️ Este app é uma ferramenta de apoio informativo. Sempre confirme medicamentos com seu médico ou farmacêutico.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
