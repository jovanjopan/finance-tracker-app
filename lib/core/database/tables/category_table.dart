import 'package:drift/drift.dart';

class Categories extends Table {
  @override
  String get tableName => 'CATEGORY';

  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get transactionType => text()();

  TextColumn get expenseClassification => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
