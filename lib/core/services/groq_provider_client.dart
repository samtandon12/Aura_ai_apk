import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/chat_message.dart';
import 'llm_provider_client.dart';

class GroqProviderClient implements LLMProviderClient {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  @override
  String get providerName => 'Groq';

  // Map internal model IDs to Groq endpoint model names
  String _mapModelId(String modelId) {
    if (modelId.contains('mixtral')) {
      return 'mixtral-8x7b-32768';
    } else if (modelId.contains('8b')) {
      return 'llama-3.1-8b-instant';
    }
    return 'llama-3.3-70b-versatile';
  }

  @override
  Future<bool> validateApiKey(String apiKey, {http.Client? client}) async {
    if (apiKey.trim().isEmpty) return false;

    final httpClient = client ?? http.Client();
    final isCustomClient = client != null;

    try {
      final response = await httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': 'Test key'},
          ],
          'max_tokens': 1,
          'stream': false,
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      if (!isCustomClient) {
        httpClient.close();
      }
    }
  }

  @override
  Stream<String> streamChatCompletion({
    required String apiKey,
    required String modelId,
    required List<ChatMessage> history,
    required String prompt,
    http.Client? client,
  }) async* {
    if (apiKey.trim().isEmpty) {
      throw const InvalidApiKeyException(
        'Groq API Key is missing. Please configure it in Settings.',
      );
    }

    final httpClient = client ?? http.Client();
    final groqModel = _mapModelId(modelId);

    // Build conversation history messages list
    final messages = [
      {
        'role': 'system',
        'content': 'You are Aura AI, a helpful, elegant, and intelligent AI companion created with Dart & Flutter. Keep responses clear, beautifully formatted, and engaging.',
      },
      for (final msg in history)
        if (msg.content.isNotEmpty)
          {
            'role': msg.sender == MessageSender.user ? 'user' : 'assistant',
            'content': msg.content,
          },
      {'role': 'user', 'content': prompt},
    ];

    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.headers.addAll({
      'Authorization': 'Bearer ${apiKey.trim()}',
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode({
      'model': groqModel,
      'messages': messages,
      'stream': true,
      'temperature': 0.7,
    });

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await httpClient.send(request);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is LLMException) rethrow;
      throw NetworkException('Connection error: $e');
    }

    if (streamedResponse.statusCode == 401) {
      throw const InvalidApiKeyException('Invalid Groq API key provided.');
    } else if (streamedResponse.statusCode == 429) {
      throw const RateLimitException();
    } else if (streamedResponse.statusCode >= 500) {
      throw ServerException(
        'Groq server error (${streamedResponse.statusCode}).',
      );
    } else if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      throw ServerException(
        'Groq API Error (${streamedResponse.statusCode}): $body',
      );
    }

    // Process Server-Sent Events (SSE) stream
    final lineStream = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;

      final dataContent = trimmed.substring(5).trim();
      if (dataContent == '[DONE]') break;

      try {
        final json = jsonDecode(dataContent) as Map<String, dynamic>;
        final choices = json['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final delta = choices.first['delta'] as Map<String, dynamic>?;
          final contentChunk = delta?['content'] as String?;
          if (contentChunk != null && contentChunk.isNotEmpty) {
            yield contentChunk;
          }
        }
      } catch (_) {
        // Ignore unparseable line chunks safely
      }
    }
  }
}
