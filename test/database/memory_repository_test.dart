import 'package:aura_ai/data/database/app_database.dart';
import 'package:aura_ai/data/repositories/memory_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MemoryRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MemoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MemoryRepository SQLite Persistence Tests', () {
    test('Add memory fact and retrieve memories', () async {
      final mem = await repo.addMemory(
        fact: 'User prefers Flutter & Dart for cross-platform app dev.',
        category: 'Preference',
      );

      expect(mem.fact, contains('Flutter & Dart'));
      expect(mem.isEnabled, isTrue);

      final memories = await repo.getMemories();
      expect(memories.length, equals(1));
      expect(memories.first.category, equals('Preference'));
    });

    test('Toggle memory isEnabled state', () async {
      final mem = await repo.addMemory(
        fact: 'User works in UTC+5:30 timezone.',
      );
      expect(mem.isEnabled, isTrue);

      await repo.toggleMemory(mem.id, false);

      final activeBefore = await repo.getActiveMemories();
      expect(activeBefore.isEmpty, isTrue);

      await repo.toggleMemory(mem.id, true);

      final activeAfter = await repo.getActiveMemories();
      expect(activeAfter.length, equals(1));
    });

    test('Update and delete memory', () async {
      final mem = await repo.addMemory(fact: 'Initial fact text');

      await repo.updateMemory(
        mem.id,
        fact: 'Updated fact text',
        category: 'UpdatedCategory',
      );

      final updatedList = await repo.getMemories();
      expect(updatedList.first.fact, equals('Updated fact text'));
      expect(updatedList.first.category, equals('UpdatedCategory'));

      await repo.deleteMemory(mem.id);

      final finalCount = await repo.getMemories();
      expect(finalCount.isEmpty, isTrue);
    });
  });
}
