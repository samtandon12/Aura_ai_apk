class UserMemory {
  final String id;
  final String fact;
  final String? category;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserMemory({
    required this.id,
    required this.fact,
    this.category,
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  UserMemory copyWith({
    String? id,
    String? fact,
    String? category,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserMemory(
      id: id ?? this.id,
      fact: fact ?? this.fact,
      category: category ?? this.category,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
