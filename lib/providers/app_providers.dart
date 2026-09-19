import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/services/attachment_service.dart';
import '../core/services/biometric_service.dart';
import '../core/services/export_service.dart';
import '../core/services/groq_provider_client.dart';
import '../core/services/llm_provider_client.dart';
import '../core/services/nvidia_provider_client.dart';
import '../core/services/secure_storage_service.dart';
import '../data/database/app_database.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/memory_repository.dart';
import '../data/repositories/persona_repository.dart';
import '../data/repositories/prompt_repository.dart';
import '../models/ai_model.dart';
import '../models/ai_persona.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/saved_prompt.dart';
import '../models/user_memory.dart';

// Secure Storage Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Export Service Provider
final exportServiceProvider = Provider<ChatExportService>((ref) {
  return ChatExportService();
});

// Biometric Service Provider
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

// Attachment Service Provider
final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService();
});

// Biometric Lock Enabled Notifier
class IsBiometricLockEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadState();
    return false;
  }

  Future<void> _loadState() async {
    final storage = ref.read(secureStorageProvider);
    final val = await storage.getBiometricEnabled();
    state = val;
  }

  Future<void> setEnabled(bool enabled) async {
    final storage = ref.read(secureStorageProvider);
    await storage.saveBiometricEnabled(enabled);
    state = enabled;
  }
}

final isBiometricLockEnabledProvider =
    NotifierProvider<IsBiometricLockEnabledNotifier, bool>(
      IsBiometricLockEnabledNotifier.new,
    );

// App Runtime Unlocked State Notifier
class IsAppUnlockedNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setUnlocked(bool value) => state = value;
}

final isAppUnlockedProvider = NotifierProvider<IsAppUnlockedNotifier, bool>(
  IsAppUnlockedNotifier.new,
);

// Groq Client Provider
final groqClientProvider = Provider<GroqProviderClient>((ref) {
  return GroqProviderClient();
});

// NVIDIA Client Provider
final nvidiaClientProvider = Provider<NvidiaNimProviderClient>((ref) {
  return NvidiaNimProviderClient();
});

// Database Singleton Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Chat Repository Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(databaseProvider));
});

// Memory Repository Provider
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository(ref.watch(databaseProvider));
});

// Persona Repository Provider
final personaRepositoryProvider = Provider<PersonaRepository>((ref) {
  return PersonaRepository(ref.watch(databaseProvider));
});

// Prompt Repository Provider
final promptRepositoryProvider = Provider<PromptRepository>((ref) {
  return PromptRepository(ref.watch(databaseProvider));
});

// Global Memory Enabled Notifier
class IsMemoryEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setEnabled(bool value) => state = value;
}

final isMemoryEnabledProvider = NotifierProvider<IsMemoryEnabledNotifier, bool>(
  IsMemoryEnabledNotifier.new,
);

// Active AI Persona Notifier
class ActivePersonaNotifier extends Notifier<AIPersona> {
  @override
  AIPersona build() => AIPersona.defaultPersona;

  void setPersona(AIPersona persona) => state = persona;
}

final activePersonaProvider =
    NotifierProvider<ActivePersonaNotifier, AIPersona>(
      ActivePersonaNotifier.new,
    );

// Stream Providers for Memories, Personas, Prompts
final memoriesStreamProvider = StreamProvider<List<UserMemory>>((ref) {
  return ref.watch(memoryRepositoryProvider).watchMemories();
});

final personasStreamProvider = StreamProvider<List<AIPersona>>((ref) {
  return ref.watch(personaRepositoryProvider).watchPersonas();
});

final promptsStreamProvider = StreamProvider<List<SavedPrompt>>((ref) {
  return ref.watch(promptRepositoryProvider).watchPrompts();
});

// Selected AI Model Notifier
class SelectedModelNotifier extends Notifier<AIModel> {
  @override
  AIModel build() => AIModel.defaultModel;

  void setModel(AIModel model) {
    state = model;
  }
}

final selectedModelProvider = NotifierProvider<SelectedModelNotifier, AIModel>(
  SelectedModelNotifier.new,
);

// Search Query Notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// Generating State Notifier
class IsGeneratingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setGenerating(bool value) {
    state = value;
  }
}

final isGeneratingProvider = NotifierProvider<IsGeneratingNotifier, bool>(
  IsGeneratingNotifier.new,
);

// Active Chat ID Notifier
class ActiveChatIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setActiveId(String? id) {
    state = id;
  }
}

final activeChatIdProvider = NotifierProvider<ActiveChatIdNotifier, String?>(
  ActiveChatIdNotifier.new,
);

// DB-Backed Chat History Stream Provider
final chatHistoryStreamProvider = StreamProvider<List<ChatSession>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  return repo.watchChats(query: query);
});

// Chat History & AI Completion Controller
class ChatHistoryNotifier extends Notifier<List<ChatSession>> {
  StreamSubscription<String>? _activeStreamSub;
  http.Client? _activeHttpClient;

  @override
  List<ChatSession> build() {
    _initSeedDataIfNeeded();
    final repo = ref.watch(chatRepositoryProvider);
    final query = ref.watch(searchQueryProvider);

    repo.getChats(query: query).then((chats) {
      state = chats;
    });

    final subscription = repo.watchChats(query: query).listen((chats) {
      state = chats;
    });

    ref.onDispose(() {
      subscription.cancel();
      _activeStreamSub?.cancel();
      _activeStreamSub = null;
      _activeHttpClient?.close();
      _activeHttpClient = null;
    });

    return [];
  }

  Future<void> _initSeedDataIfNeeded() async {
    final repo = ref.read(chatRepositoryProvider);
    final chats = await repo.getChats();
    if (chats.isEmpty) {
      final s1 = await repo.createChat(
        modelId: 'groq-llama-3.3-70b',
        title: 'Riverpod & GoRouter Clean Architecture',
      );
      await repo.toggleChatPin(s1.id);
      await repo.addMessage(
        chatId: s1.id,
        content: 'How should I structure a modern Flutter project with Riverpod and GoRouter?',
        sender: MessageSender.user,
      );
      await repo.addMessage(
        chatId: s1.id,
        content:
            'A feature-first structure is recommended:\n\n'
            '• lib/core/ (theme, router, constants)\n'
            '• lib/features/ (home, chat, settings)\n'
            '• lib/models/ (data entities)\n'
            '• lib/providers/ (Riverpod providers)\n\n'
            'This guarantees scalability and modularity.',
        sender: MessageSender.assistant,
        modelId: 'groq-llama-3.3-70b',
      );
    }
  }

  void _stopCurrentGeneration() {
    _activeStreamSub?.cancel();
    _activeStreamSub = null;
    _activeHttpClient?.close();
    _activeHttpClient = null;
    ref.read(isGeneratingProvider.notifier).setGenerating(false);
  }

  void stopGeneration() {
    _stopCurrentGeneration();
  }

  Future<String> createNewSession({
    required String modelId,
    String title = 'New Conversation',
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    final session = await repo.createChat(modelId: modelId, title: title);
    return session.id;
  }

  Future<void> sendUserMessageAndStreamResponse({
    required String sessionId,
    required String content,
    String? attachmentName,
    String? localPath,
  }) async {
    _stopCurrentGeneration();

    final repo = ref.read(chatRepositoryProvider);
    final currentModel = ref.read(selectedModelProvider);
    final attachmentService = ref.read(attachmentServiceProvider);

    String? savedPath = localPath;
    if (localPath != null && attachmentName != null) {
      final file = File(localPath);
      if (await file.exists()) {
        savedPath = await attachmentService.saveAttachmentToAppStorage(
          file,
          attachmentName,
        );
      }
    }

    // 1. Add User Message to SQLite
    await repo.addMessage(
      chatId: sessionId,
      content: content,
      sender: MessageSender.user,
      attachmentName: attachmentName,
      localPath: savedPath,
    );

    // 2. Prepare Effective Prompt with Persona, Memory, and Document/Image Context
    final activePersona = ref.read(activePersonaProvider);
    final isMemoryEnabled = ref.read(isMemoryEnabledProvider);
    final memoryRepo = ref.read(memoryRepositoryProvider);

    final StringBuffer promptBuffer = StringBuffer();

    // System Persona Context
    if (activePersona.systemPrompt.trim().isNotEmpty) {
      promptBuffer.writeln('[System Persona: ${activePersona.name}]');
      promptBuffer.writeln(activePersona.systemPrompt.trim());
      promptBuffer.writeln();
    }

    // User Memory Context (If Enabled)
    if (isMemoryEnabled) {
      final activeMemories = await memoryRepo.getActiveMemories();
      if (activeMemories.isNotEmpty) {
        promptBuffer.writeln(
          '[User Personal Memories (Transmitted to provider for personalization)]:',
        );
        for (final mem in activeMemories) {
          promptBuffer.writeln('- ${mem.fact}');
        }
        promptBuffer.writeln();
      }
    }

    // Attachment & Content Context
    if (savedPath != null && attachmentName != null) {
      final ext = attachmentName.split('.').last.toLowerCase();
      final isImg = attachmentService.isImageExtension(ext);

      if (!isImg) {
        // Document Text Extraction
        final file = File(savedPath);
        if (await file.exists()) {
          final extracted = await attachmentService.extractDocumentText(
            file,
            ext,
          );
          promptBuffer.writeln('[Attached Document: $attachmentName]');
          promptBuffer.writeln('Extracted Content:');
          promptBuffer.writeln(extracted);
          promptBuffer.writeln();
          promptBuffer.writeln('User Question:');
          promptBuffer.writeln(content);
        }
      } else {
        // Image Attachment Handling & Vision Compatibility Check
        if (!currentModel.supportsVision) {
          promptBuffer.writeln('[Attached Image: $attachmentName]');
          promptBuffer.writeln(
            '[Note: The selected model "${currentModel.name}" is text-only. Visual image analysis is bypassed. To analyze images, switch to a Vision model in the Model Selector.]',
          );
          promptBuffer.writeln();
          promptBuffer.writeln('User Question:');
          promptBuffer.writeln(content);
        } else {
          promptBuffer.writeln('[Attached Image: $attachmentName]');
          promptBuffer.writeln(
            'Please analyze the attached image visual details and answer:',
          );
          promptBuffer.writeln(content);
        }
      }
    } else {
      promptBuffer.write(content);
    }

    final String effectivePrompt = promptBuffer.toString();

    // 3. Fetch session history for AI context
    final chat = await repo.getChatById(sessionId);
    final history = chat?.messages ?? [];

    // 4. Add initial empty Assistant message with status 'generating'
    final assistantMsg = await repo.addMessage(
      chatId: sessionId,
      content: '',
      sender: MessageSender.assistant,
      modelId: currentModel.name,
      status: MessageStatus.generating,
    );

    ref.read(isGeneratingProvider.notifier).setGenerating(true);

    // 5. Select Provider Client & Fetch Encrypted Key
    final secureStorage = ref.read(secureStorageProvider);
    LLMProviderClient providerClient;
    String? apiKey;

    if (currentModel.provider == AIProvider.groq) {
      providerClient = ref.read(groqClientProvider);
      apiKey = await secureStorage.getGroqApiKey();
    } else {
      providerClient = ref.read(nvidiaClientProvider);
      apiKey = await secureStorage.getNvidiaApiKey();
    }

    if (apiKey == null || apiKey.trim().isEmpty) {
      final providerTitle = currentModel.providerDisplayName;
      await repo.updateMessageStatus(
        assistantMsg.id,
        status: MessageStatus.error,
        errorMessage:
            '$providerTitle API Key required. Please configure your $providerTitle API key in Settings.',
      );
      ref.read(isGeneratingProvider.notifier).setGenerating(false);
      return;
    }

    // 6. Stream Completion from Selected Provider Client
    _activeHttpClient = http.Client();
    String accumulatedContent = '';

    try {
      final stream = providerClient.streamChatCompletion(
        apiKey: apiKey,
        modelId: currentModel.id,
        history: history,
        prompt: effectivePrompt,
        client: _activeHttpClient,
      );

      _activeStreamSub = stream.listen(
        (chunk) async {
          accumulatedContent += chunk;
          await repo.updateMessageStatus(
            assistantMsg.id,
            status: MessageStatus.generating,
            content: accumulatedContent,
          );
        },
        onDone: () async {
          await repo.updateMessageStatus(
            assistantMsg.id,
            status: MessageStatus.complete,
            content: accumulatedContent,
          );
          _stopCurrentGeneration();
        },
        onError: (error) async {
          String errText = 'Failed to generate response.';
          if (error is LLMException) {
            errText = error.message;
          } else {
            errText = 'Error: $error';
          }

          await repo.updateMessageStatus(
            assistantMsg.id,
            status: MessageStatus.error,
            content: accumulatedContent,
            errorMessage: errText,
          );
          _stopCurrentGeneration();
        },
        cancelOnError: true,
      );
    } catch (e) {
      String errText = 'Failed to send request: $e';
      if (e is LLMException) {
        errText = e.message;
      }
      await repo.updateMessageStatus(
        assistantMsg.id,
        status: MessageStatus.error,
        errorMessage: errText,
      );
      _stopCurrentGeneration();
    }
  }

  Future<void> retryMessage(String sessionId, String failedMessageId) async {
    final repo = ref.read(chatRepositoryProvider);
    final chat = await repo.getChatById(sessionId);
    if (chat == null || chat.messages.isEmpty) return;

    final lastUserMsg = chat.messages.lastWhere(
      (m) => m.sender == MessageSender.user,
      orElse: () => chat.messages.last,
    );

    await repo.deleteMessage(failedMessageId);

    await sendUserMessageAndStreamResponse(
      sessionId: sessionId,
      content: lastUserMsg.content,
      attachmentName: lastUserMsg.attachmentName,
      localPath: lastUserMsg.attachmentPath,
    );
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.updateChatTitle(sessionId, newTitle);
  }

  Future<void> togglePin(String sessionId) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.toggleChatPin(sessionId);
  }

  Future<void> deleteSession(String sessionId) async {
    final repo = ref.read(chatRepositoryProvider);
    final attachmentService = ref.read(attachmentServiceProvider);

    final chat = await repo.getChatById(sessionId);
    if (chat != null) {
      for (final msg in chat.messages) {
        if (msg.attachmentPath != null) {
          await attachmentService.deleteLocalAttachment(msg.attachmentPath!);
        }
      }
    }

    await repo.deleteChat(sessionId);
  }
}

final chatHistoryProvider =
    NotifierProvider<ChatHistoryNotifier, List<ChatSession>>(
      ChatHistoryNotifier.new,
    );

// Active Chat Session Stream Provider
final activeChatStreamProvider = StreamProvider<ChatSession?>((ref) {
  final activeId = ref.watch(activeChatIdProvider);
  if (activeId == null) return Stream.value(null);
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchChat(activeId);
});

// Computed Active Chat Session Provider
final activeChatProvider = Provider<ChatSession?>((ref) {
  final activeId = ref.watch(activeChatIdProvider);
  if (activeId == null) return null;
  final streamVal = ref.watch(activeChatStreamProvider);
  return streamVal.asData?.value;
});

// App Settings Model & Notifier
class AppSettings {
  final String groqApiKey;
  final String groqDefaultModel;
  final String nvidiaApiKey;
  final String nvidiaDefaultModel;
  final String themeMode;
  final bool isGroqKeyValid;
  final bool isValidatingGroqKey;
  final bool isNvidiaKeyValid;
  final bool isValidatingNvidiaKey;

  const AppSettings({
    this.groqApiKey = '',
    this.groqDefaultModel = 'openai/gpt-oss-120b',
    this.nvidiaApiKey = '',
    this.nvidiaDefaultModel = 'nvidia/nemotron-3-ultra-550b-a55b',
    this.themeMode = 'dark',
    this.isGroqKeyValid = true,
    this.isValidatingGroqKey = false,
    this.isNvidiaKeyValid = true,
    this.isValidatingNvidiaKey = false,
  });

  AppSettings copyWith({
    String? groqApiKey,
    String? groqDefaultModel,
    String? nvidiaApiKey,
    String? nvidiaDefaultModel,
    String? themeMode,
    bool? isGroqKeyValid,
    bool? isValidatingGroqKey,
    bool? isNvidiaKeyValid,
    bool? isValidatingNvidiaKey,
  }) {
    return AppSettings(
      groqApiKey: groqApiKey ?? this.groqApiKey,
      groqDefaultModel: groqDefaultModel ?? this.groqDefaultModel,
      nvidiaApiKey: nvidiaApiKey ?? this.nvidiaApiKey,
      nvidiaDefaultModel: nvidiaDefaultModel ?? this.nvidiaDefaultModel,
      themeMode: themeMode ?? this.themeMode,
      isGroqKeyValid: isGroqKeyValid ?? this.isGroqKeyValid,
      isValidatingGroqKey: isValidatingGroqKey ?? this.isValidatingGroqKey,
      isNvidiaKeyValid: isNvidiaKeyValid ?? this.isNvidiaKeyValid,
      isValidatingNvidiaKey:
          isValidatingNvidiaKey ?? this.isValidatingNvidiaKey,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadKeysFromSecureStorage();
    return const AppSettings();
  }

  Future<void> _loadKeysFromSecureStorage() async {
    final storage = ref.read(secureStorageProvider);
    var groqKey = await storage.getGroqApiKey();
    var nvidiaKey = await storage.getNvidiaApiKey();

    // Check compile-time environment flags first
    const envGroq = String.fromEnvironment('GROQ_API_KEY');
    const envNvidia = String.fromEnvironment('NVIDIA_API_KEY');

    if ((groqKey == null || groqKey.trim().isEmpty) &&
        envGroq.trim().isNotEmpty) {
      await storage.saveGroqApiKey(envGroq.trim());
      groqKey = envGroq.trim();
    }

    if ((nvidiaKey == null || nvidiaKey.trim().isEmpty) &&
        envNvidia.trim().isNotEmpty) {
      await storage.saveNvidiaApiKey(envNvidia.trim());
      nvidiaKey = envNvidia.trim();
    }

    // Check local uncommitted runtime file (local_keys.json) if keys are missing from storage
    if (groqKey == null ||
        groqKey.trim().isEmpty ||
        nvidiaKey == null ||
        nvidiaKey.trim().isEmpty) {
      try {
        final file = File('local_keys.json');
        if (await file.exists()) {
          final content = await file.readAsString();
          final Map<String, dynamic> data = jsonDecode(content);

          final fileGroq = data['groq_api_key'] as String?;
          final fileNvidia = data['nvidia_api_key'] as String?;

          if ((groqKey == null || groqKey.trim().isEmpty) &&
              fileGroq != null &&
              fileGroq.trim().isNotEmpty) {
            await storage.saveGroqApiKey(fileGroq.trim());
            groqKey = fileGroq.trim();
          }

          if ((nvidiaKey == null || nvidiaKey.trim().isEmpty) &&
              fileNvidia != null &&
              fileNvidia.trim().isNotEmpty) {
            await storage.saveNvidiaApiKey(fileNvidia.trim());
            nvidiaKey = fileNvidia.trim();
          }
        }
      } catch (_) {
        // Safe runtime check fallback
      }
    }

    final isGroqPresent = groqKey != null && groqKey.trim().isNotEmpty;
    final isNvidiaPresent = nvidiaKey != null && nvidiaKey.trim().isNotEmpty;

    state = state.copyWith(
      groqApiKey: groqKey ?? '',
      nvidiaApiKey: nvidiaKey ?? '',
      isGroqKeyValid: isGroqPresent,
      isNvidiaKeyValid: isNvidiaPresent,
    );

    final currentGroq = groqKey;
    if (currentGroq != null && currentGroq.trim().isNotEmpty) {
      ref.read(groqClientProvider).validateApiKey(currentGroq).then((valid) {
        state = state.copyWith(isGroqKeyValid: valid);
      });
    }

    final currentNvidia = nvidiaKey;
    if (currentNvidia != null && currentNvidia.trim().isNotEmpty) {
      ref.read(nvidiaClientProvider).validateApiKey(currentNvidia).then((
        valid,
      ) {
        state = state.copyWith(isNvidiaKeyValid: valid);
      });
    }
  }

  Future<bool> saveAndValidateGroqApiKey(String key) async {
    state = state.copyWith(isValidatingGroqKey: true);
    final storage = ref.read(secureStorageProvider);
    final groqClient = ref.read(groqClientProvider);

    final isValid = await groqClient.validateApiKey(key);
    if (isValid || key.trim().isEmpty) {
      await storage.saveGroqApiKey(key);
      state = state.copyWith(
        groqApiKey: key,
        isGroqKeyValid: isValid,
        isValidatingGroqKey: false,
      );
    } else {
      state = state.copyWith(isValidatingGroqKey: false, isGroqKeyValid: false);
    }

    return isValid;
  }

  Future<void> removeGroqApiKey() async {
    final storage = ref.read(secureStorageProvider);
    await storage.deleteGroqApiKey();
    state = state.copyWith(groqApiKey: '', isGroqKeyValid: false);
  }

  Future<bool> saveAndValidateNvidiaApiKey(String key) async {
    state = state.copyWith(isValidatingNvidiaKey: true);
    final storage = ref.read(secureStorageProvider);
    final nvidiaClient = ref.read(nvidiaClientProvider);

    final isValid = await nvidiaClient.validateApiKey(key);
    if (isValid || key.trim().isEmpty) {
      await storage.saveNvidiaApiKey(key);
      state = state.copyWith(
        nvidiaApiKey: key,
        isNvidiaKeyValid: isValid,
        isValidatingNvidiaKey: false,
      );
    } else {
      state = state.copyWith(
        isValidatingNvidiaKey: false,
        isNvidiaKeyValid: false,
      );
    }

    return isValid;
  }

  Future<void> removeNvidiaApiKey() async {
    final storage = ref.read(secureStorageProvider);
    await storage.deleteNvidiaApiKey();
    state = state.copyWith(nvidiaApiKey: '', isNvidiaKeyValid: false);
  }

  void setGroqDefaultModel(String modelId) =>
      state = state.copyWith(groqDefaultModel: modelId);
  void setNvidiaDefaultModel(String modelId) =>
      state = state.copyWith(nvidiaDefaultModel: modelId);
  void setThemeMode(String mode) => state = state.copyWith(themeMode: mode);
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
