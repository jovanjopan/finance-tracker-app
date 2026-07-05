import 'package:drift/drift.dart';

class Accounts extends Table {
  @override
  String get tableName => 'ACCOUNT';

  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get type => text()();

  RealColumn get initialBalance => real()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
