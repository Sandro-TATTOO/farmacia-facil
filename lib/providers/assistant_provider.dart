import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../models/medication_model.dart';

// Chave Gemini via variável de ambiente (injetada no build)
const _geminiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

// ─── Estado do assistente ────────────────────────────────────────────────────
class AssistantState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool voiceEnabled;
  final bool isSpeaking;

  const AssistantState({
    this.messages    = const [],
    this.isLoading   = false,
    this.voiceEnabled = true,
    this.isSpeaking  = false,
  });

  AssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? voiceEnabled,
    bool? isSpeaking,
  }) => AssistantState(
    messages:     messages     ?? this.messages,
    isLoading:    isLoading    ?? this.isLoading,
    voiceEnabled: voiceEnabled ?? this.voiceEnabled,
    isSpeaking:   isSpeaking   ?? this.isSpeaking,
  );
}

// ─── Notifier ────────────────────────────────────────────────────────────────
class AssistantNotifier extends Notifier<AssistantState> {
  final _tts       = FlutterTts();
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  AssistantState build() {
    _initTts();
    final welcome = ChatMessage(
      id:        'welcome',
      text:      'Olá! Sou o assistente do Farmácia Fácil. Posso te ajudar com informações sobre seus remédios, horários de medicação e dicas de saúde. Como posso te ajudar hoje?',
      role:      MessageRole.assistant,
      createdAt: DateTime.now(),
    );
    return AssistantState(messages: [welcome]);
  }

  // Inicializa o Text-to-Speech em português
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        state = state.copyWith(isSpeaking: false);
      });
    } catch (_) {}
  }

  // Liga/desliga a narração por voz
  void toggleVoice() {
    if (state.voiceEnabled) {
      _tts.stop();
    }
    state = state.copyWith(voiceEnabled: !state.voiceEnabled);
  }

  // Para a narração
  Future<void> stopSpeaking() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  // Narra um texto
  Future<void> _speak(String text) async {
    if (!state.voiceEnabled || kIsWeb) return;
    try {
      state = state.copyWith(isSpeaking: true);
      // Remove markdown antes de narrar
      final clean = text
          .replaceAll(RegExp(r'\*\*|__|\*|_|`|#'), '')
          .replaceAll(RegExp(r'\n+'), '. ');
      await _tts.speak(clean);
    } catch (_) {
      state = state.copyWith(isSpeaking: false);
    }
  }

  // Envia mensagem do usuário e obtém resposta da IA
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMsg = ChatMessage(
      id:        'u${DateTime.now().millisecondsSinceEpoch}',
      text:      text.trim(),
      role:      MessageRole.user,
      createdAt: DateTime.now(),
    );

    // Mensagem de loading enquanto IA responde
    final loadingMsg = ChatMessage(
      id:        'loading',
      text:      '...',
      role:      MessageRole.assistant,
      createdAt: DateTime.now(),
      isLoading: true,
    );

    state = state.copyWith(
      messages:  [...state.messages, userMsg, loadingMsg],
      isLoading: true,
    );

    try {
      // Busca contexto dos remédios do usuário
      final context = await _buildContext();

      // Chama a IA
      final response = await _callGemini(text.trim(), context);

      // Remove loading e adiciona resposta real
      final updatedMessages = state.messages
          .where((m) => m.id != 'loading')
          .toList();

      final assistantMsg = ChatMessage(
        id:        'a${DateTime.now().millisecondsSinceEpoch}',
        text:      response,
        role:      MessageRole.assistant,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages:  [...updatedMessages, assistantMsg],
        isLoading: false,
      );

      // Narra a resposta
      await _speak(response);

    } catch (e) {
      final updatedMessages = state.messages
          .where((m) => m.id != 'loading')
          .toList();

      final errorMsg = ChatMessage(
        id:        'err${DateTime.now().millisecondsSinceEpoch}',
        text:      'Desculpe, não consegui responder agora. Verifique sua conexão e tente novamente.',
        role:      MessageRole.assistant,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages:  [...updatedMessages, errorMsg],
        isLoading: false,
      );
    }
  }

  // Monta o contexto com os remédios do usuário logado
  Future<String> _buildContext() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return '';

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('medications')
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'O usuário não tem remédios cadastrados no momento.';
      }

      final meds = snapshot.docs.map((doc) {
        final m = MedicationModel.fromMap({'id': doc.id, ...doc.data()});
        return '- ${m.name} (${m.dosage}): ${m.timesPerDay}x por dia '
               'nos horários ${m.times.join(', ')}. '
               'Estoque: ${m.remainingPills} comprimidos restantes. '
               '${m.isRunningLow ? "⚠️ ESTOQUE BAIXO!" : ""}';
      }).join('\n');

      return 'Remédios cadastrados do usuário:\n$meds';
    } catch (_) {
      return '';
    }
  }

  // Chama a API do Gemini com o contexto
  Future<String> _callGemini(String userMessage, String context) async {
    // Se não tiver chave, usa resposta local inteligente
    if (_geminiKey.isEmpty) {
      return _localResponse(userMessage, context);
    }

    final systemPrompt = '''
Você é o assistente virtual do aplicativo Farmácia Fácil, um assistente de saúde pessoal.
Você ajuda o usuário com:
- Informações sobre seus remédios cadastrados
- Horários de medicação
- Alertas de estoque baixo
- Dicas simples de saúde e bem-estar
- Dúvidas gerais sobre medicamentos

CONTEXTO ATUAL DO USUÁRIO:
$context

REGRAS IMPORTANTES:
1. Sempre responda em português do Brasil
2. Seja simpático, claro e objetivo
3. Para perguntas sobre saúde específica, SEMPRE inclua: "Este assistente é apenas informativo e não substitui orientação médica. Consulte seu médico ou farmacêutico."
4. Respostas curtas e diretas (máximo 3 parágrafos)
5. Não invente informações sobre remédios que não estão no contexto
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    );

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': systemPrompt}]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': userMessage}]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 512,
      }
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type':   'application/json',
        'x-goog-api-key': _geminiKey,
      },
      body: body,
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String? ?? _localResponse(userMessage, context);
    }

    return _localResponse(userMessage, context);
  }

  // Resposta local quando não há chave da API (fallback inteligente)
  String _localResponse(String message, String context) {
    final lower = message.toLowerCase();

    if (lower.contains('remédio') || lower.contains('medicamento') ||
        lower.contains('tomar') || lower.contains('horário')) {
      if (context.isEmpty || context.contains('não tem remédios')) {
        return 'Você ainda não tem remédios cadastrados. '
               'Vá até a aba "Remédios" para adicionar seus medicamentos e configurar os horários.';
      }
      return 'Com base nos seus remédios cadastrados:\n\n$context\n\n'
             '⚕️ Este assistente é apenas informativo e não substitui orientação médica.';
    }

    if (lower.contains('estoque') || lower.contains('acabando') ||
        lower.contains('comprar') || lower.contains('repor')) {
      if (context.contains('ESTOQUE BAIXO')) {
        return '⚠️ Atenção! Você tem remédios com estoque baixo. '
               'Acesse a aba "Farmácias" para fazer um novo pedido rapidamente.\n\n'
               '⚕️ Nunca interrompa um tratamento sem orientação médica.';
      }
      return 'Seus estoques estão em ordem por enquanto. '
             'Monitoro sempre que você registrar as doses tomadas.';
    }

    if (lower.contains('dica') || lower.contains('saúde') ||
        lower.contains('bem-estar')) {
      return '💡 Dica de saúde: Tome seus medicamentos sempre nos horários prescritos. '
             'Mantenha uma alimentação equilibrada, beba bastante água e pratique atividade física regular.\n\n'
             '⚕️ Este assistente é apenas informativo e não substitui orientação médica. '
             'Consulte seu médico ou farmacêutico para orientações específicas.';
    }

    if (lower.contains('olá') || lower.contains('oi') ||
        lower.contains('bom dia') || lower.contains('boa')) {
      return 'Olá! Tudo bem? Posso te ajudar com informações sobre seus remédios, '
             'horários de medicação, alertas de estoque e dicas de saúde. '
             'O que você precisa saber hoje?';
    }

    return 'Entendi sua pergunta. Posso te ajudar com:\n\n'
           '💊 Informações sobre seus remédios\n'
           '⏰ Horários de medicação\n'
           '📦 Alertas de estoque\n'
           '💡 Dicas de saúde\n\n'
           'Tente perguntar algo como: "Quais remédios devo tomar hoje?" '
           'ou "Algum remédio está acabando?"\n\n'
           '⚕️ Este assistente é apenas informativo e não substitui orientação médica.';
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────
final assistantProvider = NotifierProvider<AssistantNotifier, AssistantState>(
  AssistantNotifier.new,
);
