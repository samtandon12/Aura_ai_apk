import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/chat_session.dart';
import '../../../providers/app_providers.dart';

class ChatHistoryTile extends ConsumerWidget {
  final ChatSession session;

  const ChatHistoryTile({super.key, required this.session});

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: session.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
          title: const Text(
            'Rename Conversation',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Enter new chat title...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigoAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  ref
                      .read(chatHistoryProvider.notifier)
                      .renameSession(session.id, newTitle);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.isPinned
              ? AppColors.indigoAccent.withValues(alpha: 0.4)
              : AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(activeChatIdProvider.notifier).setActiveId(session.id);
            context.go('/chat/${session.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: session.isPinned
                        ? AppColors.indigoAccent.withValues(alpha: 0.15)
                        : AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    session.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: session.isPinned
                        ? AppColors.indigoAccent
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Snippet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(session.lastUpdatedAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Popup menu actions
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  color: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'rename') {
                      _showRenameDialog(context, ref);
                    } else if (value == 'pin') {
                      ref
                          .read(chatHistoryProvider.notifier)
                          .togglePin(session.id);
                    } else if (value == 'delete') {
                      ref
                          .read(chatHistoryProvider.notifier)
                          .deleteSession(session.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(width: 10),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(
                            session.isPinned
                                ? Icons.push_pin_outlined
                                : Icons.push_pin,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 10),
                          Text(session.isPinned ? 'Unpin' : 'Pin to top'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: AppColors.roseAccent,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.roseAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
