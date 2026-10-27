import 'package:flutter/material.dart';
import '../../app/theme.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  // ── Dicas de Saúde ──────────────────────────────────────────────────────────
  static final List<Map<String, dynamic>> _tips = [
    {
      'category': 'Medicamentos',
      'icon': Icons.medication,
      'color': AppTheme.primaryGreen,
      'title': 'Como tomar medicamentos corretamente',
      'content': 'Sempre leia a bula antes de usar qualquer medicamento. Respeite os horários e doses prescritas pelo médico. Nunca interrompa o tratamento por conta própria, mesmo que se sinta melhor.',
      'steps': [],
    },
    {
      'category': 'Medicamentos',
      'icon': Icons.warning_amber,
      'color': Colors.red,
      'title': 'Automedicação: riscos que você precisa conhecer',
      'content': 'Tomar medicamentos sem orientação médica pode mascarar sintomas graves e causar efeitos colaterais sérios. Sempre consulte um profissional de saúde antes de iniciar qualquer tratamento.',
      'steps': [],
    },
    {
      'category': 'Alimentação',
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'title': 'Alimentação saudável no dia a dia',
      'content': 'Prefira alimentos naturais e evite ultraprocessados. Consuma pelo menos 5 porções de frutas e verduras por dia. Beba de 2 a 3 litros de água diariamente.',
      'steps': [],
    },
    {
      'category': 'Exercícios',
      'icon': Icons.fitness_center,
      'color': Colors.blue,
      'title': 'Benefícios da atividade física',
      'content': 'Praticar 30 minutos de atividade moderada por dia melhora o humor, fortalece o coração e ajuda a manter o peso. Caminhadas são ótimas para começar.',
      'steps': [],
    },
    {
      'category': 'Prevenção',
      'icon': Icons.health_and_safety,
      'color': Colors.purple,
      'title': 'Prevenção de doenças comuns',
      'content': 'Lave as mãos com frequência, especialmente antes das refeições. Mantenha as vacinas em dia. Faça exames preventivos regularmente conforme orientação médica.',
      'steps': [],
    },
    {
      'category': 'Sono',
      'icon': Icons.bedtime,
      'color': Colors.indigo,
      'title': 'A importância do sono de qualidade',
      'content': 'Adultos precisam de 7 a 9 horas de sono por noite. Evite telas antes de dormir, mantenha o quarto escuro e fresco. Um bom sono melhora a memória e o sistema imunológico.',
      'steps': [],
    },
    {
      'category': 'Saúde Mental',
      'icon': Icons.psychology,
      'color': Colors.teal,
      'title': 'Cuidando da saúde mental',
      'content': 'Reserve tempo para atividades que você gosta. Converse com pessoas de confiança quando estiver sobrecarregado. Não hesite em buscar ajuda profissional quando precisar.',
      'steps': [],
    },
    {
      'category': 'Hidratação',
      'icon': Icons.water_drop,
      'color': Colors.cyan,
      'title': 'Importância de se manter hidratado',
      'content': 'A água representa cerca de 60% do corpo humano. A desidratação causa cansaço, dores de cabeça e dificuldade de concentração. Beba água ao longo do dia, sem esperar sentir sede.',
      'steps': [],
    },
  ];

  // ── Primeiros Socorros ───────────────────────────────────────────────────────
  static final List<Map<String, dynamic>> _firstAid = [
    {
      'category': 'Primeiros Socorros',
      'icon': Icons.local_hospital,
      'color': Colors.red,
      'urgency': 'EMERGÊNCIA',
      'urgencyColor': Colors.red,
      'title': 'Parada Cardiorrespiratória (PCR)',
      'content': 'A parada cardiorrespiratória ocorre quando o coração para de bater e a pessoa para de respirar. Cada minuto sem atendimento reduz as chances de sobrevivência em 10%. Aja imediatamente.',
      'steps': [
        'Verifique se a pessoa está consciente: chame pelo nome e sacuda levemente os ombros.',
        'Se não responder, peça ajuda em voz alta e ligue imediatamente para o SAMU (192).',
        'Deite a pessoa de costas em uma superfície firme.',
        'Entrelace as mãos e posicione o calcanhar da palma no centro do peito (sobre o osso esterno).',
        'Pressione forte e rápido: 5 a 6 cm de profundidade, 100 a 120 compressões por minuto.',
        'Se souber RCP: após 30 compressões, dê 2 respirações boca a boca.',
        'Continue até o SAMU chegar ou a pessoa reagir.',
      ],
      'warning': 'Ligue para o SAMU (192) antes de iniciar o atendimento.',
      'phone': '192',
    },
    {
      'category': 'Primeiros Socorros',
      'icon': Icons.monitor_heart,
      'color': Colors.deepOrange,
      'urgency': 'URGENTE',
      'urgencyColor': Colors.deepOrange,
      'title': 'Engasgamento',
      'content': 'O engasgamento ocorre quando um objeto bloqueia as vias aéreas. Em adultos e crianças acima de 1 ano, a Manobra de Heimlich é o procedimento indicado.',
      'steps': [
        'Pergunte: "Você está engasgado?" Se não conseguir falar, agir imediatamente.',
        'Fique atrás da pessoa, coloque um pé entre as pernas dela para apoio.',
        'Faça um punho com uma mão e posicione entre o umbigo e o osso do peito.',
        'Cubra o punho com a outra mão.',
        'Puxe com força para dentro e para cima, em movimentos rápidos.',
        'Repita até o objeto sair ou a pessoa perder a consciência.',
        'Se perder a consciência, deite-a e inicie RCP. Ligue para o SAMU (192).',
      ],
      'warning': 'Em bebês menores de 1 ano: use 5 tapas nas costas + 5 pressões no tórax. Não use Heimlich.',
      'phone': '192',
    },
    {
      'category': 'Primeiros Socorros',
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
      'urgency': 'URGENTE',
      'urgencyColor': Colors.orange,
      'title': 'Queimaduras',
      'content': 'Queimaduras são lesões causadas por calor, produtos químicos, eletricidade ou radiação. O tratamento correto nos primeiros minutos é fundamental para reduzir os danos.',
      'steps': [
        'Remova a pessoa da fonte de calor imediatamente.',
        'Resfrie a área queimada com água corrente fria (não gelada) por 10 a 20 minutos.',
        'Nunca use gelo, manteiga, pasta de dente ou qualquer produto caseiro.',
        'Remova roupas e acessórios da região afetada, exceto se estiverem colados à pele.',
        'Cubra levemente com um pano limpo e úmido.',
        'Para queimaduras extensas, graves ou com bolhas: vá ao pronto-socorro.',
        'Nunca estoure bolhas — elas protegem contra infecção.',
      ],
      'warning': 'Queimaduras com mais de 10% do corpo, na face, mãos, pés ou genitais: ligue 192.',
      'phone': '192',
    },
    {
      'category': 'Primeiros Socorros',
      'icon': Icons.bolt,
      'color': Colors.amber,
      'urgency': 'URGENTE',
      'urgencyColor': Colors.amber,
      'title': 'Convulsão / Epilepsia',
      'content': 'Uma convulsão é causada por atividade elétrica desordenada no cérebro. A maioria dura menos de 3 minutos e cessa sozinha. Seu papel é proteger a pessoa durante a crise.',
      'steps': [
        'Mantenha a calma. A convulsão geralmente passa sozinha.',
        'Afaste objetos duros e pontiagudos do redor da pessoa.',
        'Coloque algo macio embaixo da cabeça (casaco dobrado, por exemplo).',
        'Vire a pessoa de lado para evitar engasgo com saliva.',
        'NUNCA coloque nada na boca — não há risco de engolir a língua.',
        'NUNCA segure a pessoa com força para "parar" as contrações.',
        'Cronometre a duração da convulsão.',
        'Após a crise, mantenha a pessoa deitada de lado e tranquilize-a.',
      ],
      'warning': 'Ligue 192 se: a convulsão durar mais de 5 minutos, a pessoa não acordar após, houver lesão ou for a primeira crise.',
      'phone': '192',
    },
    {
      'category': 'Primeiros Socorros',
      'icon': Icons.bloodtype,
      'color': Colors.red.shade800,
      'urgency': 'URGENTE',
      'urgencyColor': Colors.red,
      'title': 'Hemorragia (Sangramento forte)',
      'content': 'Sangramentos intensos podem ser fatais em poucos minutos. O objetivo é interromper ou reduzir o fluxo de sangue até o socorro chegar.',
      'steps': [
        'Use luvas se disponível. Se não tiver, use um saco plástico ou tecido.',
        'Pressione o ferimento firmemente com um pano limpo ou gaze.',
        'Mantenha a pressão constante por pelo menos 10 minutos — não levante para verificar.',
        'Se o pano ensopar, adicione mais por cima sem retirar o anterior.',
        'Eleve o membro ferido acima do nível do coração, se possível.',
        'Não remova objetos encravados — pressione ao redor deles.',
        'Ligue para o SAMU (192) em sangramentos graves.',
      ],
      'warning': 'Sangramentos na cabeça, tórax ou abdômen: ligue 192 imediatamente.',
      'phone': '192',
    },
    {
      'category': 'Primeiros Socorros',
      'icon': Icons.psychology_alt,
      'color': Colors.purple.shade700,
      'urgency': 'URGENTE',
      'urgencyColor': Colors.deepOrange,
      'title': 'AVC (Derrame Cerebral)',
      'content': 'O AVC ocorre quando o fluxo de sangue ao cérebro é interrompido. Cada minuto conta — o cérebro perde 1,9 milhão de neurônios por minuto sem tratamento.',
      'steps': [
        'Reconheça os sinais com o método FAST:',
        'F — Face (Rosto): peça para sorrir. Um lado caiu?',
        'A — Arms (Braços): peça para levantar os dois. Um caiu?',
        'S — Speech (Fala): peça para repetir uma frase. Está estranha?',
        'T — Time (Tempo): se sim a qualquer um: LIGUE 192 AGORA.',
        'Não dê nada para comer ou beber.',
        'Deixe a pessoa confortável, de preferência deitada com a cabeça levemente elevada.',
        'Anote o horário exato em que os sintomas começaram.',
        'Não deixe a pessoa dormir — mantenha-a acordada e monitorada.',
      ],
      'warning': 'AVC é uma emergência. Cada minuto sem tratamento causa dano cerebral permanente.',
      'phone': '192',
    },
    {
      'category': 'Primeiros Socorros',
      'icon': Icons.thermostat,
      'color': Colors.blue.shade700,
      'urgency': 'ATENÇÃO',
      'urgencyColor': Colors.blue,
      'title': 'Hipotermia e Insolação',
      'content': 'Temperaturas extremas afetam o funcionamento do corpo. Tanto o frio intenso (hipotermia) quanto o calor excessivo (insolação) podem ser fatais sem tratamento correto.',
      'steps': [
        '— INSOLAÇÃO (calor) —',
        'Leve a pessoa para um local fresco e à sombra imediatamente.',
        'Refresque o corpo com panos úmidos frios ou aspersão de água.',
        'Ofereça água fresca em pequenos goles se estiver consciente.',
        'Não dê bebidas alcoólicas ou muito geladas.',
        '— HIPOTERMIA (frio) —',
        'Leve a pessoa para um ambiente aquecido.',
        'Remova roupas úmidas e cubra com cobertores secos.',
        'Ofereça bebida quente se estiver consciente e conseguir engolir.',
        'Não friccione os membros com força.',
      ],
      'warning': 'Se a pessoa perder a consciência ou convulsionar: ligue 192.',
      'phone': '192',
    },
    {
      'category': 'Primeiros Socorros',
      'icon': Icons.warning_rounded,
      'color': Colors.brown,
      'urgency': 'ATENÇÃO',
      'urgencyColor': Colors.orange,
      'title': 'Intoxicação e Envenenamento',
      'content': 'A intoxicação pode ocorrer por ingestão de produtos químicos, medicamentos em excesso, alimentos estragados ou picadas de animais peçonhentos.',
      'steps': [
        'Identifique o agente causador se possível (guarde a embalagem).',
        'NÃO provoque vômito — pode piorar em alguns casos.',
        'NÃO dê leite, óleo ou qualquer outro "neutralizante" caseiro.',
        'Se for produto químico na pele: lave com água corrente por 15 minutos.',
        'Se for nos olhos: lave com água corrente por 15 minutos.',
        'Ligue para o CVV de Toxicologia: 0800 722 6001 (24h, gratuito).',
        'Vá ao pronto-socorro levando a embalagem do produto ingerido.',
      ],
      'warning': 'Ligue 0800 722 6001 (Centro de Controle de Intoxicações) — funciona 24h e é gratuito.',
      'phone': '0800 722 6001',
    },
    {
      'category': 'Primeiros Socorros',
      'icon': Icons.bug_report,
      'color': Colors.green.shade800,
      'urgency': 'ATENÇÃO',
      'urgencyColor': Colors.orange,
      'title': 'Picadas de Animais Peçonhentos',
      'content': 'Picadas de cobras, escorpiões e aranhas podem ser fatais. O soro antiofídico está disponível em hospitais e deve ser administrado o mais rápido possível.',
      'steps': [
        'Mantenha a calma e imobilize o membro atingido.',
        'Não faça torniquete, não corte a picada e não suce o veneno.',
        'Não aplique gelo, calor ou substâncias caseiras.',
        'Remova anéis, relógios e roupas apertadas do membro afetado.',
        'Tente fotografar ou lembrar as características do animal — isso ajuda na escolha do soro.',
        'Vá imediatamente ao pronto-socorro mais próximo.',
        'Se possível, leve o animal morto ou uma foto para identificação.',
      ],
      'warning': 'Soro antiofídico só é eficaz nas primeiras horas. Não perca tempo.',
      'phone': '192',
    },
    {
      'category': 'Primeiros Socorros',
      'icon': Icons.water,
      'color': Colors.lightBlue.shade700,
      'urgency': 'EMERGÊNCIA',
      'urgencyColor': Colors.red,
      'title': 'Afogamento',
      'content': 'O afogamento pode causar morte em poucos minutos. Mesmo que a pessoa pareça bem após ser retirada da água, é obrigatório o atendimento médico.',
      'steps': [
        'Não entre na água se não for nadador treinado — use uma corda, boia ou prancha.',
        'Retire a vítima da água com cuidado.',
        'Se não respirar: inicie RCP (30 compressões + 2 respirações).',
        'Ligue para o SAMU (192) imediatamente.',
        'Mantenha a pessoa aquecida para evitar hipotermia.',
        'NÃO tente retirar água dos pulmões — foque na respiração.',
        'Mesmo que a pessoa acorde, leve ao hospital — o "afogamento secundário" pode ocorrer horas depois.',
      ],
      'warning': 'Todo afogado, mesmo consciente, deve ser avaliado no hospital.',
      'phone': '192',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saúde e Primeiros Socorros'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'Dicas de Saúde'),
              Tab(text: 'Primeiros Socorros'),
              Tab(text: 'Emergências'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TipsList(tips: _tips),
            _FirstAidList(items: _firstAid),
            const _EmergencyNumbers(),
          ],
        ),
      ),
    );
  }
}

// ── Lista de dicas de saúde ───────────────────────────────────────────────────
class _TipsList extends StatelessWidget {
  final List<Map<String, dynamic>> tips;
  const _TipsList({required this.tips});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        itemBuilder: (context, index) => _TipCard(tip: tips[index]),
      );
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
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tip['category'] as String,
                          style: TextStyle(color: color, fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    Text(tip['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 14, color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Text(tip['content'] as String,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
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

  void _showDetail(BuildContext context) {
    final color = tip['color'] as Color;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Container(width: 60, height: 60,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15)),
                  child: Icon(tip['icon'] as IconData, color: color, size: 34)),
              const SizedBox(height: 12),
              Text(tip['category'] as String,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(tip['title'] as String,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
              const SizedBox(height: 16),
              Text(tip['content'] as String,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textDark, height: 1.6)),
              const SizedBox(height: 24),
              _disclaimerBox(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Lista de primeiros socorros ───────────────────────────────────────────────
class _FirstAidList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _FirstAidList({required this.items});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => _FirstAidCard(item: items[index]),
      );
}

class _FirstAidCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _FirstAidCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color        = item['color'] as Color;
    final urgencyColor = item['urgencyColor'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'] as IconData, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: urgencyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(item['urgency'] as String,
                              style: TextStyle(color: urgencyColor,
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 14, color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Text(item['content'] as String,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
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

  void _showDetail(BuildContext context) {
    final color        = item['color'] as Color;
    final urgencyColor = item['urgencyColor'] as Color;
    final steps        = item['steps'] as List;
    final warning      = item['warning'] as String;
    final phone        = item['phone'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(width: 56, height: 56,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14)),
                      child: Icon(item['icon'] as IconData, color: color, size: 32)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: urgencyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(item['urgency'] as String,
                              style: TextStyle(color: urgencyColor,
                                  fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        const SizedBox(height: 6),
                        Text(item['title'] as String,
                            style: const TextStyle(fontSize: 18,
                                fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Descrição
              Text(item['content'] as String,
                  style: const TextStyle(fontSize: 15, color: AppTheme.textDark, height: 1.5)),
              const SizedBox(height: 20),

              // Passos
              if (steps.isNotEmpty) ...[
                Row(children: [
                  Icon(Icons.format_list_numbered, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text('O que fazer:', style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold, color: color)),
                ]),
                const SizedBox(height: 12),
                ...steps.asMap().entries.map((entry) {
                  final i    = entry.key;
                  final step = entry.value as String;
                  final isDivider = step.startsWith('—');
                  if (isDivider) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(step, style: TextStyle(
                          color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: TextStyle(color: color, fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(step, style: const TextStyle(
                              fontSize: 14, color: AppTheme.textDark, height: 1.5)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Aviso
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(warning,
                          style: TextStyle(color: Colors.orange.shade800,
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Botão ligar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone),
                  label: Text('Ligar $phone'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _disclaimerBox(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Números de emergência ─────────────────────────────────────────────────────
class _EmergencyNumbers extends StatelessWidget {
  const _EmergencyNumbers();

  static const _numbers = [
    {'name': 'SAMU',               'number': '192', 'desc': 'Urgências e emergências médicas', 'color': Colors.red,         'icon': Icons.local_hospital},
    {'name': 'Bombeiros',          'number': '193', 'desc': 'Incêndios, resgates e acidentes', 'color': Colors.orange,      'icon': Icons.local_fire_department},
    {'name': 'Polícia Militar',    'number': '190', 'desc': 'Segurança pública e crimes',      'color': Colors.blue,        'icon': Icons.security},
    {'name': 'Defesa Civil',       'number': '199', 'desc': 'Desastres naturais e enchentes',  'color': Colors.brown,       'icon': Icons.flood},
    {'name': 'CVV',                'number': '188', 'desc': 'Centro de Valorização da Vida (suicídio)', 'color': Colors.teal, 'icon': Icons.favorite},
    {'name': 'Disque Intoxicação', 'number': '0800 722 6001', 'desc': 'Envenenamentos e intoxicações', 'color': Colors.purple, 'icon': Icons.science},
    {'name': 'Ligue 180',          'number': '180', 'desc': 'Violência contra a mulher',       'color': Colors.pink,        'icon': Icons.woman},
    {'name': 'Disque 100',         'number': '100', 'desc': 'Direitos humanos e vulneráveis',  'color': Colors.indigo,      'icon': Icons.people},
  ];

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Em situação de emergência, ligue imediatamente.\nTodos os números são gratuitos.',
                    style: TextStyle(color: Colors.red,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          ..._numbers.map((n) {
            final color = n['color'] as Color;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(n['icon'] as IconData, color: color),
                ),
                title: Text(n['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(n['desc'] as String,
                    style: const TextStyle(fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(n['number'] as String,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                onTap: () {},
              ),
            );
          }),
        ],
      );
}

// ── Aviso médico padrão ───────────────────────────────────────────────────────
Widget _disclaimerBox() => Container(
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
              'Este conteúdo é informativo e não substitui orientação médica profissional. Em emergências, ligue para o SAMU (192).',
              style: TextStyle(fontSize: 11, color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );
