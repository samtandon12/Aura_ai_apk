import 'dart:convert';

import 'package:aura_ai/core/services/groq_provider_client.dart';
import 'package:aura_ai/core/services/llm_provider_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late GroqProviderClient client;

  setUp(() {
    client = GroqProviderClient();
  });

  group('GroqProviderClient Unit Tests', () {
    test('validateApiKey returns true on status 200', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('{"id": "test"}', 200);
      });

      final result = await client.validateApiKey(
        'gsk_valid_key',
        client: mockHttpClient,
      );
      expect(result, isTrue);
    });

    test('validateApiKey returns false on status 401', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('{"error": "invalid_key"}', 401);
      });

      final result = await client.validateApiKey(
        'invalid_key',
        client: mockHttpClient,
      );
      expect(result, isFalse);
    });

    test('streamChatCompletion parses SSE stream data correctly', () async {
      final mockHttpClient = MockClient.streaming((request, bodyStream) async {
        final sseData = [
          'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n',
          'data: {"choices":[{"delta":{"content":" Aura!"}}]}\n\n',
          'data: [DONE]\n\n',
        ];
        return http.StreamedResponse(
          Stream.fromIterable(sseData.map((s) => utf8.encode(s))),
          200,
        );
      });

      final chunks = await client
          .streamChatCompletion(
            apiKey: 'gsk_valid_key',
            modelId: 'openai/gpt-oss-120b',
            history: const [],
            prompt: 'Hi',
            client: mockHttpClient,
          )
          .toList();

      expect(chunks, equals(['Hello', ' Aura!']));
    });

    test('streamChatCompletion throws InvalidApiKeyException on 401', () async {
      final mockHttpClient = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"error": "Unauthorized"}')),
          401,
        );
      });

      expect(
        () => client
            .streamChatCompletion(
              apiKey: 'bad_key',
              modelId: 'openai/gpt-oss-120b',
              history: const [],
              prompt: 'Hi',
              client: mockHttpClient,
            )
            .toList(),
        throwsA(isA<InvalidApiKeyException>()),
      );
    });

    test('streamChatCompletion throws RateLimitException on 429', () async {
      final mockHttpClient = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"error": "Rate limit"}')),
          429,
        );
      });

      expect(
        () => client
            .streamChatCompletion(
              apiKey: 'valid_key',
              modelId: 'openai/gpt-oss-120b',
              history: const [],
              prompt: 'Hi',
              client: mockHttpClient,
            )
            .toList(),
        throwsA(isA<RateLimitException>()),
      );
    });
  });
}
