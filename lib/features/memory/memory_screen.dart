import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_memory.dart';
import '../../providers/app_providers.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  void _showAddEditMemoryDialog([UserMemory? existingMemory]) {
    final factController = TextEditingController(
      text: existingMemory?.fact ?? '',
    );
    final categoryController = TextEditingController(
      text: existingMemory?.category ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.psychology_outlined,
                color: AppColors.indigoAccent,
              ),
              const SizedBox(width: 10),
              Text(
                existingMemory == null ? 'Add Personal Memory' : 'Edit Memory',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What fact should Aura remember about you?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: factController,
                  maxLines: 3,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                  ),
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. I prefer Flutter for cross-platform app dev.',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a memory fact';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Category / Tag (Optional)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: categoryController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Work, Preference, Personal',
                  ),
                ),
              ],
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
                  final fact = factController.text.trim();
                  final category = categoryController.text.trim().isNotEmpty
                      ? categoryController.text.trim()
                      : null;

                  final repo = ref.read(memoryRepositoryProvider);
                  if (existingMemory == null) {
                    await repo.addMemory(fact: fact, category: category);
                  } else {
                    await repo.updateMemory(
                      existingMemory.id,
                      fact: fact,
                      category: category,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: Text(existingMemory == null ? 'Save Memory' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(UserMemory memory) {
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
                'Delete Memory?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${memory.fact}"? This action cannot be undone.',
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
                    .read(memoryRepositoryProvider)
                    .deleteMemory(memory.id);
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
    final isMemoryEnabled = ref.watch(isMemoryEnabledProvider);
    final memoriesAsync = ref.watch(memoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Personal Memory',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: 'Add Memory',
            onPressed: () => _showAddEditMemoryDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Global Memory Toggle Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.indigoAccent.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: AppColors.indigoAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Memory Enabled',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Use saved facts to personalize responses',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isMemoryEnabled,
                    activeTrackColor: AppColors.indigoAccent,
                    onChanged: (val) {
                      ref
                          .read(isMemoryEnabledProvider.notifier)
                          .setEnabled(val);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),
            const SizedBox(height: 16),

            // Privacy Callout Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.indigoAccent.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: AppColors.indigoAccent,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Transparency Notice',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Memories are stored locally in your SQLite database. When memory is enabled, active facts are transmitted with prompt requests to your selected AI provider.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 50.ms, duration: 250.ms),
            const SizedBox(height: 24),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SAVED MEMORIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddEditMemoryDialog(),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add Fact',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Memories List
            memoriesAsync.when(
              data: (memories) {
                if (memories.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.psychology_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Memories Saved Yet',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap "Add Fact" above to give Aura context about your preferences or workflow.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: memories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final mem = memories[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Switch.adaptive(
                            value: mem.isEnabled,
                            activeTrackColor: AppColors.indigoAccent,
                            onChanged: (val) {
                              ref
                                  .read(memoryRepositoryProvider)
                                  .toggleMemory(mem.id, val);
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mem.fact,
                                  style: TextStyle(
                                    color: mem.isEnabled
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    decoration: mem.isEnabled
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                                if (mem.category != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      mem.category!,
                                      style: const TextStyle(
                                        color: AppColors.indigoAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => _showAddEditMemoryDialog(mem),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.roseAccent,
                            ),
                            onPressed: () => _confirmDelete(mem),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.indigoAccent),
              ),
              error: (err, stack) => Text(
                'Error loading memories: $err',
                style: const TextStyle(color: AppColors.roseAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
