import 'package:drift/drift.dart';

import '../../models/saved_prompt.dart';
import '../database/app_database.dart';

class PromptRepository {
  final AppDatabase db;

  PromptRepository(this.db);

  SavedPrompt _mapRowToPrompt(Prompt row) {
    return SavedPrompt(
      id: row.id,
      title: row.title,
      content: row.content,
      category: row.category,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<void> _seedStartersIfNeeded() async {
    for (final starter in SavedPrompt.starterPrompts) {
      final existing = await (db.select(
        db.prompts,
      )..where((p) => p.id.equals(starter.id))).getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.prompts)
            .insert(
              PromptsCompanion.insert(
                id: starter.id,
                title: starter.title,
                content: starter.content,
                category: Value(starter.category),
                createdAt: starter.createdAt,
                updatedAt: starter.updatedAt,
              ),
            );
      }
    }
  }

  Future<List<SavedPrompt>> getPrompts({
    String queryStr = '',
    String categoryFilter = 'All',
  }) async {
    await _seedStartersIfNeeded();
    final query = db.select(db.prompts)
      ..orderBy([
        (p) => OrderingTerm(expression: p.updatedAt, mode: OrderingMode.desc),
      ]);

    if (queryStr.trim().isNotEmpty) {
      final term = '%${queryStr.trim()}%';
      query.where((p) => p.title.like(term) | p.content.like(term));
    }

    if (categoryFilter != 'All') {
      query.where((p) => p.category.equals(categoryFilter));
    }

    final rows = await query.get();
    return rows.map(_mapRowToPrompt).toList();
  }

  Stream<List<SavedPrompt>> watchPrompts({
    String queryStr = '',
    String categoryFilter = 'All',
  }) {
    _seedStartersIfNeeded();
    final query = db.select(db.prompts)
      ..orderBy([
        (p) => OrderingTerm(expression: p.updatedAt, mode: OrderingMode.desc),
      ]);

    if (queryStr.trim().isNotEmpty) {
      final term = '%${queryStr.trim()}%';
      query.where((p) => p.title.like(term) | p.content.like(term));
    }

    if (categoryFilter != 'All') {
      query.where((p) => p.category.equals(categoryFilter));
    }

    return query.watch().map((rows) => rows.map(_mapRowToPrompt).toList());
  }

  Future<SavedPrompt> createPrompt({
    required String title,
    required String content,
    String category = 'General',
  }) async {
    final id = 'prompt-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final entry = PromptsCompanion.insert(
      id: id,
      title: title,
      content: content,
      category: Value(category),
      createdAt: now,
      updatedAt: now,
    );

    await db.into(db.prompts).insert(entry);

    return SavedPrompt(
      id: id,
      title: title,
      content: content,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updatePrompt(
    String id, {
    required String title,
    required String content,
    required String category,
  }) async {
    final now = DateTime.now();
    await (db.update(db.prompts)..where((p) => p.id.equals(id))).write(
      PromptsCompanion(
        title: Value(title),
        content: Value(content),
        category: Value(category),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deletePrompt(String id) async {
    await (db.delete(db.prompts)..where((p) => p.id.equals(id))).go();
  }
}
