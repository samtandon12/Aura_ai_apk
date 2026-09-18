import 'package:aura_ai/data/database/app_database.dart';
import 'package:aura_ai/data/repositories/prompt_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PromptRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PromptRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PromptRepository SQLite Persistence Tests', () {
    test('Get prompts seeds starter prompts on first query', () async {
      final prompts = await repo.getPrompts();
      expect(prompts.length, greaterThanOrEqualTo(3));
      expect(prompts.any((p) => p.title.contains('Code Audit')), isTrue);
    });

    test('Create, search, and update saved prompt', () async {
      await repo.createPrompt(
        title: 'Flutter Widget Refactor',
        content: 'Refactor the following StatelessWidget to StatefulWidget with animation:',
        category: 'Coding',
      );

      final searchResult = await repo.getPrompts(queryStr: 'StatelessWidget');
      expect(searchResult.length, equals(1));
      expect(searchResult.first.title, equals('Flutter Widget Refactor'));

      await repo.updatePrompt(
        searchResult.first.id,
        title: 'Updated Widget Refactor',
        content: 'Updated content string',
        category: 'Coding',
      );

      final updated = await repo.getPrompts(queryStr: 'Updated');
      expect(updated.length, equals(1));
      expect(updated.first.content, equals('Updated content string'));
    });

    test('Filter prompts by category and delete prompt', () async {
      final p1 = await repo.createPrompt(
        title: 'Story Generator',
        content: 'Write a sci-fi story about AI',
        category: 'Writing',
      );

      final writingPrompts = await repo.getPrompts(categoryFilter: 'Writing');
      expect(writingPrompts.any((p) => p.id == p1.id), isTrue);

      await repo.deletePrompt(p1.id);
      final afterDelete = await repo.getPrompts(categoryFilter: 'Writing');
      expect(afterDelete.any((p) => p.id == p1.id), isFalse);
    });
  });
}
