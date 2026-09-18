import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/attachment_service.dart';
import '../../core/services/export_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_session.dart';
import '../../providers/app_providers.dart';
import 'widgets/composer_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/model_selector_sheet.dart';
import 'widgets/welcome_view.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String? initialPrompt;

  const ChatScreen({super.key, this.sessionId, this.initialPrompt});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PickedAttachment? _selectedAttachment;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null) {
      _composerController.text = widget.initialPrompt!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.sessionId != null) {
        ref.read(activeChatIdProvider.notifier).setActiveId(widget.sessionId);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage([String? textOverride]) async {
    final rawText = textOverride ?? _composerController.text.trim();
    final attachment = _selectedAttachment;

    if (rawText.isEmpty && attachment == null) return;

    final text = rawText.isNotEmpty
        ? rawText
        : (attachment?.isImage == true
              ? 'Please analyze this attached image.'
              : 'Please analyze this attached document.');

    final currentModel = ref.read(selectedModelProvider);
    String? activeId = ref.read(activeChatIdProvider);

    // If no active session, create a new session
    if (activeId == null) {
      activeId = await ref
          .read(chatHistoryProvider.notifier)
          .createNewSession(
            modelId: currentModel.id,
            title: text.length > 30 ? '${text.substring(0, 30)}...' : text,
          );
      ref.read(activeChatIdProvider.notifier).setActiveId(activeId);
    }

    _composerController.clear();
    setState(() {
      _selectedAttachment = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Trigger user message and real AI response streaming
    await ref
        .read(chatHistoryProvider.notifier)
        .sendUserMessageAndStreamResponse(
          sessionId: activeId,
          content: text,
          attachmentName: attachment?.fileName,
          localPath: attachment?.file.path,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _showExportDialog(ChatSession session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Conversation',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose file format to share or save',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                  color: AppColors.indigoAccent,
                ),
                title: const Text('Plain Text (.txt)'),
                subtitle: const Text('Human-readable formatted text file'),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(exportServiceProvider)
                      .shareChatExport(session, ExportFormat.txt);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.code_rounded,
                  color: AppColors.violetAccent,
                ),
                title: const Text('Markdown (.md)'),
                subtitle: const Text(
                  'Formatted headers, code blocks & bubbles',
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(exportServiceProvider)
                      .shareChatExport(session, ExportFormat.markdown);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.data_object_rounded,
                  color: AppColors.cyanAccent,
                ),
                title: const Text('JSON (.json)'),
                subtitle: const Text(
                  'Structured JSON object with message history',
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(exportServiceProvider)
                      .shareChatExport(session, ExportFormat.json);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeChat = ref.watch(activeChatProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final activePersona = ref.watch(activePersonaProvider);
    final isGenerating = ref.watch(isGeneratingProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/'),
        ),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Model Selector Pill
              GestureDetector(
                onTap: () => ModelSelectorSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: selectedModel.badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selectedModel.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Active Persona Switcher Pill
              GestureDetector(
                onTap: () => context.push('/personas'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: activePersona.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: activePersona.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activePersona.iconData,
                        size: 12,
                        color: activePersona.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activePersona.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: activePersona.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (activeChat != null && activeChat.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              tooltip: 'Export Chat',
              onPressed: () => _showExportDialog(activeChat),
            ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, size: 20),
            tooltip: 'New Chat',
            onPressed: () async {
              final newId = await ref
                  .read(chatHistoryProvider.notifier)
                  .createNewSession(modelId: selectedModel.id);
              ref.read(activeChatIdProvider.notifier).setActiveId(newId);
              if (context.mounted) {
                context.go('/chat/$newId');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Chat Body
          Expanded(
            child: activeChat == null || activeChat.messages.isEmpty
                ? WelcomeView(
                    currentModel: selectedModel,
                    onSelectPrompt: (prompt) => _sendMessage(prompt),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: activeChat.messages.length,
                    itemBuilder: (context, index) {
                      final message = activeChat.messages[index];
                      return MessageBubble(message: message);
                    },
                  ),
          ),

          // Composer Bar
          ComposerBar(
            controller: _composerController,
            isGenerating: isGenerating,
            onSend: () => _sendMessage(),
            onStop: () {
              ref.read(chatHistoryProvider.notifier).stopGeneration();
            },
            currentAttachment: _selectedAttachment,
            onAttachmentSelected: (filename) {
              setState(() {
                _selectedAttachment = filename;
              });
            },
          ),
        ],
      ),
    );
  }
}
