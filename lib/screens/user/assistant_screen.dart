import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            isLoading: state.isLoading,
            onSend: _send,
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

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(
          left: 16,
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
            Expanded(
              child: TextField(
                controller: controller,
                focusNode:  focusNode,
                maxLines:   null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:    'Digite sua pergunta...',
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    )
                  : Material(
                      color: AppTheme.primaryGreen,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap:         onSend,
                        customBorder:  const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.send,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
}
