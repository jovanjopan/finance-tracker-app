import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/core/database/app_database.dart';

void main() {
  group('AppDatabase smoke test', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('instantiate database without error', () {
      expect(database, isNotNull);
    });

    test('all tables are created and empty on first query', () async {
      final accountsRows = await database.select(database.accounts).get();
      final categoriesRows = await database.select(database.categories).get();
      final transactionsRows = await database.select(database.transactions).get();
      final budgetsRows = await database.select(database.budgets).get();

      expect(accountsRows, isEmpty);
      expect(categoriesRows, isEmpty);
      expect(transactionsRows, isEmpty);
      expect(budgetsRows, isEmpty);
    });

    test('insert and read one account row', () async {
      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: '8ed88ee5-cc2c-4ebf-9639-34f31178d913',
              name: 'Cash Wallet',
              type: 'cash',
              initialBalance: 100000,
            ),
          );

      final rows = await database.select(database.accounts).get();

      expect(rows, hasLength(1));
      expect(rows.first.id, '8ed88ee5-cc2c-4ebf-9639-34f31178d913');
      expect(rows.first.name, 'Cash Wallet');
      expect(rows.first.type, 'cash');
      expect(rows.first.initialBalance, 100000);
      expect(rows.first.isActive, isTrue);
    });
  });
}
