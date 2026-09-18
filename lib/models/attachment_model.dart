class AIAttachment {
  final String id;
  final String messageId;
  final String chatId;
  final String fileName;
  final String? mimeType;
  final String localPath;
  final int size;
  final DateTime createdAt;

  const AIAttachment({
    required this.id,
    required this.messageId,
    required this.chatId,
    required this.fileName,
    this.mimeType,
    required this.localPath,
    required this.size,
    required this.createdAt,
  });

  AIAttachment copyWith({
    String? id,
    String? messageId,
    String? chatId,
    String? fileName,
    String? mimeType,
    String? localPath,
    int? size,
    DateTime? createdAt,
  }) {
    return AIAttachment(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
