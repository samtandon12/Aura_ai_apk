class SavedPrompt {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedPrompt({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'General',
    required this.createdAt,
    required this.updatedAt,
  });

  SavedPrompt copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedPrompt(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static final List<SavedPrompt> starterPrompts = [
    SavedPrompt(
      id: 'prompt-code-audit',
      title: 'Code Audit & Security Review',
      content: 'Please audit the following code for bugs, race conditions, memory leaks, performance bottlenecks, and security vulnerabilities:\n\n```\n[Insert Code Here]\n```',
      category: 'Coding',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    SavedPrompt(
      id: 'prompt-explain-concept',
      title: 'Explain Complex Concept',
      content: 'Explain the following concept step-by-step with clear real-world analogies, high-level architecture diagram in Mermaid, and a minimal working code example:\n\nTopic: ',
      category: 'Learning',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    SavedPrompt(
      id: 'prompt-refactor-clean',
      title: 'Refactor & Clean Architecture',
      content: 'Refactor the following Dart/Flutter code to follow clean architecture, modern Riverpod state management, and strict immutability:\n\n',
      category: 'Coding',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];
}
