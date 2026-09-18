import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/chat_message.dart';
import '../../models/chat_session.dart';

enum ExportFormat { txt, markdown, json }

class ChatExportService {
  String generateTxt(ChatSession session) {
    final buffer = StringBuffer();
    buffer.writeln('==================================================');
    buffer.writeln('AURA AI CHAT EXPORT');
    buffer.writeln('Title: ${session.title}');
    buffer.writeln('Session ID: ${session.id}');
    buffer.writeln('Model: ${session.modelId}');
    buffer.writeln('Exported At: ${DateTime.now().toIso8601String()}');
    buffer.writeln('==================================================\n');

    for (final msg in session.messages) {
      final roleStr = msg.sender == MessageSender.user
          ? 'USER'
          : 'AURA ASSISTANT';
      final timeStr = msg.timestamp.toIso8601String();
      buffer.writeln('[$roleStr] ($timeStr)');
      if (msg.attachmentName != null) {
        buffer.writeln('[Attachment Metadata: ${msg.attachmentName}]');
      }
      buffer.writeln(msg.content);
      buffer.writeln('--------------------------------------------------\n');
    }

    return buffer.toString();
  }

  String generateMarkdown(ChatSession session) {
    final buffer = StringBuffer();
    buffer.writeln('# ${session.title}');
    buffer.writeln();
    buffer.writeln('> **Exported from Aura AI Assistant**  ');
    buffer.writeln('> **Model:** `${session.modelId}`  ');
    buffer.writeln('> **Date:** `${session.createdAt.toLocal().toString()}`  ');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (final msg in session.messages) {
      final isUser = msg.sender == MessageSender.user;
      final roleStr = isUser ? '👤 User' : '🤖 Aura Assistant';
      buffer.writeln('### $roleStr');
      buffer.writeln('*${msg.timestamp.toLocal().toString()}*');
      buffer.writeln();
      if (msg.attachmentName != null) {
        buffer.writeln('📎 **Attachment:** `${msg.attachmentName}`');
        buffer.writeln();
      }
      buffer.writeln(msg.content);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }

  String generateJson(ChatSession session) {
    final exportData = {
      'app': 'Aura AI',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'session': {
        'id': session.id,
        'title': session.title,
        'modelId': session.modelId,
        'createdAt': session.createdAt.toIso8601String(),
        'updatedAt': session.lastUpdatedAt.toIso8601String(),
        'messages': session.messages.map((m) {
          return {
            'id': m.id,
            'sender': m.sender.name,
            'content': m.content,
            'timestamp': m.timestamp.toIso8601String(),
            'attachmentName': m.attachmentName,
            'status': m.status.name,
          };
        }).toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  Future<void> shareChatExport(ChatSession session, ExportFormat format) async {
    String content;
    String extension;
    String mimeType;

    switch (format) {
      case ExportFormat.txt:
        content = generateTxt(session);
        extension = 'txt';
        mimeType = 'text/plain';
        break;
      case ExportFormat.markdown:
        content = generateMarkdown(session);
        extension = 'md';
        mimeType = 'text/markdown';
        break;
      case ExportFormat.json:
        content = generateJson(session);
        extension = 'json';
        mimeType = 'application/json';
        break;
    }

    final tempDir = await getTemporaryDirectory();
    final sanitizedTitle = session.title
        .replaceAll(RegExp(r'[^\w\s-]'), '_')
        .replaceAll(' ', '_');
    final fileName =
        'AuraChat_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final filePath = p.join(tempDir.path, fileName);

    final file = File(filePath);
    await file.writeAsString(content, encoding: utf8);

    await Share.shareXFiles(
      [XFile(filePath, mimeType: mimeType)],
      text: 'Exported conversation: ${session.title}',
      subject: 'Aura AI Chat Export — ${session.title}',
    );
  }
}
