import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/chat_message.dart';
import '../../../providers/app_providers.dart';

class MessageBubble extends ConsumerWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  bool get isUser => message.sender == MessageSender.user;

  bool _isImageFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  Widget _buildAttachmentWidget(BuildContext context, bool isUser) {
    final name = message.attachmentName!;
    final path = message.attachmentPath;
    final isImg = _isImageFile(name);

    if (isImg && path != null && File(path).existsSync()) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.surfaceBorder,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildDocumentBadge(name, isUser),
          ),
        ),
      );
    }

    return _buildDocumentBadge(name, isUser);
  }

  Widget _buildDocumentBadge(String name, bool isUser) {
    final ext = name.split('.').last.toLowerCase();
    final icon = ext == 'pdf'
        ? Icons.picture_as_pdf_rounded
        : (ext == 'csv'
              ? Icons.table_chart_outlined
              : Icons.description_outlined);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.2)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: isUser
            ? null
            : Border.all(color: AppColors.indigoAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isUser ? Colors.white : AppColors.indigoAccent,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGenerating = message.status == MessageStatus.generating;
    final isError = message.status == MessageStatus.error;

    return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.indigoAccent.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82,
                      ),
                      decoration: BoxDecoration(
                        gradient: isUser ? AppColors.primaryGradient : null,
                        color: isUser
                            ? null
                            : isError
                            ? AppColors.roseAccent.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        border: isUser
                            ? null
                            : Border.all(
                                color: isError
                                    ? AppColors.roseAccent.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.surfaceBorder,
                                width: 1,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.attachmentName != null)
                            _buildAttachmentWidget(context, isUser),
                          if (message.content.isNotEmpty)
                            SelectableText(
                              message.content,
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 14.5,
                                height: 1.45,
                              ),
                            ),
                          if (isGenerating && message.content.isEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.indigoAccent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Aura is thinking...',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          if (isError) ...[
                            if (message.content.isNotEmpty)
                              const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 16,
                                  color: AppColors.roseAccent,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    message.errorMessage ?? 'An error occurred while generating response.',
                                    style: const TextStyle(
                                      color: AppColors.roseAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.roseAccent
                                    .withValues(alpha: 0.15),
                                foregroundColor: AppColors.roseAccent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(chatHistoryProvider.notifier)
                                    .retryMessage(
                                      message.sessionId,
                                      message.id,
                                    );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(
                  left: isUser ? 0 : 42,
                  right: isUser ? 4 : 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUser && message.modelId != null) ...[
                      Text(
                        message.modelId!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '•',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    if (message.content.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: message.content),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Message copied to clipboard'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.copy,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.1, end: 0, duration: 250.ms);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
