import 'package:drift/drift.dart';

import '../../models/user_memory.dart';
import '../database/app_database.dart';

class MemoryRepository {
  final AppDatabase db;

  MemoryRepository(this.db);

  UserMemory _mapRowToMemory(Memory row) {
    return UserMemory(
      id: row.id,
      fact: row.fact,
      category: row.category,
      isEnabled: row.isEnabled,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<List<UserMemory>> getMemories() async {
    final query = db.select(db.memories)
      ..orderBy([
        (m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(_mapRowToMemory).toList();
  }

  Stream<List<UserMemory>> watchMemories() {
    final query = db.select(db.memories)
      ..orderBy([
        (m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map((rows) => rows.map(_mapRowToMemory).toList());
  }

  Future<List<UserMemory>> getActiveMemories() async {
    final query = db.select(db.memories)
      ..where((m) => m.isEnabled.equals(true))
      ..orderBy([
        (m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(_mapRowToMemory).toList();
  }

  Future<UserMemory> addMemory({
    required String fact,
    String? category,
    bool isEnabled = true,
  }) async {
    final id = 'mem-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final entry = MemoriesCompanion.insert(
      id: id,
      fact: fact,
      category: Value(category),
      isEnabled: Value(isEnabled),
      createdAt: now,
      updatedAt: now,
    );

    await db.into(db.memories).insert(entry);

    return UserMemory(
      id: id,
      fact: fact,
      category: category,
      isEnabled: isEnabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateMemory(
    String id, {
    required String fact,
    String? category,
    bool? isEnabled,
  }) async {
    final now = DateTime.now();
    await (db.update(db.memories)..where((m) => m.id.equals(id))).write(
      MemoriesCompanion(
        fact: Value(fact),
        category: Value(category),
        isEnabled: isEnabled != null ? Value(isEnabled) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> toggleMemory(String id, bool isEnabled) async {
    final now = DateTime.now();
    await (db.update(db.memories)..where((m) => m.id.equals(id))).write(
      MemoriesCompanion(isEnabled: Value(isEnabled), updatedAt: Value(now)),
    );
  }

  Future<void> deleteMemory(String id) async {
    await (db.delete(db.memories)..where((m) => m.id.equals(id))).go();
  }
}
