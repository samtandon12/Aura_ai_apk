import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/ai_persona.dart';
import '../../providers/app_providers.dart';

class PersonaScreen extends ConsumerStatefulWidget {
  const PersonaScreen({super.key});

  @override
  ConsumerState<PersonaScreen> createState() => _PersonaScreenState();
}

class _PersonaScreenState extends ConsumerState<PersonaScreen> {
  void _showAddEditPersonaDialog([AIPersona? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController = TextEditingController(
      text: existing?.description ?? '',
    );
    final promptController = TextEditingController(
      text: existing?.systemPrompt ?? '',
    );
    String selectedIcon = existing?.iconName ?? 'auto_awesome';
    String selectedColorHex = existing?.colorHex ?? '#6366F1';
    final formKey = GlobalKey<FormState>();

    final icons = [
      'auto_awesome',
      'code',
      'edit_note',
      'terminal',
      'psychology',
      'science',
    ];

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
                    Icons.person_pin_rounded,
                    color: AppColors.indigoAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    existing == null ? 'Create Custom Persona' : 'Edit Persona',
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
                        'Persona Name',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Senior Flutter Developer',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a persona name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Short Description',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Focuses on Flutter architecture & state management',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'System Instruction / Role Prompt',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: promptController,
                        maxLines: 4,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'You are an expert Flutter engineer. Provide clean, well-documented code snippets using Riverpod.',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a system instruction';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Choose Icon',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: icons.map((iconName) {
                          final isSelected = selectedIcon == iconName;
                          return InkWell(
                            onTap: () {
                              setDialogState(() => selectedIcon = iconName);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.indigoAccent.withValues(
                                        alpha: 0.2,
                                      )
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.indigoAccent
                                      : Colors.transparent,
                                ),
                              ),
                              child: Icon(
                                AIPersona(
                                  id: '',
                                  name: '',
                                  description: '',
                                  systemPrompt: '',
                                  iconName: iconName,
                                  createdAt: DateTime.now(),
                                ).iconData,
                                color: isSelected
                                    ? AppColors.indigoAccent
                                    : AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                          );
                        }).toList(),
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
                      final name = nameController.text.trim();
                      final desc = descController.text.trim();
                      final prompt = promptController.text.trim();

                      final repo = ref.read(personaRepositoryProvider);
                      if (existing == null) {
                        final created = await repo.createPersona(
                          name: name,
                          description: desc,
                          systemPrompt: prompt,
                          iconName: selectedIcon,
                          colorHex: selectedColorHex,
                        );
                        ref
                            .read(activePersonaProvider.notifier)
                            .setPersona(created);
                      } else {
                        await repo.updatePersona(
                          existing.id,
                          name: name,
                          description: desc,
                          systemPrompt: prompt,
                          iconName: selectedIcon,
                          colorHex: selectedColorHex,
                        );
                        // Update active persona if currently selected
                        final active = ref.read(activePersonaProvider);
                        if (active.id == existing.id) {
                          ref
                              .read(activePersonaProvider.notifier)
                              .setPersona(
                                existing.copyWith(
                                  name: name,
                                  description: desc,
                                  systemPrompt: prompt,
                                  iconName: selectedIcon,
                                  colorHex: selectedColorHex,
                                ),
                              );
                        }
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(
                    existing == null ? 'Create Persona' : 'Save Changes',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(AIPersona persona) {
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
                'Delete Persona?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${persona.name}"? Starter personas cannot be deleted, but custom personas can be removed anytime.',
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
                    .read(personaRepositoryProvider)
                    .deletePersona(persona.id);
                final active = ref.read(activePersonaProvider);
                if (active.id == persona.id) {
                  ref
                      .read(activePersonaProvider.notifier)
                      .setPersona(AIPersona.defaultPersona);
                }
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
    final activePersona = ref.watch(activePersonaProvider);
    final personasAsync = ref.watch(personasStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Custom Personas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: 'Create Persona',
            onPressed: () => _showAddEditPersonaDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Persona Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.indigoAccent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigoAccent.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: activePersona.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activePersona.iconData,
                      color: activePersona.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              activePersona.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldAccent.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: AppColors.emeraldAccent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activePersona.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),
            const SizedBox(height: 24),

            // Personas List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AVAILABLE PERSONAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddEditPersonaDialog(),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Create Custom',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Personas List
            personasAsync.when(
              data: (personas) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: personas.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final persona = personas[index];
                    final isActive = persona.id == activePersona.id;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppColors.indigoAccent
                              : AppColors.surfaceBorder,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: persona.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  persona.iconData,
                                  color: persona.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          persona.name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        if (persona.isDefault) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceLight,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'STARTER',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      persona.description,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isActive
                                      ? AppColors.indigoAccent
                                      : AppColors.surfaceLight,
                                  foregroundColor: isActive
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  ref
                                      .read(activePersonaProvider.notifier)
                                      .setPersona(persona);
                                },
                                child: Text(
                                  isActive ? 'Active' : 'Select',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
                              persona.systemPrompt,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                  'Duplicate',
                                  style: TextStyle(fontSize: 11),
                                ),
                                onPressed: () async {
                                  await ref
                                      .read(personaRepositoryProvider)
                                      .duplicatePersona(persona);
                                },
                              ),
                              if (!persona.isDefault) ...[
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.indigoAccent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Edit',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  onPressed: () =>
                                      _showAddEditPersonaDialog(persona),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.roseAccent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  onPressed: () => _confirmDelete(persona),
                                ),
                              ],
                            ],
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
                'Error loading personas: $err',
                style: const TextStyle(color: AppColors.roseAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
