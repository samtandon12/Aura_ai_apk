import 'chat_message.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final List<ChatMessage> messages;
  final String modelId;
  final bool isPinned;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.messages,
    required this.modelId,
    this.isPinned = false,
  });

  String get snippet {
    if (messages.isEmpty) return 'No messages yet';
    return messages.last.content;
  }

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    List<ChatMessage>? messages,
    String? modelId,
    bool? isPinned,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      messages: messages ?? this.messages,
      modelId: modelId ?? this.modelId,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
