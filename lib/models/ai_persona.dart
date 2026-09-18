import 'package:flutter/material.dart';

class AIPersona {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final String iconName;
  final String colorHex;
  final bool isDefault;
  final DateTime createdAt;

  const AIPersona({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.iconName = 'auto_awesome',
    this.colorHex = '#6366F1',
    this.isDefault = false,
    required this.createdAt,
  });

  AIPersona copyWith({
    String? id,
    String? name,
    String? description,
    String? systemPrompt,
    String? iconName,
    String? colorHex,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AIPersona(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  IconData get iconData {
    switch (iconName) {
      case 'code':
        return Icons.code_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'create':
      case 'edit_note':
        return Icons.edit_note_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'auto_awesome':
      default:
        return Icons.auto_awesome;
    }
  }

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  static final AIPersona defaultPersona = AIPersona(
    id: 'persona-default',
    name: 'Aura Default',
    description: 'Balanced, helpful, and precise general AI assistant',
    systemPrompt: 'You are Aura, an intelligent, empathetic, and highly capable AI assistant. Provide clear, accurate, structured, and helpful responses.',
    iconName: 'auto_awesome',
    colorHex: '#6366F1',
    isDefault: true,
    createdAt: DateTime(2026, 1, 1),
  );

  static final List<AIPersona> starterPersonas = [
    defaultPersona,
    AIPersona(
      id: 'persona-architect',
      name: 'Software Architect',
      description:
          'Focuses on clean code, design patterns, scale & performance',
      systemPrompt: 'You are a Senior Principal Software Architect. Focus on modularity, clean architecture, security, scalability, performance, and best engineering practices. Provide code snippets with idiomatic quality.',
      iconName: 'code',
      colorHex: '#8B5CF6',
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    AIPersona(
      id: 'persona-creative',
      name: 'Creative Writer',
      description: 'Imaginative, articulate, engaging storytelling & prose',
      systemPrompt: 'You are an award-winning creative writer and storyteller. Craft vivid, engaging, imaginative text with expressive vocabulary and evocative descriptions.',
      iconName: 'edit_note',
      colorHex: '#EC4899',
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    AIPersona(
      id: 'persona-concise',
      name: 'Concise Engineer',
      description: 'Direct, minimal fluff, precise answers & quick snippets',
      systemPrompt: 'You are a no-nonsense engineering expert. Be extremely concise, direct, and factual. Skip introductory pleasantries and deliver accurate code snippets and brief bullet points.',
      iconName: 'terminal',
      colorHex: '#10B981',
      isDefault: true,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];
}
