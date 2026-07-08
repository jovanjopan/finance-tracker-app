import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/account_table.dart';
import 'tables/budget_table.dart';
import 'tables/category_table.dart';
import 'tables/transaction_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Accounts, Categories, Transactions, Budgets])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(transactions, transactions.note);
        }
        if (from < 3) {
          await customStatement('ALTER TABLE budgets RENAME TO budgets_old');
          await m.createTable(budgets);
          await customStatement(
            'INSERT INTO budgets (id, category_id, classification, target_amount, start_date, end_date) '
            'SELECT id, category_id, NULL, target_amount, start_date, end_date FROM budgets_old',
          );
          await customStatement('DROP TABLE budgets_old');
        }
        if (from < 4) {
          await m.addColumn(transactions, transactions.allocationType); 
        }
      },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dbFolder = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dbFolder.path, 'app_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
