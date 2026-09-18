import 'package:aura_ai/data/database/app_database.dart';
import 'package:aura_ai/data/repositories/chat_repository.dart';
import 'package:aura_ai/models/chat_message.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ChatRepository repository;

  setUp(() {
    // In-Memory SQLite database for fast unit testing
    db = AppDatabase(NativeDatabase.memory());
    repository = ChatRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ChatRepository SQLite Persistence Tests', () {
    test('Create and retrieve chat sessions', () async {
      final session = await repository.createChat(
        modelId: 'groq-llama-3.3-70b',
        title: 'Test Conversation',
      );

      expect(session.id, startsWith('session-'));
      expect(session.title, equals('Test Conversation'));

      final retrieved = await repository.getChatById(session.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.modelId, equals('groq-llama-3.3-70b'));
    });

    test('Add message and attachment to chat', () async {
      final session = await repository.createChat(
        modelId: 'groq-llama-3.3-70b',
        title: 'Attachment Test',
      );

      final msg = await repository.addMessage(
        chatId: session.id,
        content: 'Check this architecture spec file',
        sender: MessageSender.user,
        attachmentName: 'spec.dart',
        localPath: '/docs/spec.dart',
      );

      expect(msg.content, equals('Check this architecture spec file'));
      expect(msg.attachmentName, equals('spec.dart'));

      final updatedSession = await repository.getChatById(session.id);
      expect(updatedSession!.messages.length, equals(1));
      expect(updatedSession.messages.first.attachmentName, equals('spec.dart'));
    });

    test('Rename and toggle pin status', () async {
      final session = await repository.createChat(
        modelId: 'nvidia-llama-3.1-405b',
        title: 'Old Title',
      );

      await repository.updateChatTitle(session.id, 'Renamed Title');
      await repository.toggleChatPin(session.id);

      final updated = await repository.getChatById(session.id);
      expect(updated!.title, equals('Renamed Title'));
      expect(updated.isPinned, isTrue);
    });

    test(
      'Cascade delete removes chat and related messages & attachments safely',
      () async {
        final session = await repository.createChat(
          modelId: 'groq-llama-3.3-70b',
          title: 'To Delete',
        );

        final msg = await repository.addMessage(
          chatId: session.id,
          content: 'Temporary msg',
          sender: MessageSender.user,
          attachmentName: 'temp.txt',
          localPath: '/tmp/temp.txt',
        );

        expect(msg.id, isNotEmpty);

        // Delete Chat
        await repository.deleteChat(session.id);

        final deletedSession = await repository.getChatById(session.id);
        expect(deletedSession, isNull);

        // Verify messages table is empty
        final allMessages = await db.select(db.messages).get();
        expect(allMessages, isEmpty);

        // Verify attachments table is empty
        final allAttachments = await db.select(db.attachments).get();
        expect(allAttachments, isEmpty);
      },
    );

    test('Search chats by query string', () async {
      await repository.createChat(
        modelId: 'groq-llama-3.3-70b',
        title: 'Flutter Clean Architecture',
      );
      await repository.createChat(
        modelId: 'nvidia-llama-3.1-405b',
        title: 'Quantum Physics',
      );

      final results = await repository.getChats(query: 'Flutter');
      expect(results.length, equals(1));
      expect(results.first.title, contains('Flutter'));
    });
  });
}
