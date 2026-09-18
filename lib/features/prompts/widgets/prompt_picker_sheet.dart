import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/app_providers.dart';

class PromptPickerSheet extends ConsumerWidget {
  final ValueChanged<String> onSelectPrompt;
  final ValueChanged<String>? onSelectAndSendPrompt;

  const PromptPickerSheet({
    super.key,
    required this.onSelectPrompt,
    this.onSelectAndSendPrompt,
  });

  static void show(
    BuildContext context, {
    required ValueChanged<String> onSelectPrompt,
    ValueChanged<String>? onSelectAndSendPrompt,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => PromptPickerSheet(
          onSelectPrompt: onSelectPrompt,
          onSelectAndSendPrompt: onSelectAndSendPrompt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promptsAsync = ref.watch(promptsStreamProvider);

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.surfaceBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.bookmark_outline_rounded,
                color: AppColors.indigoAccent,
              ),
              const SizedBox(width: 10),
              const Text(
                'Insert Saved Prompt',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.surfaceBorder, height: 1),

        // List of Prompts
        Expanded(
          child: promptsAsync.when(
            data: (prompts) {
              if (prompts.isEmpty) {
                return const Center(
                  child: Text(
                    'No saved prompts found in library.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: prompts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final prompt = prompts[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.indigoAccent.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              prompt.category,
                              style: const TextStyle(
                                color: AppColors.indigoAccent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              prompt.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          prompt.content,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () {
                        onSelectPrompt(prompt.content);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.indigoAccent),
            ),
            error: (err, stack) => Text(
              'Error loading prompts: $err',
              style: const TextStyle(color: AppColors.roseAccent),
            ),
          ),
        ),
      ],
    );
  }
}
