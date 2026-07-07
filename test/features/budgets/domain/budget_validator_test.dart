import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_entity.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_validation_exception.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_validator.dart';

void main() {
  group('BudgetValidator', () {
    test('accepts budget with only categoryId', () {
      final budget = BudgetEntity(
        id: 'b1',
        categoryId: 'cat-1',
        targetAmount: 500000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      expect(() => BudgetValidator.validate(budget), returnsNormally);
    });

    test('accepts budget with only classification', () {
      final budget = BudgetEntity(
        id: 'b2',
        classification: 'needs',
        targetAmount: 500000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      expect(() => BudgetValidator.validate(budget), returnsNormally);
    });

    test('throws when both categoryId and classification are set', () {
      final budget = BudgetEntity(
        id: 'b3',
        categoryId: 'cat-1',
        classification: 'needs',
        targetAmount: 500000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      expect(
        () => BudgetValidator.validate(budget),
        throwsA(isA<BudgetValidationException>()),
      );
    });

    test('throws when neither categoryId nor classification are set', () {
      final budget = BudgetEntity(
        id: 'b4',
        targetAmount: 500000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      expect(
        () => BudgetValidator.validate(budget),
        throwsA(isA<BudgetValidationException>()),
      );
    });

    test('throws when classification value is invalid', () {
      final budget = BudgetEntity(
        id: 'b5',
        classification: 'unknown',
        targetAmount: 500000,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );
      expect(
        () => BudgetValidator.validate(budget),
        throwsA(isA<BudgetValidationException>()),
      );
    });
  });
}