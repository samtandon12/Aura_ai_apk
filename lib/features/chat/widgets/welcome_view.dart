import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/ai_model.dart';

class WelcomeView extends StatelessWidget {
  final AIModel currentModel;
  final ValueChanged<String> onSelectPrompt;

  const WelcomeView({
    super.key,
    required this.currentModel,
    required this.onSelectPrompt,
  });

  static const List<Map<String, String>> _prompts = [
    {
      'icon': 'code',
      'title': 'Flutter Architecture',
      'prompt': 'Write a clean Riverpod + GoRouter state management boilerplate for Flutter.',
    },
    {
      'icon': 'science',
      'title': 'Quantum Physics',
      'prompt': 'Explain quantum superposition and entanglement in simple everyday analogies.',
    },
    {
      'icon': 'email',
      'title': 'Executive Communication',
      'prompt': 'Draft a concise email proposing an AI infrastructure upgrade to leadership.',
    },
    {
      'icon': 'lightbulb',
      'title': 'Product Ideation',
      'prompt': 'Brainstorm 5 unique features for a privacy-first mobile AI assistant.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ambient Aura Logo Badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigoAccent.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 36),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Aura AI',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: currentModel.badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Powered by ${currentModel.name}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 36),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PROMPT STARTERS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.35,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _prompts.length,
              itemBuilder: (context, index) {
                final item = _prompts[index];
                final IconData iconData = _getIconData(item['icon']!);

                return _buildStarterCard(
                  context,
                  title: item['title']!,
                  prompt: item['prompt']!,
                  icon: iconData,
                  delayMs: 350 + (index * 50),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterCard(
    BuildContext context, {
    required String title,
    required String prompt,
    required IconData icon,
    required int delayMs,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onSelectPrompt(prompt),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.indigoAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.indigoAccent),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delayMs.ms).slideY(begin: 0.1, end: 0);
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'code':
        return Icons.code_rounded;
      case 'science':
        return Icons.science_outlined;
      case 'email':
        return Icons.mark_email_read_outlined;
      case 'lightbulb':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}
