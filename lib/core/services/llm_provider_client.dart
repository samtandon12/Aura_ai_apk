import 'package:http/http.dart' as http;

import '../../models/chat_message.dart';

abstract class LLMException implements Exception {
  final String message;
  final String? code;

  const LLMException(this.message, {this.code});

  @override
  String toString() => 'LLMException: $message';
}

class InvalidApiKeyException extends LLMException {
  const InvalidApiKeyException([
    super.message = 'Invalid or missing API key',
    String? code,
  ]) : super(code: code);
}

class RateLimitException extends LLMException {
  const RateLimitException([
    super.message = 'Rate limit exceeded. Please wait a moment and try again.',
    String? code,
  ]) : super(code: code);
}

class NetworkException extends LLMException {
  const NetworkException([
    super.message = 'Network error. Please check your internet connection.',
    String? code,
  ]) : super(code: code);
}

class ServerException extends LLMException {
  const ServerException([
    super.message = 'Provider service error. Please try again later.',
    String? code,
  ]) : super(code: code);
}

abstract class LLMProviderClient {
  String get providerName;

  /// Stream response chunks for a chat completion request
  Stream<String> streamChatCompletion({
    required String apiKey,
    required String modelId,
    required List<ChatMessage> history,
    required String prompt,
    http.Client? client,
  });

  /// Validate whether the given API key is valid with the provider server
  Future<bool> validateApiKey(String apiKey, {http.Client? client});
}
