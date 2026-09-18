import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/saved_prompt.dart';
import '../../providers/app_providers.dart';

class PromptLibraryScreen extends ConsumerStatefulWidget {
  const PromptLibraryScreen({super.key});

  @override
  ConsumerState<PromptLibraryScreen> createState() =>
      _PromptLibraryScreenState();
}

class _PromptLibraryScreenState extends ConsumerState<PromptLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Coding',
    'Learning',
    'Writing',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditPromptDialog([SavedPrompt? existing]) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(
      text: existing?.content ?? '',
    );
    String category = existing?.category ?? 'General';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.surfaceBorder),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.bookmark_outline_rounded,
                    color: AppColors.indigoAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    existing == null ? 'Create Saved Prompt' : 'Edit Prompt',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Title',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Code Review & Refactor',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Category',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: category,
                            isExpanded: true,
                            dropdownColor: AppColors.surfaceLight,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                            items: ['Coding', 'Learning', 'Writing', 'General']
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => category = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Prompt Content',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: contentController,
                        maxLines: 5,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter your prompt template text...',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter prompt content';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final title = titleController.text.trim();
                      final content = contentController.text.trim();

                      final repo = ref.read(promptRepositoryProvider);
                      if (existing == null) {
                        await repo.createPrompt(
                          title: title,
                          content: content,
                          category: category,
                        );
                      } else {
                        await repo.updatePrompt(
                          existing.id,
                          title: title,
                          content: content,
                          category: category,
                        );
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(existing == null ? 'Save Prompt' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(SavedPrompt prompt) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: AppColors.roseAccent),
              SizedBox(width: 8),
              Text(
                'Delete Prompt?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${prompt.title}"? This cannot be undone.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
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
                backgroundColor: AppColors.roseAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await ref
                    .read(promptRepositoryProvider)
                    .deletePrompt(prompt.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final promptsAsync = ref.watch(promptsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Prompt Library',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: 'Create Prompt',
            onPressed: () => _showAddEditPromptDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Category Filter Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search prompt templates...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppColors.indigoAccent,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),

          // Prompts List
          Expanded(
            child: promptsAsync.when(
              data: (allPrompts) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = allPrompts.where((p) {
                  final matchesCat =
                      _selectedCategory == 'All' ||
                      p.category == _selectedCategory;
                  final matchesQuery =
                      query.isEmpty ||
                      p.title.toLowerCase().contains(query) ||
                      p.content.toLowerCase().contains(query);
                  return matchesCat && matchesQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bookmark_border_rounded,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Saved Prompts Found',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            query.isNotEmpty ? 'No templates match "$query"' : 'Tap "+" to save your favorite prompt templates.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final prompt = filtered[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.indigoAccent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  prompt.category,
                                  style: const TextStyle(
                                    color: AppColors.indigoAccent,
                                    fontSize: 10,
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
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              prompt.content,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text(
                                  'Copy',
                                  style: TextStyle(fontSize: 11),
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: prompt.content),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Prompt copied to clipboard',
                                      ),
                                      duration: Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.indigoAccent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                icon: const Icon(Icons.send_rounded, size: 14),
                                label: const Text(
                                  'Use in Chat',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  context.go('/chat', extra: prompt.content);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () =>
                                    _showAddEditPromptDialog(prompt),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: AppColors.roseAccent,
                                ),
                                onPressed: () => _confirmDelete(prompt),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 200.ms);
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
      ),
    );
  }
}
