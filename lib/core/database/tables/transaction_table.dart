import 'package:drift/drift.dart';

import 'account_table.dart';
import 'category_table.dart';

class Transactions extends Table {
  @override
  String get tableName => 'TRANSACTION';

  TextColumn get id => text()();

  TextColumn get type => text()();

  RealColumn get amount => real()();

  DateTimeColumn get transactionDate => dateTime()();

  @ReferenceName('sourceAccountTransactions')
  TextColumn get accountId => text().references(Accounts, #id)();

  @ReferenceName('destinationAccountTransactions')
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();

  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  // ignore: override_on_non_overriding_member
  List<Set<Column<Object>>> get indexes => [
    {accountId},
    {toAccountId},
    {transactionDate},
  ];
}
