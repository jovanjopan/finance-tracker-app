import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:myfinancetracker/core/providers/database_providers.dart';
import 'package:myfinancetracker/features/accounts/domain/account_entity.dart';
import 'package:myfinancetracker/features/accounts/domain/account_repository.dart';
import 'package:myfinancetracker/main.dart';

void main() {
  testWidgets('Splash navigates to onboarding when no accounts exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('koinku'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('buat akun pertama'), findsOneWidget);
  });

  testWidgets('Splash navigates directly to placeholder home when an account exists', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(
            const _FakeAccountRepository([
              AccountEntity(
                id: 'acc-1',
                name: 'Cash',
                type: 'cash',
                initialBalance: 0.0,
                isActive: true,
              ),
            ]),
          ),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Onboarding & Dashboard belum dibuat'), findsOneWidget);
    expect(find.text('buat akun pertama'), findsNothing);
  });
}

class _FakeAccountRepository implements AccountRepository {
  const _FakeAccountRepository([this._accounts = const <AccountEntity>[]]);

  final List<AccountEntity> _accounts;

  @override
  Future<void> createAccount(AccountEntity account) async {}

  @override
  Future<void> deleteAccount(String id) async {}

  @override
  Future<AccountEntity?> getAccountById(String id) async => null;

  @override
  Future<void> updateAccount(AccountEntity account) async {}

  @override
  Stream<List<AccountEntity>> watchAllAccounts() {
    return Stream<List<AccountEntity>>.value(_accounts);
  }

  @override
  Stream<double> watchCurrentBalance(String accountId) {
    return Stream<double>.value(0.0);
  }
}
