import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/chat_message.dart';
import 'llm_provider_client.dart';

class NvidiaNimProviderClient implements LLMProviderClient {
  static const String _baseUrl =
      'https://integrate.api.nvidia.com/v1/chat/completions';

  @override
  String get providerName => 'NVIDIA NIM';

  // Map internal model IDs to NVIDIA NIM endpoint model names
  String _mapModelId(String modelId) {
    if (modelId.contains('nemotron')) {
      return 'nvidia/nemotron-3-ultra-550b-a55b';
    }
    return 'nvidia/nemotron-3-ultra-550b-a55b';
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
          'model': 'nvidia/nemotron-3-ultra-550b-a55b',
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
        'NVIDIA API Key is missing. Please configure it in Settings.',
      );
    }

    final httpClient = client ?? http.Client();
    final nvidiaModel = _mapModelId(modelId);

    final messages = [
      {
        'role': 'system',
        'content': 'You are Aura AI, powered by NVIDIA NIM cloud infrastructure. Provide accurate, clear, and elegant responses.',
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
      'model': nvidiaModel,
      'messages': messages,
      'stream': true,
      'temperature': 0.7,
      'max_tokens': 2048,
    });

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await httpClient.send(request);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      if (e is LLMException) rethrow;
      throw NetworkException('NVIDIA NIM connection error: $e');
    }

    if (streamedResponse.statusCode == 401) {
      throw const InvalidApiKeyException('Invalid NVIDIA API key provided.');
    } else if (streamedResponse.statusCode == 402 ||
        streamedResponse.statusCode == 429) {
      throw const RateLimitException(
        'NVIDIA NIM rate limit or quota exceeded. Please try again later.',
      );
    } else if (streamedResponse.statusCode >= 500) {
      throw ServerException(
        'NVIDIA NIM server error (${streamedResponse.statusCode}).',
      );
    } else if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      throw ServerException(
        'NVIDIA NIM API Error (${streamedResponse.statusCode}): $body',
      );
    }

    // Process SSE stream
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
          final reasoningChunk =
              delta?['reasoning_content'] as String? ??
              delta?['reasoning'] as String?;

          if (contentChunk != null && contentChunk.isNotEmpty) {
            yield contentChunk;
          } else if (reasoningChunk != null && reasoningChunk.isNotEmpty) {
            yield reasoningChunk;
          }
        }
      } catch (_) {
        // Ignore unparseable line chunks safely
      }
    }
  }
}
