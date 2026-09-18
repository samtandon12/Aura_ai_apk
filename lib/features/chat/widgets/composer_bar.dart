import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/attachment_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../prompts/widgets/prompt_picker_sheet.dart';

class ComposerBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final bool isGenerating;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final ValueChanged<PickedAttachment?> onAttachmentSelected;
  final PickedAttachment? currentAttachment;

  const ComposerBar({
    super.key,
    required this.controller,
    required this.isGenerating,
    required this.onSend,
    required this.onStop,
    required this.onAttachmentSelected,
    this.currentAttachment,
  });

  @override
  ConsumerState<ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends ConsumerState<ComposerBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    try {
      final attachmentService = ref.read(attachmentServiceProvider);
      final picked = await attachmentService.pickAttachment();
      if (picked != null) {
        widget.onAttachmentSelected(picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is FormatException ? e.message : 'Error picking file: $e',
            ),
            backgroundColor: AppColors.roseAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
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
                'Attach Context',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                  color: AppColors.violetAccent,
                ),
                title: const Text('Image / Screenshot'),
                subtitle: const Text('JPG, JPEG, PNG, WebP (Max 10MB)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAttachment();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                  color: AppColors.indigoAccent,
                ),
                title: const Text('Document / Code File'),
                subtitle: const Text('PDF, TXT, DOCX, CSV (Max 10MB)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAttachment();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.bookmark_outline_rounded,
                  color: AppColors.cyanAccent,
                ),
                title: const Text('Saved Prompt Library'),
                subtitle: const Text('Insert pre-written prompt templates'),
                onTap: () {
                  Navigator.pop(context);
                  PromptPickerSheet.show(
                    context,
                    onSelectPrompt: (promptText) {
                      widget.controller.text = promptText;
                    },
                  );
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
    final hasText = widget.controller.text.trim().isNotEmpty;
    final hasAttachment = widget.currentAttachment != null;
    final canSend = hasText || hasAttachment;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.currentAttachment != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.indigoAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.currentAttachment!.isImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              widget.currentAttachment!.file,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 44,
                                    height: 44,
                                    color: AppColors.surface,
                                    child: const Icon(
                                      Icons.image,
                                      color: AppColors.indigoAccent,
                                    ),
                                  ),
                            ),
                          )
                        else
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.indigoAccent.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.description_rounded,
                              color: AppColors.indigoAccent,
                              size: 24,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.currentAttachment!.fileName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(widget.currentAttachment!.size / 1024).toStringAsFixed(1)} KB • ${widget.currentAttachment!.extension.toUpperCase()}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => widget.onAttachmentSelected(null),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 12,
                          color: AppColors.amberAccent,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Attachment content will be transmitted to provider for processing',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment Button
                IconButton(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.attach_file_rounded),
                  color: widget.currentAttachment != null
                      ? AppColors.indigoAccent
                      : AppColors.textSecondary,
                  tooltip: 'Attach Context',
                ),
                const SizedBox(width: 4),

                // Multiline Composer Input
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask Aura anything...',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      fillColor: AppColors.surface,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.surfaceBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.surfaceBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppColors.indigoAccent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send or Stop Generation Button UI
                if (widget.isGenerating)
                  GestureDetector(
                    onTap: widget.onStop,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.roseAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.roseAccent,
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.stop_rounded,
                          color: AppColors.roseAccent,
                          size: 22,
                        ),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: canSend ? widget.onSend : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: canSend ? AppColors.primaryGradient : null,
                        color: canSend ? null : AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        boxShadow: canSend
                            ? [
                                BoxShadow(
                                  color: AppColors.indigoAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: canSend ? Colors.white : AppColors.textMuted,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
