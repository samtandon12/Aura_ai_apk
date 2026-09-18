enum MessageSender { user, assistant }

enum MessageStatus { complete, generating, error }

class ChatMessage {
  final String id;
  final String sessionId;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final String? modelId;
  final String? attachmentName;
  final String? attachmentPath;
  final MessageStatus status;
  final String? errorMessage;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.modelId,
    this.attachmentName,
    this.attachmentPath,
    this.status = MessageStatus.complete,
    this.errorMessage,
  });

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    MessageSender? sender,
    String? content,
    DateTime? timestamp,
    String? modelId,
    String? attachmentName,
    String? attachmentPath,
    MessageStatus? status,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      modelId: modelId ?? this.modelId,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
