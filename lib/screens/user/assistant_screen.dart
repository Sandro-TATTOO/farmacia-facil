import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../providers/assistant_provider.dart';
import '../../models/chat_message_model.dart';
import '../../app/theme.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _focusNode   = FocusNode();
  final _picker      = ImagePicker();
  bool  _scanningPrescription = false;

  // Sugestões rápidas de perguntas
  static const _suggestions = [
    'Quais remédios devo tomar hoje?',
    'Algum remédio está acabando?',
    'Quais são meus horários de medicação?',
    'Me dê uma dica de saúde',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    ref.read(assistantProvider.notifier).stopSpeaking();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _focusNode.unfocus();
    ref.read(assistantProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Abre câmera/galeria, lê a receita e envia para o assistente
  Future<void> _scanPrescription(ImageSource source) async {
    if (kIsWeb) {
      ref.read(assistantProvider.notifier).sendMessage(
        'Como funciona a leitura de receita no app?',
      );
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source:       source,
        maxWidth:     1200,
        imageQuality: 90,
      );
      if (picked == null) return;

      setState(() => _scanningPrescription = true);

      // Envia mensagem de contexto para o chat
      ref.read(assistantProvider.notifier).sendImageMessage(
        '📷 Analisando receita médica...',
      );

      // OCR com ML Kit
      final inputImage  = InputImage.fromFilePath(picked.path);
      final recognizer  = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized  = await recognizer.processImage(inputImage);
      await recognizer.close();

      final text = recognized.text.trim();

      if (text.isEmpty) {
        ref.read(assistantProvider.notifier).sendMessage(
          'Fotografei uma receita mas o texto não ficou legível. '
          'Pode tentar novamente com mais luz?',
        );
      } else {
        // Envia o texto para o assistente analisar
        ref.read(assistantProvider.notifier).sendMessage(
          'Acabei de fotografar uma receita médica. '
          'Aqui está o texto lido:\n\n$text\n\n'
          'Quais medicamentos você consegue identificar nessa receita? '
          'Me ajude a confirmar e sugira onde comprar.',
        );
      }

      _scrollToBottom();
    } catch (e) {
      ref.read(assistantProvider.notifier).sendMessage(
        'Tive um problema ao acessar a câmera. Tente novamente.',
      );
    } finally {
      setState(() => _scanningPrescription = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ler receita médica',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Escolha como enviar a receita',
                style: TextStyle(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: AppTheme.primaryGreen),
                ),
                title: const Text('Tirar foto agora'),
                subtitle: const Text('Abre a câmera do celular'),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanPrescription(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Escolher da galeria'),
                subtitle: const Text('Seleciona uma foto existente'),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanPrescription(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantProvider);

    // Auto-scroll quando nova mensagem chega
    ref.listen(assistantProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistente',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Online',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          // Botão de voz
          if (!kIsWeb)
            IconButton(
              onPressed: () =>
                  ref.read(assistantProvider.notifier).toggleVoice(),
              icon: Icon(
                state.voiceEnabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                color: Colors.white,
              ),
              tooltip: state.voiceEnabled
                  ? 'Desativar voz'
                  : 'Ativar voz',
            ),
          // Indicador de fala ativa
          if (state.isSpeaking)
            IconButton(
              onPressed: () =>
                  ref.read(assistantProvider.notifier).stopSpeaking(),
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
              tooltip: 'Parar narração',
            ),
        ],
      ),
      body: Column(
        children: [
          // Aviso médico
          Container(
            color: Colors.blue.shade50,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blue),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Assistente informativo. Não substitui orientação médica.',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),

          // Lista de mensagens
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: state.messages.length +
                  (state.messages.length == 1 ? 1 : 0) +
                  (state.pendingActions.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // Sugestões após boas-vindas
                if (state.messages.length == 1 && index == 1) {
                  return _SuggestionsWidget(
                    suggestions: _suggestions,
                    onTap: (s) =>
                        ref.read(assistantProvider.notifier).sendMessage(s),
                  );
                }
                // Botões de ação navegável
                final actionsIndex = state.messages.length +
                    (state.messages.length == 1 ? 1 : 0);
                if (state.pendingActions.isNotEmpty && index == actionsIndex) {
                  return _ActionsWidget(
                    actions: state.pendingActions,
                    onTap: (route) => context.go(route),
                  );
                }
                return _MessageBubble(message: state.messages[index]);
              },
            ),
          ),

          // Campo de digitação
          _InputBar(
            controller: _controller,
            focusNode: _focusNode,
            isLoading: state.isLoading || _scanningPrescription,
            onSend: _send,
            onCamera: _showImageSourceDialog,
          ),
        ],
      ),
    );
  }
}

// ─── Bolha de mensagem ────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar do assistente
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.smart_toy,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],

          // Bolha
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryGreen
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isLoading
                  ? const _TypingIndicator()
                  : Text(
                      message.text,
                      style: TextStyle(
                        color:
                            isUser ? Colors.white : AppTheme.textDark,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
            ),
          ),

          // Avatar do usuário
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  AppTheme.primaryGreen.withValues(alpha: 0.15),
              child: const Icon(Icons.person,
                  color: AppTheme.primaryGreen, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Animação de "digitando..." ───────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(), SizedBox(width: 4),
            _Dot(), SizedBox(width: 4),
            _Dot(),
          ],
        ),
      );
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.textGrey,
          shape: BoxShape.circle,
        ),
      );
}

// ─── Botões de ação navegável ────────────────────────────────────────────────
class _ActionsWidget extends StatelessWidget {
  final List<AssistantAction>  actions;
  final void Function(String)  onTap;

  const _ActionsWidget({required this.actions, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 40),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions.map((a) => ElevatedButton.icon(
            onPressed: () => onTap(a.route),
            icon: Text(a.icon, style: const TextStyle(fontSize: 14)),
            label: Text(a.label, style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          )).toList(),
        ),
      );
}

// ─── Sugestões rápidas ────────────────────────────────────────────────────────
class _SuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;

  const _SuggestionsWidget(
      {required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sugestões:',
                style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .map((s) => GestureDetector(
                        onTap: () => onTap(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primaryGreen
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 12),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
}

// ─── Barra de input ───────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode            focusNode;
  final bool                 isLoading;
  final VoidCallback         onSend;
  final VoidCallback         onCamera;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Botão câmera
            if (!kIsWeb)
              IconButton(
                onPressed: isLoading ? null : onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                color: AppTheme.primaryGreen,
                tooltip: 'Ler receita',
              ),
            // Campo de texto
            Expanded(
              child: TextField(
                controller: controller,
                focusNode:  focusNode,
                maxLines:   null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:    'Digite ou use a câmera...',
                  filled:      true,
                  fillColor:   Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            // Botão enviar
            isLoading
                ? Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  )
                : Material(
                    color:        AppTheme.primaryGreen,
                    shape:        const CircleBorder(),
                    child: InkWell(
                      onTap:        onSend,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.send, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
          ],
        ),
      );
}
