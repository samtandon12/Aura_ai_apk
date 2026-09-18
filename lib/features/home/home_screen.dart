import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/app_providers.dart';
import 'widgets/chat_history_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(chatHistoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedModel = ref.watch(selectedModelProvider);

    final filteredSessions = history.where((session) {
      if (searchQuery.isEmpty) return true;
      return session.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          session.snippet.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    final pinnedSessions = filteredSessions.where((s) => s.isPinned).toList();
    final otherSessions = filteredSessions.where((s) => !s.isPinned).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header Branding & Settings Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.indigoAccent.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aura AI',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          Text(
                            'Personal Intelligence Companion',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.textPrimary,
                    ),
                    tooltip: 'Settings',
                    onPressed: () => context.go('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // "+ New Chat" Primary Action Button
              GestureDetector(
                onTap: () async {
                  final newId = await ref
                      .read(chatHistoryProvider.notifier)
                      .createNewSession(modelId: selectedModel.id);
                  ref.read(activeChatIdProvider.notifier).setActiveId(newId);
                  if (context.mounted) {
                    context.go('/chat/$newId');
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.indigoAccent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Start New Conversation',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),

              // Search Bar Input
              TextField(
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).setQuery(value);
                },
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            ref.read(searchQueryProvider.notifier).setQuery('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Chat History Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECENT CHATS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (history.isNotEmpty)
                    Text(
                      '${history.length} total',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Chat List / Empty State
              Expanded(
                child: filteredSessions.isEmpty
                    ? _buildEmptyState(context, searchQuery.isNotEmpty)
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          if (pinnedSessions.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0, left: 4),
                              child: Text(
                                'PINNED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.indigoAccent,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            ...pinnedSessions.map(
                              (s) => ChatHistoryTile(session: s),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (otherSessions.isNotEmpty) ...[
                            if (pinnedSessions.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0, left: 4),
                                child: Text(
                                  'OTHERS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ...otherSessions.map(
                              (s) => ChatHistoryTile(session: s),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Icon(
              isSearch
                  ? Icons.search_off_rounded
                  : Icons.chat_bubble_outline_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No conversations found' : 'No chat history yet',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Try searching for a different keyword'
                : 'Tap "Start New Conversation" to begin chatting with Aura',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
