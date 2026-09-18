import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/chat_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/memory/memory_screen.dart';
import '../../features/persona/persona_screen.dart';
import '../../features/privacy/privacy_screen.dart';
import '../../features/prompts/prompt_library_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final id = state.uri.queryParameters['id'];
        final extraText = state.extra as String?;
        return ChatScreen(sessionId: id, initialPrompt: extraText);
      },
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return ChatScreen(sessionId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(path: '/memory', builder: (context, state) => const MemoryScreen()),
    GoRoute(
      path: '/personas',
      builder: (context, state) => const PersonaScreen(),
    ),
    GoRoute(
      path: '/prompts',
      builder: (context, state) => const PromptLibraryScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
);
