import 'package:drift/drift.dart';

import 'category_table.dart';

class Budgets extends Table {
  @override
  String get tableName => 'BUDGET';

  TextColumn get id => text()();

  TextColumn get categoryId => text().references(Categories, #id)();

  RealColumn get targetAmount => real()();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get endDate => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
