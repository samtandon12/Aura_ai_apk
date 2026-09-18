import 'package:drift/drift.dart';

import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../database/app_database.dart';

class ChatRepository {
  final AppDatabase db;

  ChatRepository(this.db);

  // Map Drift DB Chat + Messages -> Domain ChatSession
  ChatSession _mapToSession(
    Chat chatRow,
    List<Message> messageRows,
    List<Attachment> attachmentRows,
  ) {
    final attachmentMap = <String, Attachment>{};
    for (final att in attachmentRows) {
      attachmentMap[att.messageId] = att;
    }

    final messages = messageRows.map((msgRow) {
      final att = attachmentMap[msgRow.id];
      final senderEnum = msgRow.sender == 'user'
          ? MessageSender.user
          : MessageSender.assistant;
      final statusEnum = MessageStatus.values.firstWhere(
        (e) => e.name == msgRow.status,
        orElse: () => MessageStatus.complete,
      );

      return ChatMessage(
        id: msgRow.id,
        sessionId: msgRow.chatId,
        sender: senderEnum,
        content: msgRow.content,
        timestamp: msgRow.timestamp,
        modelId: msgRow.modelId,
        attachmentName: att?.fileName,
        attachmentPath: att?.localPath,
        status: statusEnum,
        errorMessage: msgRow.errorMessage,
      );
    }).toList();

    return ChatSession(
      id: chatRow.id,
      title: chatRow.title,
      createdAt: chatRow.createdAt,
      lastUpdatedAt: chatRow.updatedAt,
      messages: messages,
      modelId: chatRow.modelId,
      isPinned: chatRow.isPinned,
    );
  }

  Future<List<ChatSession>> getChats({String query = ''}) async {
    final chatQuery = db.select(db.chats)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    if (query.trim().isNotEmpty) {
      final term = '%${query.trim()}%';
      chatQuery.where((t) => t.title.like(term));
    }

    final chatRows = await chatQuery.get();
    final sessions = <ChatSession>[];

    for (final chatRow in chatRows) {
      final msgRows =
          await (db.select(db.messages)
                ..where((m) => m.chatId.equals(chatRow.id))
                ..orderBy([
                  (m) => OrderingTerm(
                    expression: m.timestamp,
                    mode: OrderingMode.asc,
                  ),
                ]))
              .get();

      final attRows = await (db.select(
        db.attachments,
      )..where((a) => a.chatId.equals(chatRow.id))).get();

      sessions.add(_mapToSession(chatRow, msgRows, attRows));
    }

    return sessions;
  }

  Stream<List<ChatSession>> watchChats({String query = ''}) {
    final chatQuery = db.select(db.chats)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    if (query.trim().isNotEmpty) {
      final term = '%${query.trim()}%';
      chatQuery.where((t) => t.title.like(term));
    }

    return chatQuery.watch().asyncMap((chatRows) async {
      final sessions = <ChatSession>[];
      for (final chatRow in chatRows) {
        final msgRows =
            await (db.select(db.messages)
                  ..where((m) => m.chatId.equals(chatRow.id))
                  ..orderBy([
                    (m) => OrderingTerm(
                      expression: m.timestamp,
                      mode: OrderingMode.asc,
                    ),
                  ]))
                .get();

        final attRows = await (db.select(
          db.attachments,
        )..where((a) => a.chatId.equals(chatRow.id))).get();

        sessions.add(_mapToSession(chatRow, msgRows, attRows));
      }
      return sessions;
    });
  }

  Future<ChatSession?> getChatById(String id) async {
    final chatRow = await (db.select(
      db.chats,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (chatRow == null) return null;

    final msgRows =
        await (db.select(db.messages)
              ..where((m) => m.chatId.equals(id))
              ..orderBy([
                (m) => OrderingTerm(
                  expression: m.timestamp,
                  mode: OrderingMode.asc,
                ),
              ]))
            .get();

    final attRows = await (db.select(
      db.attachments,
    )..where((a) => a.chatId.equals(id))).get();

    return _mapToSession(chatRow, msgRows, attRows);
  }

  Stream<ChatSession?> watchChat(String id) {
    final query = db.select(db.chats)..where((c) => c.id.equals(id));
    return query.watchSingleOrNull().asyncMap((chatRow) async {
      if (chatRow == null) return null;

      final msgRows =
          await (db.select(db.messages)
                ..where((m) => m.chatId.equals(id))
                ..orderBy([
                  (m) => OrderingTerm(
                    expression: m.timestamp,
                    mode: OrderingMode.asc,
                  ),
                ]))
              .get();

      final attRows = await (db.select(
        db.attachments,
      )..where((a) => a.chatId.equals(id))).get();

      return _mapToSession(chatRow, msgRows, attRows);
    });
  }

  Future<ChatSession> createChat({
    required String modelId,
    String title = 'New Conversation',
  }) async {
    final id = 'session-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final entry = ChatsCompanion.insert(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
      modelId: modelId,
      isPinned: const Value(false),
    );

    await db.into(db.chats).insert(entry);
    return ChatSession(
      id: id,
      title: title,
      createdAt: now,
      lastUpdatedAt: now,
      messages: const [],
      modelId: modelId,
    );
  }

  Future<void> updateChatTitle(String chatId, String newTitle) async {
    await (db.update(db.chats)..where((c) => c.id.equals(chatId))).write(
      ChatsCompanion(title: Value(newTitle), updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> toggleChatPin(String chatId) async {
    final chat = await getChatById(chatId);
    if (chat == null) return;

    await (db.update(db.chats)..where((c) => c.id.equals(chatId))).write(
      ChatsCompanion(
        isPinned: Value(!chat.isPinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteChat(String chatId) async {
    // Foreign Key cascade is active, so deleting chat row removes messages and attachments automatically
    await (db.delete(db.chats)..where((c) => c.id.equals(chatId))).go();
  }

  Future<ChatMessage> addMessage({
    required String chatId,
    required String content,
    required MessageSender sender,
    String? modelId,
    String? attachmentName,
    String? localPath,
    MessageStatus status = MessageStatus.complete,
    String? errorMessage,
  }) async {
    final msgId = 'msg-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    await db
        .into(db.messages)
        .insert(
          MessagesCompanion.insert(
            id: msgId,
            chatId: chatId,
            sender: sender.name,
            content: content,
            timestamp: now,
            status: Value(status.name),
            modelId: Value(modelId),
            errorMessage: Value(errorMessage),
          ),
        );

    if (attachmentName != null) {
      final attId = 'att-${DateTime.now().millisecondsSinceEpoch}';
      await db
          .into(db.attachments)
          .insert(
            AttachmentsCompanion.insert(
              id: attId,
              messageId: msgId,
              chatId: chatId,
              fileName: attachmentName,
              localPath: localPath ?? attachmentName,
              createdAt: now,
            ),
          );
    }

    // Auto-update Chat title if first user message
    final chat = await getChatById(chatId);
    if (chat != null) {
      String newTitle = chat.title;
      if (chat.messages.length <= 1 && sender == MessageSender.user) {
        newTitle = content.length > 30
            ? '${content.substring(0, 30)}...'
            : content;
      }

      await (db.update(db.chats)..where((c) => c.id.equals(chatId))).write(
        ChatsCompanion(title: Value(newTitle), updatedAt: Value(now)),
      );
    }

    return ChatMessage(
      id: msgId,
      sessionId: chatId,
      sender: sender,
      content: content,
      timestamp: now,
      modelId: modelId,
      attachmentName: attachmentName,
      attachmentPath: localPath ?? attachmentName,
      status: status,
      errorMessage: errorMessage,
    );
  }

  Future<void> updateMessageStatus(
    String messageId, {
    required MessageStatus status,
    String? content,
    String? errorMessage,
  }) async {
    await (db.update(db.messages)..where((m) => m.id.equals(messageId))).write(
      MessagesCompanion(
        status: Value(status.name),
        content: content != null ? Value(content) : const Value.absent(),
        errorMessage: errorMessage != null
            ? Value(errorMessage)
            : const Value.absent(),
      ),
    );
  }

  Future<void> deleteMessage(String messageId) async {
    await (db.delete(db.messages)..where((m) => m.id.equals(messageId))).go();
  }
}
