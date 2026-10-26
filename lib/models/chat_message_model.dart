enum MessageRole { user, assistant }

class ChatMessage {
  final String      id;
  final String      text;
  final MessageRole role;
  final DateTime    createdAt;
  final bool        isLoading; // true enquanto IA está gerando resposta

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.createdAt,
    this.isLoading = false,
  });

  bool get isUser      => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  ChatMessage copyWith({String? text, bool? isLoading}) => ChatMessage(
    id:        id,
    text:      text      ?? this.text,
    role:      role,
    createdAt: createdAt,
    isLoading: isLoading ?? this.isLoading,
  );
}
