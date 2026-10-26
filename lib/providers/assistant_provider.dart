import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../models/medication_model.dart';

const _geminiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

// ─── Ação navegável que o assistente pode sugerir ─────────────────────────────
class AssistantAction {
  final String label;
  final String route;
  final String icon;

  const AssistantAction({
    required this.label,
    required this.route,
    required this.icon,
  });
}

// ─── Estado ───────────────────────────────────────────────────────────────────
class AssistantState {
  final List<ChatMessage>    messages;
  final bool                 isLoading;
  final bool                 voiceEnabled;
  final bool                 isSpeaking;
  final List<AssistantAction> pendingActions; // botões de ação na última mensagem

  const AssistantState({
    this.messages       = const [],
    this.isLoading      = false,
    this.voiceEnabled   = true,
    this.isSpeaking     = false,
    this.pendingActions = const [],
  });

  AssistantState copyWith({
    List<ChatMessage>?    messages,
    bool?                 isLoading,
    bool?                 voiceEnabled,
    bool?                 isSpeaking,
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
                   'Conheço seus remédios, pedidos e posso te guiar pelo app. '
                   'Pergunte o que precisar!',
        role:      MessageRole.assistant,
        createdAt: DateTime.now(),
      ),
    ]);
  }

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

  // ── Envia mensagem ─────────────────────────────────────────────────────────
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
      // Busca TODOS os contextos do usuário
      final context = await _buildFullContext();

      // Detecta intenção para gerar ações navegáveis
      final actions = _detectActions(text.toLowerCase(), context);

      // Chama a IA
      final response = await _callGemini(text.trim(), context);

      final updated = state.messages.where((m) => m.id != 'loading').toList();
      final assistantMsg = ChatMessage(
        id:        'a${DateTime.now().millisecondsSinceEpoch}',
        text:      response,
        role:      MessageRole.assistant,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages:       [...updated, assistantMsg],
        isLoading:      false,
        pendingActions: actions,
      );

      await _speak(response);

    } catch (e) {
      final updated = state.messages.where((m) => m.id != 'loading').toList();
      state = state.copyWith(
        messages: [...updated, ChatMessage(
          id:        'err${DateTime.now().millisecondsSinceEpoch}',
          text:      'Desculpe, não consegui responder agora. Verifique sua conexão.',
          role:      MessageRole.assistant,
          createdAt: DateTime.now(),
        )],
        isLoading: false,
        pendingActions: [],
      );
    }
  }

  // ── Contexto completo do usuário ───────────────────────────────────────────
  Future<String> _buildFullContext() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Usuário não identificado.';

    final buffer = StringBuffer();

    // 1. Remédios
    try {
      final medsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('medications')
          .where('isActive', isEqualTo: true)
          .get();

      if (medsSnap.docs.isEmpty) {
        buffer.writeln('REMÉDIOS: Nenhum remédio cadastrado.');
      } else {
        buffer.writeln('REMÉDIOS CADASTRADOS:');
        for (final doc in medsSnap.docs) {
          final m = MedicationModel.fromMap({'id': doc.id, ...doc.data()});
          buffer.writeln(
            '- ${m.name} (${m.dosage}): ${m.timesPerDay}x/dia '
            'nos horários ${m.times.join(', ')}. '
            'Estoque: ${m.remainingPills} comprimidos. '
            '${m.isRunningLow ? "⚠️ ESTOQUE BAIXO!" : "Estoque OK."}',
          );
        }
      }
    } catch (_) {}

    // 2. Pedidos recentes
    try {
      final ordersSnap = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .get();

      final orders = ordersSnap.docs;
      if (orders.isEmpty) {
        buffer.writeln('\nPEDIDOS: Nenhum pedido realizado ainda.');
      } else {
        // Ordena por data (mais recente primeiro)
        orders.sort((a, b) {
          final aDate = a.data()['createdAt'] as String? ?? '';
          final bDate = b.data()['createdAt'] as String? ?? '';
          return bDate.compareTo(aDate);
        });
        buffer.writeln('\nPEDIDOS RECENTES (últimos 3):');
        for (final doc in orders.take(3)) {
          final d = doc.data();
          buffer.writeln(
            '- Pedido na ${d['pharmacyName'] ?? 'farmácia'}: '
            'status "${d['status'] ?? 'desconhecido'}", '
            'total R\$ ${(d['totalPrice'] ?? 0).toStringAsFixed(2)}.',
          );
        }
      }
    } catch (_) {}

    // 3. Farmácias disponíveis
    try {
      final pharmSnap = await _firestore
          .collection('pharmacies')
          .where('isApproved', isEqualTo: true)
          .get();

      if (pharmSnap.docs.isEmpty) {
        buffer.writeln('\nFARMÁCIAS: Nenhuma farmácia disponível no momento.');
      } else {
        buffer.writeln('\nFARMÁCIAS DISPONÍVEIS:');
        for (final doc in pharmSnap.docs) {
          final d = doc.data();
          buffer.writeln(
            '- ${d['name'] ?? 'Farmácia'} em ${d['city'] ?? ''} '
            '(${d['hasDelivery'] == true ? "faz entrega" : "só retirada"}).',
          );
        }
      }
    } catch (_) {}

    return buffer.toString();
  }

  // ── Detecta ações navegáveis com base na mensagem ─────────────────────────
  List<AssistantAction> _detectActions(String msg, String context) {
    final actions = <AssistantAction>[];

    if (msg.contains('remédio') || msg.contains('medicamento') ||
        msg.contains('tomar') || msg.contains('horário') ||
        msg.contains('dose')) {
      actions.add(const AssistantAction(
        label: 'Ver meus remédios',
        route: '/medications',
        icon:  '💊',
      ));
    }

    if (msg.contains('estoque') || msg.contains('acabando') ||
        msg.contains('comprar') || msg.contains('repor') ||
        context.contains('ESTOQUE BAIXO')) {
      actions.add(const AssistantAction(
        label: 'Buscar farmácias',
        route: '/pharmacies',
        icon:  '🏪',
      ));
    }

    if (msg.contains('pedido') || msg.contains('entrega') ||
        msg.contains('status') || msg.contains('compra')) {
      actions.add(const AssistantAction(
        label: 'Ver meus pedidos',
        route: '/orders',
        icon:  '📦',
      ));
    }

    if (msg.contains('receita') || msg.contains('foto') ||
        msg.contains('fotografar') || msg.contains('câmera')) {
      actions.add(const AssistantAction(
        label: 'Ler receita',
        route: '/prescription',
        icon:  '📄',
      ));
    }

    if (msg.contains('dica') || msg.contains('saúde') ||
        msg.contains('bem-estar') || msg.contains('cuidado')) {
      actions.add(const AssistantAction(
        label: 'Ver dicas de saúde',
        route: '/health-tips',
        icon:  '💡',
      ));
    }

    if (msg.contains('farmácia') || msg.contains('loja') ||
        msg.contains('perto')) {
      if (!actions.any((a) => a.route == '/pharmacies')) {
        actions.add(const AssistantAction(
          label: 'Ver farmácias',
          route: '/pharmacies',
          icon:  '🏪',
        ));
      }
    }

    return actions;
  }

  // ── Chama o Gemini ─────────────────────────────────────────────────────────
  Future<String> _callGemini(String userMessage, String context) async {
    if (_geminiKey.isEmpty) return _localResponse(userMessage, context);

    final systemPrompt = '''
Você é o assistente virtual do aplicativo Farmácia Fácil.
Você tem acesso completo aos dados do usuário e ajuda com:
- Remédios cadastrados, horários e estoques
- Status de pedidos realizados
- Farmácias disponíveis
- Dicas de saúde e bem-estar
- Orientações sobre como usar o app

DADOS ATUAIS DO USUÁRIO:
$context

REGRAS:
1. Sempre responda em português do Brasil
2. Seja simpático, direto e objetivo (máximo 3 parágrafos curtos)
3. Use os dados reais do contexto acima nas respostas
4. Para dúvidas médicas específicas: "Este assistente é informativo e não substitui orientação médica."
5. Quando mencionar uma funcionalidade do app, explique como acessá-la
6. Use emojis com moderação para tornar a resposta mais amigável
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type':   'application/json',
        'x-goog-api-key': _geminiKey,
      },
      body: jsonEncode({
        'system_instruction': {'parts': [{'text': systemPrompt}]},
        'contents': [
          {'role': 'user', 'parts': [{'text': userMessage}]}
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 512},
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String? ?? _localResponse(userMessage, context);
    }

    return _localResponse(userMessage, context);
  }

  // ── Fallback local inteligente ─────────────────────────────────────────────
  String _localResponse(String message, String context) {
    final lower = message.toLowerCase();

    // Remédios / horários
    if (lower.contains('remédio') || lower.contains('tomar') ||
        lower.contains('horário') || lower.contains('dose')) {
      if (context.contains('Nenhum remédio')) {
        return 'Você ainda não tem remédios cadastrados. '
               'Toque em "Ver meus remédios" abaixo para adicionar o primeiro! 💊';
      }
      final lines = context.split('\n')
          .where((l) => l.startsWith('- ') && l.contains('horários'))
          .take(3).join('\n');
      return 'Seus remédios cadastrados:\n\n$lines\n\n'
             '⚕️ Sempre confirme com seu médico ou farmacêutico.';
    }

    // Estoque / repor
    if (lower.contains('estoque') || lower.contains('acabando') ||
        lower.contains('repor') || lower.contains('comprar')) {
      if (context.contains('ESTOQUE BAIXO')) {
        return '⚠️ Atenção! Você tem remédios com estoque baixo.\n\n'
               'Toque em "Buscar farmácias" para fazer um novo pedido rapidamente. '
               'Não interrompa seu tratamento! 🏪';
      }
      return '✅ Seus estoques estão ok por enquanto. '
             'Continuo monitorando conforme você registrar as doses.';
    }

    // Pedidos
    if (lower.contains('pedido') || lower.contains('entrega') ||
        lower.contains('status')) {
      if (context.contains('Nenhum pedido')) {
        return 'Você ainda não fez nenhum pedido pelo app. '
               'Acesse "Farmácias", escolha uma e toque em "Fazer pedido". 📦';
      }
      final lines = context.split('\n')
          .where((l) => l.startsWith('- Pedido')).take(3).join('\n');
      return 'Seus pedidos recentes:\n\n$lines\n\n'
             'Toque em "Ver meus pedidos" para ver todos os detalhes.';
    }

    // Farmácias
    if (lower.contains('farmácia') || lower.contains('loja') ||
        lower.contains('perto')) {
      if (context.contains('Nenhuma farmácia')) {
        return 'Ainda não há farmácias cadastradas e aprovadas na plataforma. '
               'Em breve mais farmácias estarão disponíveis! 🏪';
      }
      final lines = context.split('\n')
          .where((l) => l.startsWith('- ') && l.contains('entrega'))
          .take(3).join('\n');
      return 'Farmácias disponíveis na plataforma:\n\n$lines\n\n'
             'Toque em "Ver farmácias" para ver produtos e fazer pedidos.';
    }

    // Receita
    if (lower.contains('receita') || lower.contains('foto') ||
        lower.contains('câmera')) {
      return '📄 Para ler uma receita médica:\n\n'
             '1. Toque em "Ler receita" abaixo\n'
             '2. Fotografe ou selecione a imagem da receita\n'
             '3. O app identifica os medicamentos automaticamente\n'
             '4. Confirme e busque nas farmácias!\n\n'
             '⚕️ Sempre confirme os medicamentos com seu médico.';
    }

    // Dicas de saúde
    if (lower.contains('dica') || lower.contains('saúde') ||
        lower.contains('bem-estar')) {
      return '💡 Dica do dia:\n\n'
             'Tome seus medicamentos sempre no mesmo horário — isso ajuda o '
             'corpo a manter o nível correto do remédio no sangue.\n\n'
             'Beba bastante água, durma bem e movimente-se diariamente. '
             'Toque em "Ver dicas" para mais conteúdos de saúde!\n\n'
             '⚕️ Este assistente é informativo e não substitui orientação médica.';
    }

    // Saudação
    if (lower.contains('olá') || lower.contains('oi') ||
        lower.contains('bom') || lower.contains('boa')) {
      return 'Olá! 😊 Estou aqui para te ajudar.\n\n'
             'Posso te informar sobre seus remédios, horários, '
             'status de pedidos, farmácias disponíveis e muito mais.\n\n'
             'O que você quer saber hoje?';
    }

    return 'Entendi! Posso te ajudar com:\n\n'
           '💊 Seus remédios e horários\n'
           '📦 Status dos seus pedidos\n'
           '🏪 Farmácias disponíveis\n'
           '📄 Leitura de receitas\n'
           '💡 Dicas de saúde\n\n'
           'O que você precisa?';
  }
}

final assistantProvider = NotifierProvider<AssistantNotifier, AssistantState>(
  AssistantNotifier.new,
);
