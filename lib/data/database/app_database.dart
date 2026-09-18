import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// Table: Chats
class Chats extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get modelId => text()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Table: Messages
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get chatId =>
      text().references(Chats, #id, onDelete: KeyAction.cascade)();
  TextColumn get sender => text()(); // 'user' or 'assistant'
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get status => text().withDefault(
    const Constant('complete'),
  )(); // 'complete', 'generating', 'error'
  TextColumn get modelId => text().nullable()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table: Attachments
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get messageId =>
      text().references(Messages, #id, onDelete: KeyAction.cascade)();
  TextColumn get chatId =>
      text().references(Chats, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get localPath => text()();
  IntColumn get size => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table: Memories
class Memories extends Table {
  TextColumn get id => text()();
  TextColumn get fact => text()();
  TextColumn get category => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table: Personas
class Personas extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get systemPrompt => text()();
  TextColumn get iconName =>
      text().withDefault(const Constant('auto_awesome'))();
  TextColumn get colorHex => text().withDefault(const Constant('#6366F1'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Table: Prompts
class Prompts extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Chats, Messages, Attachments, Memories, Personas, Prompts],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
      },
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(memories);
          await m.createTable(personas);
          await m.createTable(prompts);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'aura_ai.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
