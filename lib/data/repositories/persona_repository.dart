import 'package:drift/drift.dart';

import '../../models/ai_persona.dart';
import '../database/app_database.dart';

class PersonaRepository {
  final AppDatabase db;

  PersonaRepository(this.db);

  AIPersona _mapRowToPersona(Persona row) {
    return AIPersona(
      id: row.id,
      name: row.name,
      description: row.description,
      systemPrompt: row.systemPrompt,
      iconName: row.iconName,
      colorHex: row.colorHex,
      isDefault: row.isDefault,
      createdAt: row.createdAt,
    );
  }

  Future<void> _seedStartersIfNeeded() async {
    for (final starter in AIPersona.starterPersonas) {
      final existing = await (db.select(
        db.personas,
      )..where((p) => p.id.equals(starter.id))).getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.personas)
            .insert(
              PersonasCompanion.insert(
                id: starter.id,
                name: starter.name,
                description: starter.description,
                systemPrompt: starter.systemPrompt,
                iconName: Value(starter.iconName),
                colorHex: Value(starter.colorHex),
                isDefault: Value(starter.isDefault),
                createdAt: starter.createdAt,
              ),
            );
      }
    }
  }

  Future<List<AIPersona>> getPersonas() async {
    await _seedStartersIfNeeded();
    final query = db.select(db.personas)
      ..orderBy([
        (p) => OrderingTerm(expression: p.isDefault, mode: OrderingMode.desc),
        (p) => OrderingTerm(expression: p.createdAt, mode: OrderingMode.asc),
      ]);
    final rows = await query.get();
    return rows.map(_mapRowToPersona).toList();
  }

  Stream<List<AIPersona>> watchPersonas() {
    _seedStartersIfNeeded();
    final query = db.select(db.personas)
      ..orderBy([
        (p) => OrderingTerm(expression: p.isDefault, mode: OrderingMode.desc),
        (p) => OrderingTerm(expression: p.createdAt, mode: OrderingMode.asc),
      ]);
    return query.watch().map((rows) => rows.map(_mapRowToPersona).toList());
  }

  Future<AIPersona> createPersona({
    required String name,
    required String description,
    required String systemPrompt,
    String iconName = 'auto_awesome',
    String colorHex = '#6366F1',
  }) async {
    final id = 'persona-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final entry = PersonasCompanion.insert(
      id: id,
      name: name,
      description: description,
      systemPrompt: systemPrompt,
      iconName: Value(iconName),
      colorHex: Value(colorHex),
      isDefault: const Value(false),
      createdAt: now,
    );

    await db.into(db.personas).insert(entry);

    return AIPersona(
      id: id,
      name: name,
      description: description,
      systemPrompt: systemPrompt,
      iconName: iconName,
      colorHex: colorHex,
      isDefault: false,
      createdAt: now,
    );
  }

  Future<AIPersona> duplicatePersona(AIPersona source) async {
    return createPersona(
      name: '${source.name} (Copy)',
      description: source.description,
      systemPrompt: source.systemPrompt,
      iconName: source.iconName,
      colorHex: source.colorHex,
    );
  }

  Future<void> updatePersona(
    String id, {
    required String name,
    required String description,
    required String systemPrompt,
    String? iconName,
    String? colorHex,
  }) async {
    await (db.update(db.personas)..where((p) => p.id.equals(id))).write(
      PersonasCompanion(
        name: Value(name),
        description: Value(description),
        systemPrompt: Value(systemPrompt),
        iconName: iconName != null ? Value(iconName) : const Value.absent(),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
      ),
    );
  }

  Future<void> deletePersona(String id) async {
    // Only allow deletion of non-default custom personas
    await (db.delete(
      db.personas,
    )..where((p) => p.id.equals(id) & p.isDefault.equals(false))).go();
  }
}
