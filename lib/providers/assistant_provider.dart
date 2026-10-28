import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../models/medication_model.dart';

// Firebase AI Logic — sem chave de API necessária

// ─── Ação navegável ───────────────────────────────────────────────────────────
class AssistantAction {
  final String label;
  final String route;
  final String icon;
  final bool   isCall;   // true = abre discador em vez de navegar
  final String? phone;

  const AssistantAction({
    required this.label,
    required this.route,
    required this.icon,
    this.isCall = false,
    this.phone,
  });
}

// ─── Estado ───────────────────────────────────────────────────────────────────
class AssistantState {
  final List<ChatMessage>     messages;
  final bool                  isLoading;
  final bool                  voiceEnabled;
  final bool                  isSpeaking;
  final List<AssistantAction> pendingActions;

  const AssistantState({
    this.messages       = const [],
    this.isLoading      = false,
    this.voiceEnabled   = true,
    this.isSpeaking     = false,
    this.pendingActions = const [],
  });

  AssistantState copyWith({
    List<ChatMessage>?     messages,
    bool?                  isLoading,
    bool?                  voiceEnabled,
    bool?                  isSpeaking,
    List<AssistantAction>? pendingActions,
  }) => AssistantState(
    messages:       messages       ?? this.messages,
    isLoading:      isLoading      ?? this.isLoading,
    voiceEnabled:   voiceEnabled   ?? this.voiceEnabled,
    isSpeaking:     isSpeaking     ?? this.isSpeaking,
    pendingActions: pendingActions ?? this.pendingActions,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class AssistantNotifier extends Notifier<AssistantState> {
  final _tts       = FlutterTts();
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  AssistantState build() {
    _initTts();
    return AssistantState(messages: [
      ChatMessage(
        id:        'welcome',
        text:      'Olá! 👋 Sou o assistente do Farmácia Fácil.\n\n'
                   'Conheço seus remédios, pedidos e posso te ajudar com '
                   'primeiros socorros, emergências e dicas de saúde.\n\n'
                   'Como posso te ajudar hoje?',
        role:      MessageRole.assistant,
        createdAt: DateTime.now(),
      ),
    ]);
  }

  // ── TTS ────────────────────────────────────────────────────────────────────
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() =>
          state = state.copyWith(isSpeaking: false));
    } catch (_) {}
  }

  void toggleVoice() {
    if (state.voiceEnabled) _tts.stop();
    state = state.copyWith(voiceEnabled: !state.voiceEnabled);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> _speak(String text) async {
    if (!state.voiceEnabled || kIsWeb) return;
    try {
      state = state.copyWith(isSpeaking: true);
      final clean = text
          .replaceAll(RegExp(r'\*\*|__|\*|_|`|#+'), '')
          .replaceAll(RegExp(r'\n+'), '. ');
      await _tts.speak(clean);
    } catch (_) {
      state = state.copyWith(isSpeaking: false);
    }
  }

  // ── Mensagem de sistema (câmera, etc.) ─────────────────────────────────────
  void sendImageMessage(String text) {
    final msg = ChatMessage(
      id:        's${DateTime.now().millisecondsSinceEpoch}',
      text:      text,
      role:      MessageRole.assistant,
      createdAt: DateTime.now(),
      isLoading: true,
    );
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  // ── Envia mensagem principal ────────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMsg = ChatMessage(
      id:        'u${DateTime.now().millisecondsSinceEpoch}',
      text:      text.trim(),
      role:      MessageRole.user,
      createdAt: DateTime.now(),
    );

    final loadingMsg = ChatMessage(
      id:        'loading',
      text:      '...',
      role:      MessageRole.assistant,
      createdAt: DateTime.now(),
      isLoading: true,
    );

    state = state.copyWith(
      messages:       [...state.messages, userMsg, loadingMsg],
      isLoading:      true,
      pendingActions: [],
    );

    try {
      final context = await _buildFullContext();
      final lower   = text.toLowerCase();
      final actions = _detectActions(lower, context);
      final response = await _callGemini(text.trim(), context);

      final updated = state.messages
          .where((m) => m.id != 'loading' && !m.isLoading)
          .toList();

      state = state.copyWith(
        messages: [...updated, ChatMessage(
          id:        'a${DateTime.now().millisecondsSinceEpoch}',
          text:      response,
          role:      MessageRole.assistant,
          createdAt: DateTime.now(),
        )],
        isLoading:      false,
        pendingActions: actions,
      );

      await _speak(response);

    } catch (_) {
      final updated = state.messages
          .where((m) => m.id != 'loading' && !m.isLoading)
          .toList();
      state = state.copyWith(
        messages: [...updated, ChatMessage(
          id:        'err${DateTime.now().millisecondsSinceEpoch}',
          text:      'Desculpe, não consegui responder agora. Verifique sua conexão.',
          role:      MessageRole.assistant,
          createdAt: DateTime.now(),
        )],
        isLoading:      false,
        pendingActions: [],
      );
    }
  }

  // ── Contexto completo do usuário ───────────────────────────────────────────
  Future<String> _buildFullContext() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Usuário não identificado.';

    final buffer = StringBuffer();

    // Remédios
    try {
      final snap = await _firestore
          .collection('users').doc(uid).collection('medications')
          .where('isActive', isEqualTo: true).get();

      if (snap.docs.isEmpty) {
        buffer.writeln('REMÉDIOS: Nenhum remédio cadastrado.');
      } else {
        buffer.writeln('REMÉDIOS CADASTRADOS:');
        for (final doc in snap.docs) {
          final m = MedicationModel.fromMap({'id': doc.id, ...doc.data()});
          buffer.writeln(
            '- ${m.name} (${m.dosage}): ${m.timesPerDay}x/dia '
            'nos horários ${m.times.join(", ")}. '
            'Estoque: ${m.remainingPills} comprimidos. '
            '${m.isRunningLow ? "⚠️ ESTOQUE BAIXO!" : "Estoque OK."}',
          );
        }
      }
    } catch (_) {}

    // Pedidos
    try {
      final snap = await _firestore
          .collection('orders').where('userId', isEqualTo: uid).get();

      if (snap.docs.isEmpty) {
        buffer.writeln('\nPEDIDOS: Nenhum pedido realizado.');
      } else {
        final sorted = snap.docs
          ..sort((a, b) {
            final aD = a.data()['createdAt'] as String? ?? '';
            final bD = b.data()['createdAt'] as String? ?? '';
            return bD.compareTo(aD);
          });
        buffer.writeln('\nPEDIDOS RECENTES:');
        for (final doc in sorted.take(3)) {
          final d = doc.data();
          buffer.writeln(
            '- Pedido na ${d['pharmacyName'] ?? 'farmácia'}: '
            'status "${d['status'] ?? ''}", '
            'total R\$ ${(d['totalPrice'] ?? 0).toStringAsFixed(2)}.',
          );
        }
      }
    } catch (_) {}

    // Farmácias
    try {
      final snap = await _firestore
          .collection('pharmacies').where('isApproved', isEqualTo: true).get();

      if (snap.docs.isEmpty) {
        buffer.writeln('\nFARMÁCIAS: Nenhuma disponível.');
      } else {
        buffer.writeln('\nFARMÁCIAS DISPONÍVEIS:');
        for (final doc in snap.docs) {
          final d = doc.data();
          buffer.writeln(
            '- ${d['name'] ?? ''} em ${d['city'] ?? ''} '
            '(${d['hasDelivery'] == true ? "faz entrega" : "só retirada"}).',
          );
        }
      }
    } catch (_) {}

    return buffer.toString();
  }

  // ── Detecta ações com base na mensagem ─────────────────────────────────────
  List<AssistantAction> _detectActions(String msg, String context) {
    final actions = <AssistantAction>[];

    // Emergência — sempre prioridade máxima
    if (_isEmergency(msg)) {
      actions.add(const AssistantAction(
        label: '🚨 Ligar SAMU (192)',
        route: '',
        icon:  '🚨',
        isCall: true,
        phone: '192',
      ));
      actions.add(const AssistantAction(
        label: 'Ver Primeiros Socorros',
        route: '/health-tips',
        icon:  '🏥',
      ));
      return actions; // em emergência só mostra essas ações
    }

    // Primeiros socorros
    if (_isFirstAid(msg)) {
      actions.add(const AssistantAction(
        label: 'Ver Primeiros Socorros',
        route: '/health-tips',
        icon:  '🏥',
      ));
      actions.add(const AssistantAction(
        label: '📞 SAMU (192)',
        route: '',
        icon:  '📞',
        isCall: true,
        phone: '192',
      ));
    }

    // Remédios
    if (msg.contains('remédio') || msg.contains('medicamento') ||
        msg.contains('tomar') || msg.contains('horário') ||
        msg.contains('dose') || msg.contains('comprimido')) {
      actions.add(const AssistantAction(
        label: 'Ver meus remédios',
        route: '/medications',
        icon:  '💊',
      ));
    }

    // Estoque baixo
    if (msg.contains('estoque') || msg.contains('acabando') ||
        msg.contains('repor') || msg.contains('comprar') ||
        context.contains('ESTOQUE BAIXO')) {
      actions.add(const AssistantAction(
        label: 'Buscar farmácias',
        route: '/pharmacies',
        icon:  '🏪',
      ));
    }

    // Pedidos
    if (msg.contains('pedido') || msg.contains('entrega') ||
        msg.contains('status') || msg.contains('encomenda')) {
      actions.add(const AssistantAction(
        label: 'Ver meus pedidos',
        route: '/orders',
        icon:  '📦',
      ));
    }

    // Receita
    if (msg.contains('receita') || msg.contains('foto') ||
        msg.contains('câmera') || msg.contains('fotografar')) {
      actions.add(const AssistantAction(
        label: 'Ler receita',
        route: '/prescription',
        icon:  '📄',
      ));
    }

    // Dicas / saúde
    if (msg.contains('dica') || msg.contains('saúde') ||
        msg.contains('bem-estar') || msg.contains('alimenta') ||
        msg.contains('exerc') || msg.contains('sono')) {
      actions.add(const AssistantAction(
        label: 'Ver dicas de saúde',
        route: '/health-tips',
        icon:  '💡',
      ));
    }

    // Farmácias
    if ((msg.contains('farmácia') || msg.contains('loja') ||
         msg.contains('perto') || msg.contains('próxima')) &&
        !actions.any((a) => a.route == '/pharmacies')) {
      actions.add(const AssistantAction(
        label: 'Ver farmácias',
        route: '/pharmacies',
        icon:  '🏪',
      ));
    }

    return actions;
  }

  // Detecta situação de emergência
  bool _isEmergency(String msg) =>
    msg.contains('parada') || msg.contains('infarto') ||
    msg.contains('avc') || msg.contains('derrame') ||
    msg.contains('desmaio') || msg.contains('inconsciente') ||
    msg.contains('não respira') || msg.contains('parou de respirar') ||
    msg.contains('overdose') || msg.contains('envenenamento') ||
    msg.contains('sangramento') || msg.contains('afogou') ||
    msg.contains('emergência') || msg.contains('socorro') ||
    msg.contains('acidente') || msg.contains('urgência');

  // Detecta necessidade de primeiros socorros
  bool _isFirstAid(String msg) =>
    msg.contains('queimad') || msg.contains('convulsão') ||
    msg.contains('epilep') || msg.contains('engasgou') ||
    msg.contains('engasgament') || msg.contains('heimlich') ||
    msg.contains('picada') || msg.contains('cobra') ||
    msg.contains('escorpião') || msg.contains('intoxica') ||
    msg.contains('hipotermia') || msg.contains('insolação') ||
    msg.contains('fratura') || msg.contains('osso quebrado') ||
    msg.contains('primeiros socorros');

  // ── Chama Gemini via Firebase AI Logic (sem chave de API) ─────────────────
  Future<String> _callGemini(String userMessage, String context) async {
    try {
      // Firebase AI Logic usa autenticação Firebase — sem chave AQ. ou AIza
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
      );

      final prompt = '''
Você é o assistente virtual do aplicativo Farmácia Fácil — um assistente de saúde pessoal completo.

SUAS CAPACIDADES:
1. Remédios: informa horários, dosagens, estoques e alertas
2. Pedidos: informa status e histórico de compras
3. Farmácias: informa as disponíveis na plataforma
4. Primeiros Socorros: orienta sobre queimaduras, convulsões, engasgamento, AVC, etc.
5. Emergências: indica o número correto para cada situação (SAMU 192, Bombeiros 193, etc.)
6. Dicas de saúde: alimentação, exercícios, sono, medicamentos, saúde mental
7. Receitas médicas: orienta sobre como usar o recurso de leitura de receita

DADOS ATUAIS DO USUÁRIO:
$context

REGRAS:
1. Responda SEMPRE em português do Brasil
2. Seja direto, claro e objetivo (máximo 3 parágrafos)
3. Use os dados reais do contexto acima
4. Em situações de emergência: indique IMEDIATAMENTE o número 192 (SAMU)
5. Para primeiros socorros: dê os passos de forma numerada e clara
6. Para dúvidas médicas: "Este assistente é informativo. Consulte seu médico."
7. Use emojis com moderação
8. Nunca invente dados que não estão no contexto

Pergunta do usuário: $userMessage
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? _localResponse(userMessage, context);

    } catch (e) {
      _log('Erro Firebase AI: $e');
      return _localResponse(userMessage, context);
    }
  }

  // ── Fallback local completo e refinado ─────────────────────────────────────
  String _localResponse(String message, String context) {
    final lower = message.toLowerCase();

    // ── EMERGÊNCIAS (prioridade máxima) ──
    if (_isEmergency(lower)) {
      return '🚨 EMERGÊNCIA DETECTADA!\n\n'
             'Ligue IMEDIATAMENTE para o SAMU: 192\n\n'
             'Enquanto aguarda o socorro:\n'
             '• Mantenha a pessoa consciente\n'
             '• Não mova se houver suspeita de fratura\n'
             '• Se parou de respirar: inicie RCP\n\n'
             'Toque em "Ligar SAMU" abaixo para chamar agora.';
    }

    // ── PRIMEIROS SOCORROS ──
    if (lower.contains('queimad')) {
      return '🔥 Para queimaduras:\n\n'
             '1. Resfrie com água corrente fria por 10-20 min\n'
             '2. Nunca use gelo, manteiga ou pasta de dente\n'
             '3. Cubra com pano limpo e úmido\n'
             '4. Não estoure bolhas\n\n'
             'Queimaduras extensas ou na face: ligue 192 (SAMU).\n\n'
             '⚕️ Este assistente é informativo. Busque atendimento médico.';
    }

    if (lower.contains('convulsão') || lower.contains('epilep')) {
      return '⚡ Para convulsão/epilepsia:\n\n'
             '1. Afaste objetos perigosos do redor\n'
             '2. Coloque algo macio embaixo da cabeça\n'
             '3. Vire a pessoa de lado\n'
             '4. NUNCA coloque nada na boca\n'
             '5. Cronometre a duração\n\n'
             'Ligue 192 se durar mais de 5 minutos ou for a primeira vez.\n\n'
             '⚕️ Consulte um neurologista após a crise.';
    }

    if (lower.contains('engasgou') || lower.contains('engasgament')) {
      return '😮 Para engasgamento:\n\n'
             '1. Pergunte: "Você está engasgado?"\n'
             '2. Se não conseguir falar: aplique a Manobra de Heimlich\n'
             '3. Posicione-se atrás da pessoa\n'
             '4. Faça um punho entre o umbigo e o peito\n'
             '5. Puxe com força para dentro e para cima\n'
             '6. Repita até o objeto sair\n\n'
             'Em bebês: 5 tapas nas costas + 5 pressões no tórax.\n\n'
             '⚕️ Se perder a consciência: inicie RCP e ligue 192.';
    }

    if (lower.contains('avc') || lower.contains('derrame')) {
      return '🧠 AVC — Use o método FAST:\n\n'
             '👁 F — Face: peça para sorrir. Um lado caiu?\n'
             '💪 A — Braços: levante os dois. Um caiu?\n'
             '🗣 S — Fala: repita uma frase. Está estranha?\n'
             '⏰ T — Tempo: SIM a qualquer um? LIGUE 192 AGORA!\n\n'
             'AVC é emergência — cada minuto causa dano cerebral permanente.\n\n'
             'Toque em "Ligar SAMU" abaixo imediatamente.';
    }

    if (lower.contains('picada') || lower.contains('cobra') ||
        lower.contains('escorpião')) {
      return '🐍 Para picadas de animais peçonhentos:\n\n'
             '1. Mantenha a calma e imobilize o membro\n'
             '2. NUNCA faça torniquete ou corte a picada\n'
             '3. NUNCA suce o veneno\n'
             '4. Remova relógios e anéis do membro\n'
             '5. Vá IMEDIATAMENTE ao pronto-socorro\n\n'
             'O soro só é eficaz nas primeiras horas!\n\n'
             '⚕️ Ligue 192 (SAMU) em casos graves.';
    }

    if (lower.contains('intoxica') || lower.contains('veneno') ||
        lower.contains('remédio demais') || lower.contains('overdose')) {
      return '☠️ Para intoxicação/envenenamento:\n\n'
             '1. NÃO provoque vômito\n'
             '2. Guarde a embalagem do produto\n'
             '3. Ligue: 0800 722 6001 (Centro de Intoxicações — 24h gratuito)\n'
             '4. Vá ao pronto-socorro levando a embalagem\n\n'
             'Toque em "Ligar SAMU" abaixo para emergências graves.';
    }

    // ── REMÉDIOS ──
    if (lower.contains('remédio') || lower.contains('tomar') ||
        lower.contains('horário') || lower.contains('dose') ||
        lower.contains('medicamento')) {
      if (context.contains('Nenhum remédio')) {
        return '💊 Você ainda não tem remédios cadastrados.\n\n'
               'Toque em "Ver meus remédios" para adicionar seus medicamentos '
               'e configurar os horários de uso.';
      }
      final lines = context.split('\n')
          .where((l) => l.startsWith('- ') && l.contains('horários'))
          .take(3).join('\n');
      return 'Seus remédios cadastrados:\n\n$lines\n\n'
             '⚕️ Sempre confirme dosagens com seu médico ou farmacêutico.';
    }

    // ── ESTOQUE ──
    if (lower.contains('estoque') || lower.contains('acabando') ||
        lower.contains('repor') || lower.contains('comprar')) {
      if (context.contains('ESTOQUE BAIXO')) {
        return '⚠️ Você tem remédios com estoque baixo!\n\n'
               'Toque em "Buscar farmácias" para fazer um pedido antes de acabar. '
               'Não interrompa seu tratamento sem orientação médica. 🏪';
      }
      return '✅ Seus estoques estão em ordem por enquanto.\n\n'
             'Monitoro conforme você registra as doses tomadas.';
    }

    // ── PEDIDOS ──
    if (lower.contains('pedido') || lower.contains('entrega') ||
        lower.contains('status') || lower.contains('encomenda')) {
      if (context.contains('Nenhum pedido')) {
        return '📦 Você ainda não fez nenhum pedido pelo app.\n\n'
               'Acesse "Farmácias", escolha uma, veja os produtos e toque em "Fazer pedido".';
      }
      final lines = context.split('\n')
          .where((l) => l.startsWith('- Pedido')).take(3).join('\n');
      return 'Seus pedidos recentes:\n\n$lines\n\n'
             'Toque em "Ver meus pedidos" para todos os detalhes.';
    }

    // ── FARMÁCIAS ──
    if (lower.contains('farmácia') || lower.contains('comprar remédio') ||
        lower.contains('perto') || lower.contains('próxima')) {
      if (context.contains('Nenhuma disponível')) {
        return '🏪 Ainda não há farmácias cadastradas na plataforma.\n\n'
               'Em breve mais farmácias estarão disponíveis!';
      }
      final lines = context.split('\n')
          .where((l) => l.startsWith('- ') && (l.contains('entrega') || l.contains('retirada')))
          .take(3).join('\n');
      return 'Farmácias disponíveis:\n\n$lines\n\n'
             'Toque em "Ver farmácias" para ver produtos e fazer pedidos.';
    }

    // ── RECEITA ──
    if (lower.contains('receita') || lower.contains('câmera') ||
        lower.contains('fotografar') || lower.contains('foto')) {
      return '📄 Para ler uma receita médica:\n\n'
             '1. Toque no ícone 📷 ao lado do campo de texto\n'
             '2. Escolha câmera ou galeria\n'
             '3. O app lê o texto automaticamente\n'
             '4. Confirme os medicamentos identificados\n'
             '5. Busque nas farmácias com um toque!\n\n'
             '⚕️ Sempre confirme os medicamentos com seu médico.';
    }

    // ── DICAS DE SAÚDE ──
    if (lower.contains('dica') || lower.contains('saúde') ||
        lower.contains('bem-estar') || lower.contains('alimenta') ||
        lower.contains('exerc') || lower.contains('sono')) {
      return '💡 Dica do dia:\n\n'
             'Tome seus medicamentos sempre no mesmo horário — '
             'isso mantém o nível correto no sangue.\n\n'
             'Beba bastante água, durma bem e movimente-se diariamente.\n\n'
             'Toque em "Ver dicas" para mais conteúdos sobre saúde e '
             'orientações de primeiros socorros!\n\n'
             '⚕️ Este assistente é informativo e não substitui orientação médica.';
    }

    // ── EMERGÊNCIAS (número específico) ──
    if (lower.contains('samu') || lower.contains('192')) {
      return '🚑 SAMU — Serviço de Atendimento Médico de Urgência\n\n'
             'Número: 192\n'
             'Disponível 24 horas, 7 dias por semana.\n'
             'Gratuito de qualquer telefone.\n\n'
             'Toque em "Ligar SAMU" abaixo para chamar agora.';
    }

    if (lower.contains('bombeiro') || lower.contains('193')) {
      return '🚒 Corpo de Bombeiros\n\n'
             'Número: 193\n'
             'Para incêndios, resgates e acidentes.\n'
             'Disponível 24 horas, gratuito.';
    }

    if (lower.contains('cvv') || lower.contains('suicid') ||
        lower.contains('188')) {
      return '💙 CVV — Centro de Valorização da Vida\n\n'
             'Número: 188\n'
             'Apoio emocional e prevenção do suicídio.\n'
             'Disponível 24 horas, gratuito e sigiloso.\n\n'
             'Você não está sozinho. Ajuda está disponível.';
    }

    // ── SAUDAÇÃO ──
    if (lower.contains('olá') || lower.contains('oi') ||
        lower.contains('bom dia') || lower.contains('boa tarde') ||
        lower.contains('boa noite')) {
      return 'Olá! 😊 Estou aqui para te ajudar.\n\n'
             'Posso te ajudar com:\n'
             '💊 Remédios e horários\n'
             '📦 Status de pedidos\n'
             '🏪 Farmácias\n'
             '📄 Leitura de receitas\n'
             '🏥 Primeiros socorros\n'
             '🚨 Números de emergência\n'
             '💡 Dicas de saúde\n\n'
             'O que você precisa?';
    }

    // ── RESPOSTA PADRÃO ──
    return 'Entendi! Posso te ajudar com:\n\n'
           '💊 Seus remédios e horários\n'
           '📦 Status dos seus pedidos\n'
           '🏪 Farmácias disponíveis\n'
           '📄 Leitura de receitas\n'
           '🏥 Primeiros socorros\n'
           '🚨 Emergências (SAMU, Bombeiros...)\n'
           '💡 Dicas de saúde\n\n'
           'Pergunte algo específico para eu te ajudar melhor!';
  }
}

final assistantProvider = NotifierProvider<AssistantNotifier, AssistantState>(
  AssistantNotifier.new,
);
