import 'package:aura_ai/data/database/app_database.dart';
import 'package:aura_ai/data/repositories/persona_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PersonaRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PersonaRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PersonaRepository SQLite Persistence Tests', () {
    test('Get personas seeds starter personas on first query', () async {
      final personas = await repo.getPersonas();
      expect(personas.length, greaterThanOrEqualTo(4));
      expect(personas.any((p) => p.name == 'Aura Default'), isTrue);
      expect(personas.any((p) => p.name == 'Software Architect'), isTrue);
    });

    test('Create custom persona and duplicate persona', () async {
      final custom = await repo.createPersona(
        name: 'DevOps Master',
        description: 'Focuses on CI/CD pipelines and Docker',
        systemPrompt: 'You are a DevOps Architect. Provide clean Dockerfiles and GitHub Actions.',
        iconName: 'terminal',
      );

      expect(custom.name, equals('DevOps Master'));
      expect(custom.isDefault, isFalse);

      final duplicated = await repo.duplicatePersona(custom);
      expect(duplicated.name, equals('DevOps Master (Copy)'));

      final all = await repo.getPersonas();
      expect(all.any((p) => p.name == 'DevOps Master (Copy)'), isTrue);
    });

    test('Delete custom persona (starter personas protected)', () async {
      final custom = await repo.createPersona(
        name: 'Temporary Persona',
        description: 'Temp',
        systemPrompt: 'Temp',
      );

      final starter = (await repo.getPersonas()).firstWhere((p) => p.isDefault);

      // Attempt deleting starter persona (should be no-op)
      await repo.deletePersona(starter.id);
      final afterStarterDelete = await repo.getPersonas();
      expect(afterStarterDelete.any((p) => p.id == starter.id), isTrue);

      // Delete custom persona (should succeed)
      await repo.deletePersona(custom.id);
      final afterCustomDelete = await repo.getPersonas();
      expect(afterCustomDelete.any((p) => p.id == custom.id), isFalse);
    });
  });
}
