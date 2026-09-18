import 'dart:convert';

import 'package:aura_ai/core/services/export_service.dart';
import 'package:aura_ai/models/chat_message.dart';
import 'package:aura_ai/models/chat_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ChatExportService exportService;
  late ChatSession testSession;

  setUp(() {
    exportService = ChatExportService();
    testSession = ChatSession(
      id: 'session-123',
      title: 'Flutter Architecture Discussion',
      createdAt: DateTime(2026, 9, 18, 10, 0),
      lastUpdatedAt: DateTime(2026, 9, 18, 10, 5),
      modelId: 'groq-llama-3.3-70b',
      messages: [
        ChatMessage(
          id: 'msg-1',
          sessionId: 'session-123',
          sender: MessageSender.user,
          content: 'What is the recommended state management approach?',
          timestamp: DateTime(2026, 9, 18, 10, 0),
          attachmentName: 'architecture_diagram.png',
        ),
        ChatMessage(
          id: 'msg-2',
          sessionId: 'session-123',
          sender: MessageSender.assistant,
          content: 'Riverpod is recommended for type safety and testability.',
          timestamp: DateTime(2026, 9, 18, 10, 1),
          modelId: 'groq-llama-3.3-70b',
        ),
      ],
    );
  });

  group('ChatExportService Unit Tests', () {
    test('generateTxt includes headers, messages, and attachment metadata', () {
      final txt = exportService.generateTxt(testSession);
      expect(txt, contains('AURA AI CHAT EXPORT'));
      expect(txt, contains('Title: Flutter Architecture Discussion'));
      expect(txt, contains('Model: groq-llama-3.3-70b'));
      expect(txt, contains('[USER]'));
      expect(txt, contains('[Attachment Metadata: architecture_diagram.png]'));
      expect(
        txt,
        contains('What is the recommended state management approach?'),
      );
      expect(txt, contains('[AURA ASSISTANT]'));
      expect(
        txt,
        contains('Riverpod is recommended for type safety and testability.'),
      );
    });

    test('generateMarkdown formats headers, tags, and message blocks', () {
      final md = exportService.generateMarkdown(testSession);
      expect(md, contains('# Flutter Architecture Discussion'));
      expect(md, contains('**Model:** `groq-llama-3.3-70b`'));
      expect(md, contains('### 👤 User'));
      expect(md, contains('📎 **Attachment:** `architecture_diagram.png`'));
      expect(md, contains('### 🤖 Aura Assistant'));
      expect(
        md,
        contains('Riverpod is recommended for type safety and testability.'),
      );
    });

    test('generateJson outputs valid structured JSON string', () {
      final jsonStr = exportService.generateJson(testSession);
      expect(jsonStr, isNotEmpty);

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['app'], equals('Aura AI'));
      expect(decoded['session']['id'], equals('session-123'));
      expect(
        decoded['session']['title'],
        equals('Flutter Architecture Discussion'),
      );

      final messages = decoded['session']['messages'] as List;
      expect(messages.length, equals(2));
      expect(messages.first['sender'], equals('user'));
      expect(
        messages.first['attachmentName'],
        equals('architecture_diagram.png'),
      );
      expect(messages.last['sender'], equals('assistant'));
    });
  });
}
