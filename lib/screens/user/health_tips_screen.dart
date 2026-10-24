import 'package:flutter/material.dart';
import '../../app/theme.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  static final List<Map<String, dynamic>> _tips = [
    {
      'category': 'Medicamentos',
      'icon': Icons.medication,
      'color': AppTheme.primaryGreen,
      'title': 'Como tomar medicamentos corretamente',
      'content':
          'Sempre leia a bula antes de usar qualquer medicamento. Respeite os horários e doses prescritas pelo médico. Nunca interrompa o tratamento por conta própria, mesmo que se sinta melhor.',
    },
    {
      'category': 'Alimentação',
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'title': 'Alimentação saudável no dia a dia',
      'content':
          'Prefira alimentos naturais e evite ultraprocessados. Consuma pelo menos 5 porções de frutas e verduras por dia. Beba de 2 a 3 litros de água diariamente.',
    },
    {
      'category': 'Exercícios',
      'icon': Icons.fitness_center,
      'color': Colors.blue,
      'title': 'Benefícios da atividade física',
      'content':
          'Praticar 30 minutos de atividade moderada por dia melhora o humor, fortalece o coração e ajuda a manter o peso. Caminhadas são ótimas para começar.',
    },
    {
      'category': 'Prevenção',
      'icon': Icons.health_and_safety,
      'color': Colors.purple,
      'title': 'Prevenção de doenças comuns',
      'content':
          'Lave as mãos com frequência, especialmente antes das refeições. Mantenha as vacinas em dia. Faça exames preventivos regularmente conforme orientação médica.',
    },
    {
      'category': 'Sono',
      'icon': Icons.bedtime,
      'color': Colors.indigo,
      'title': 'A importância do sono de qualidade',
      'content':
          'Adultos precisam de 7 a 9 horas de sono por noite. Evite telas antes de dormir, mantenha o quarto escuro e fresco. Um bom sono melhora a memória e o sistema imunológico.',
    },
    {
      'category': 'Saúde Mental',
      'icon': Icons.psychology,
      'color': Colors.teal,
      'title': 'Cuidando da saúde mental',
      'content':
          'Reserve tempo para atividades que você gosta. Converse com pessoas de confiança quando estiver sobrecarregado. Não hesite em buscar ajuda profissional quando precisar.',
    },
    {
      'category': 'Hidratação',
      'icon': Icons.water_drop,
      'color': Colors.cyan,
      'title': 'Importância de se manter hidratado',
      'content':
          'A água representa cerca de 60% do corpo humano. A desidratação causa cansaço, dores de cabeça e dificuldade de concentração. Beba água ao longo do dia, sem esperar sentir sede.',
    },
    {
      'category': 'Medicamentos',
      'icon': Icons.warning_amber,
      'color': Colors.red,
      'title': 'Automedicação: riscos que você precisa conhecer',
      'content':
          'Tomar medicamentos sem orientação médica pode mascarar sintomas graves e causar efeitos colaterais sérios. Sempre consulte um profissional de saúde antes de iniciar qualquer tratamento.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final categories = _tips.map((t) => t['category'] as String).toSet().toList();

    return DefaultTabController(
      length: categories.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dicas de Saúde'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              const Tab(text: 'Todas'),
              ...categories.map((c) => Tab(text: c)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TipsList(tips: _tips),
            ...categories.map((cat) =>
                _TipsList(tips: _tips.where((t) => t['category'] == cat).toList())),
          ],
        ),
      ),
    );
  }
}

class _TipsList extends StatelessWidget {
  final List<Map<String, dynamic>> tips;
  const _TipsList({required this.tips});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        return _TipCard(tip: tip);
      },
    );
  }
}

class _TipCard extends StatelessWidget {
  final Map<String, dynamic> tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final color = tip['color'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTipDetail(context, tip),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tip['icon'] as IconData, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tip['category'] as String,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip['content'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  void _showTipDetail(BuildContext context, Map<String, dynamic> tip) {
    final color = tip['color'] as Color;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(tip['icon'] as IconData, color: color, size: 34),
              ),
              const SizedBox(height: 12),
              Text(
                tip['category'] as String,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                tip['title'] as String,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tip['content'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textDark,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outlined, size: 16, color: AppTheme.textGrey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta dica é informativa e não substitui orientação médica profissional.',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textGrey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
